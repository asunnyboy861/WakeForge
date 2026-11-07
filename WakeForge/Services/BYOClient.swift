import Foundation

enum BYOClient {
    static func send(configuration: BYOConfiguration, apiKey: String, payload: [String: Any]) async throws -> String {
        let base = configuration.baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/ "))
        let endpointString = base.contains("chat/completions") ? base : base + "/chat/completions"
        guard let url = URL(string: endpointString) else { throw GLMError.badResponse }

        var body = payload
        body["model"] = configuration.model

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

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
        case 401, 403:
            throw GLMError.receiptRejected
        case 429:
            throw GLMError.rateLimited
        default:
            throw GLMError.badResponse
        }
    }
}
