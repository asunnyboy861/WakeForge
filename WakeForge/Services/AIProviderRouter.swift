import Foundation

struct PhotoVerdict: Sendable {
    let passed: Bool
    let confidence: Double
    let reason: String
    let source: String
    let manualFallback: Bool
}

struct MorningChallenge: Sendable {
    let question: String
    let keywords: [String]
}

@MainActor
final class AIProviderRouter {
    static let shared = AIProviderRouter()

    private let bank: [MorningChallenge] = [
        MorningChallenge(question: "Name three things you can see out of your window right now.", keywords: ["window", "tree", "sky", "car", "building", "street"]),
        MorningChallenge(question: "What is one thing you are grateful for this morning?", keywords: ["grateful", "thankful", "family", "friend", "health", "sleep"]),
        MorningChallenge(question: "Say the color of the sky in one word.", keywords: ["blue", "gray", "grey", "white", "orange", "pink", "black"]),
        MorningChallenge(question: "What will you finish today before noon?", keywords: ["finish", "today", "morning", "task", "work", "study"]),
        MorningChallenge(question: "How many hours did you sleep? Type a number from 1 to 12.", keywords: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"]),
        MorningChallenge(question: "Name a person you will speak to today.", keywords: ["mom", "dad", "friend", "team", "family", "colleague"]),
        MorningChallenge(question: "What is the first thing you will drink today?", keywords: ["water", "coffee", "tea", "juice", "milk"]),
        MorningChallenge(question: "Describe the sound in your room in one word.", keywords: ["quiet", "silent", "birds", "clock", "traffic", "music"]),
        MorningChallenge(question: "What is one word for how you feel right now?", keywords: ["tired", "awake", "ready", "calm", "focused", "strong"]),
        MorningChallenge(question: "Name a place you will go today.", keywords: ["gym", "office", "work", "school", "home", "store"]),
        MorningChallenge(question: "Pick a number between one and ten and type it.", keywords: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]),
        MorningChallenge(question: "What is one small win you want before lunch?", keywords: ["win", "lunch", "task", "email", "walk", "clean"])
    ]

    func verifyPhoto(jpeg: Data, prompt: String) async -> PhotoVerdict {
        let base64 = jpeg.base64EncodedString()
        let systemPrompt = """
        You verify a morning-task photo. Task: \(prompt). Judge tolerantly: different angles and lighting are acceptable.
        Respond ONLY with JSON: {"verdict":"pass","confidence":0.0,"reason":"short reason"}
        """
        guard GLMClient.shared.cloudAvailable else {
            return PhotoVerdict(passed: false, confidence: 0, reason: "Cloud check is not available. Tap below to confirm you took the photo.", source: "manual", manualFallback: true)
        }
        do {
            let content = try await GLMClient.shared.chatWithImage(base64JPEG: base64, systemPrompt: systemPrompt, userText: "Return the JSON verdict now.")
            return parseVerdict(content)
        } catch {
            return PhotoVerdict(passed: false, confidence: 0, reason: "We could not verify this automatically. Tap below to confirm you took the photo.", source: "manual", manualFallback: true)
        }
    }

    func makeChallenge(streak: Int, recent: [String]) async -> MorningChallenge {
        if AppleAIService.isAvailable {
            let instructions = """
            You create a 30-second morning challenge that a person can answer in a few words.
            Respond only with JSON: {"question":"...","keywords":["...","..."]}
            """
            let prompt = "streak=\(streak), recent=\(recent.suffix(4).joined(separator: " | "))"
            if let raw = await AppleAIService.respond(prompt: prompt, instructions: instructions),
               let challenge = parseChallenge(raw) {
                return challenge
            }
        }
        return bank[abs(streak + Calendar.current.component(.day, from: Date())) % bank.count]
    }

    func judgeAnswer(_ answer: String, challenge: MorningChallenge, streak: Int) async -> Bool {
        let trimmed = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 1 else { return false }
        let lowered = trimmed.lowercased()
        if challenge.keywords.contains(where: { lowered.contains($0.lowercased()) }) {
            return true
        }
        if AppleAIService.isAvailable {
            let instructions = """
            Judge whether the answer plausibly responds to the morning question.
            Respond only with JSON: {"pass":true}
            """
            let prompt = "question=\(challenge.question) answer=\(trimmed)"
            if let raw = await AppleAIService.respond(prompt: prompt, instructions: instructions),
               let json = jsonObject(from: raw),
               let pass = json["pass"] as? Bool {
                return pass
            }
        }
        return trimmed.split(separator: " ").count >= 3
    }

    func weeklyNarrative(reps: Int, earned: Int, skipped: Int) async -> String? {
        guard AppleAIService.isAvailable else { return nil }
        let instructions = "You write one short, upbeat sentence about the user's morning week. No emoji."
        let prompt = "earned=\(earned), skipped=\(skipped), pushups=\(reps)"
        return await AppleAIService.respond(prompt: prompt, instructions: instructions)
    }

    private func parseVerdict(_ raw: String) -> PhotoVerdict {
        guard let json = jsonObject(from: raw) else {
            return PhotoVerdict(passed: false, confidence: 0, reason: "Verification response was unreadable.", source: "cloud", manualFallback: true)
        }
        let verdict = (json["verdict"] as? String ?? "").lowercased()
        let confidence = json["confidence"] as? Double ?? 0
        let reason = json["reason"] as? String ?? ""
        let passed = verdict == "pass" && confidence >= 0.7
        if verdict == "pass" && confidence < 0.7 {
            return PhotoVerdict(passed: false, confidence: confidence, reason: reason.isEmpty ? "Confidence was low. Retake the photo." : reason, source: "cloud", manualFallback: false)
        }
        return PhotoVerdict(passed: passed, confidence: confidence, reason: reason.isEmpty ? "Photo verified." : reason, source: "cloud", manualFallback: false)
    }

    private func parseChallenge(_ raw: String) -> MorningChallenge? {
        guard let json = jsonObject(from: raw),
              let question = json["question"] as? String,
              let keywords = json["keywords"] as? [String], !question.isEmpty, !keywords.isEmpty else { return nil }
        return MorningChallenge(question: question, keywords: keywords)
    }

    private func jsonObject(from raw: String) -> [String: Any]? {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("```") {
            text = text.replacingOccurrences(of: "```json", with: "")
            text = text.replacingOccurrences(of: "```", with: "")
            text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard let data = text.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return object
    }
}
