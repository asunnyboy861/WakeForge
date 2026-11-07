import Foundation

struct BYOConfiguration: Codable, Equatable {
    var providerName: String
    var baseURL: String
    var model: String
}

enum BYOProvider: String, CaseIterable, Identifiable {
    case openai
    case deepseek
    case glm
    case gemini
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openai: return "OpenAI"
        case .deepseek: return "DeepSeek"
        case .glm: return "GLM"
        case .gemini: return "Gemini"
        case .custom: return "Custom"
        }
    }

    var defaultBaseURL: String {
        switch self {
        case .openai: return "https://api.openai.com/v1"
        case .deepseek: return "https://api.deepseek.com/v1"
        case .glm: return "https://api.z.ai/api/paas/v4"
        case .gemini: return "https://generativelanguage.googleapis.com/v1beta/openai"
        case .custom: return ""
        }
    }

    var defaultModel: String {
        switch self {
        case .openai: return "gpt-4o-mini"
        case .deepseek: return "deepseek-chat"
        case .glm: return "glm-5.3-flash"
        case .gemini: return "gemini-2.0-flash"
        case .custom: return ""
        }
    }
}

@MainActor
final class BYOStore: ObservableObject {
    static let shared = BYOStore()

    @Published var configuration: BYOConfiguration?
    @Published var apiKey: String?

    private let configKey = "wf.byo.configuration"
    private let keyAccount = "byo.api_key"

    private init() {
        load()
    }

    var isConfigured: Bool {
        configuration != nil && (apiKey?.isEmpty == false)
    }

    var providerLabel: String {
        configuration?.providerName ?? "None"
    }

    func load() {
        if let data = UserDefaults.standard.data(forKey: configKey),
           let config = try? JSONDecoder().decode(BYOConfiguration.self, from: data) {
            configuration = config
        }
        apiKey = KeychainHelper.read(keyAccount)
    }

    func save(configuration: BYOConfiguration, apiKey: String) {
        if let data = try? JSONEncoder().encode(configuration) {
            UserDefaults.standard.set(data, forKey: configKey)
        }
        KeychainHelper.save(apiKey, account: keyAccount)
        self.configuration = configuration
        self.apiKey = apiKey
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: configKey)
        KeychainHelper.delete(keyAccount)
        configuration = nil
        apiKey = nil
    }
}
