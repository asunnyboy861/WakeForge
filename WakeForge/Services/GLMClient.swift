import Foundation
import StoreKit

enum GLMError: LocalizedError {
    case proxyNotConfigured
    case rateLimited
    case badResponse
    case emptyContent
    case receiptRejected

    var errorDescription: String? {
        switch self {
        case .proxyNotConfigured: return "Cloud AI is unavailable right now."
        case .rateLimited: return "Too many cloud requests. Try again in a moment."
        case .badResponse: return "Cloud service error."
        case .emptyContent: return "The cloud returned no result."
        case .receiptRejected: return "Cloud verification needs an active Pro subscription."
        }
    }
}

@MainActor
final class GLMClient {
    static let shared = GLMClient()

    private let proxyURL = URL(string: "https://cramjam-api.calcs.top")!
    private let proxyFallbackURL = URL(string: "https://cramjam-proxy.iocompile67692.workers.dev")!
    private let model = "glm-5.3-flash"
    private let appId = "wakeforge"

    private var proxyDevKey: String? {
        guard let url = Bundle.main.url(forResource: "GLMProxySecret", withExtension: "txt"),
              let raw = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        let key = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return key.isEmpty ? nil : key
    }

    var hasProxyChannel: Bool {
        proxyDevKey != nil || SubscriptionManager.shared.isPro
    }

    var cloudAvailable: Bool {
        proxyDevKey != nil || BYOStore.shared.isConfigured || SubscriptionManager.shared.isPro
    }

    private var userId: String {
        if let id = KeychainHelper.read("proxy_user_id") { return id }
        let id = UUID().uuidString
        KeychainHelper.save(id, account: "proxy_user_id")
        return id
    }

    private func currentEntitlementJWS() async -> String? {
        for id in SubscriptionManager.productIDs {
            if let result = await Transaction.currentEntitlement(for: id),
               case .verified(let transaction) = result,
               transaction.revocationDate == nil {
                return result.jwsRepresentation
            }
        }
        return nil
    }

    func chat(messages: [[String: Any]], maxTokens: Int, jsonMode: Bool = true) async throws -> String {
        var payload: [String: Any] = [
            "model": model,
            "messages": messages,
            "thinking": ["level": "low"],
            "max_tokens": maxTokens
        ]
        if jsonMode {
            payload["response_format"] = ["type": "json_object"]
        }

        if let byo = BYOStore.shared.configuration, let key = BYOStore.shared.apiKey {
            return try await BYOClient.send(configuration: byo, apiKey: key, payload: payload)
        }

        var body: [String: Any] = [
            "appId": appId,
            "userId": userId,
            "payload": payload
        ]
        if let jws = await currentEntitlementJWS() {
            body["appTransaction"] = jws
        } else if let devKey = proxyDevKey {
            body["devKey"] = devKey
        } else {
            throw GLMError.proxyNotConfigured
        }
        return try await sendWithFallback(payload: body)
    }

    func chatWithImage(base64JPEG: String, systemPrompt: String, userText: String, maxTokens: Int = 8192) async throws -> String {
        let content: [[String: Any]] = [
            ["type": "text", "text": systemPrompt + (userText.isEmpty ? "" : "\n\(userText)")],
            ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64JPEG)"]]
        ]
        return try await chat(messages: [["role": "user", "content": content]], maxTokens: maxTokens, jsonMode: true)
    }

    private func sendWithFallback(payload: [String: Any]) async throws -> String {
        do {
            return try await send(url: proxyURL, payload: payload)
        } catch GLMError.badResponse, GLMError.emptyContent {
            return try await send(url: proxyFallbackURL, payload: payload)
        }
    }

    private func send(url: URL, payload: [String: Any]) async throws -> String {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw GLMError.badResponse }
        switch http.statusCode {
        case 200:
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let message = choices.first?["message"] as? [String: Any],
                  let content = message["content"] as? String, !content.isEmpty else {
                throw GLMError.emptyContent
            }
            return content
        case 401:
            throw GLMError.receiptRejected
        case 429:
            throw GLMError.rateLimited
        default:
            throw GLMError.badResponse
        }
    }
}
