import Foundation

struct FeedbackRequest: Codable {
    let name: String
    let email: String
    let subject: String
    let message: String
    let app_name: String
}

enum FeedbackService {
    static let baseURL = URL(string: "https://msg.calcs.top")!
    static let appName = "WakeForge"

    static func submit(name: String, email: String, subject: String, message: String) async throws {
        let endpoint = baseURL.appendingPathComponent("api/feedback")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload = FeedbackRequest(name: name, email: email, subject: subject, message: message, app_name: appName)
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw FeedbackError.network
        }
        guard (200..<300).contains(http.statusCode) else {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = json["error"] as? String {
                throw FeedbackError.server(message)
            }
            throw FeedbackError.server("Something went wrong. Please try again.")
        }
    }
}

enum FeedbackError: LocalizedError {
    case network
    case server(String)

    var errorDescription: String? {
        switch self {
        case .network: return "Network unavailable. Please check your connection."
        case .server(let message): return message
        }
    }
}
