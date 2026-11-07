import Foundation

struct ChainStep: Identifiable {
    let id: Int
    let title: String
    let symbol: String
}

@MainActor
final class MorningChainStore: ObservableObject {
    static let shared = MorningChainStore()

    static let steps: [ChainStep] = [
        ChainStep(id: 0, title: "Drink a glass of water", symbol: "drop.fill"),
        ChainStep(id: 1, title: "Stretch for 30 seconds", symbol: "figure.flexibility"),
        ChainStep(id: 2, title: "Leave the phone for 10 minutes", symbol: "iphone.slash")
    ]

    static let window: TimeInterval = 21 * 60

    @Published private(set) var startedAt: Date?
    @Published private(set) var completed: Set<Int> = []

    private let startedKey = "wf.chain.startedAt"
    private let completedKey = "wf.chain.completed"

    private init() {
        if let date = UserDefaults.standard.object(forKey: startedKey) as? Date {
            startedAt = date
        }
        if let raw = UserDefaults.standard.string(forKey: completedKey) {
            completed = Set(raw.split(separator: ",").compactMap { Int($0) })
        }
    }

    var expiresAt: Date? {
        startedAt.map { $0.addingTimeInterval(Self.window) }
    }

    var isActive: Bool {
        guard let expiresAt else { return false }
        return Date() < expiresAt
    }

    var secondsRemaining: Int {
        guard let expiresAt else { return 0 }
        return max(0, Int(expiresAt.timeIntervalSinceNow))
    }

    var isComplete: Bool {
        completed.count == Self.steps.count
    }

    func start(at date: Date = Date()) {
        startedAt = date
        completed = []
        UserDefaults.standard.set(date, forKey: startedKey)
        UserDefaults.standard.set("", forKey: completedKey)
    }

    func toggle(_ stepID: Int) {
        guard isActive else { return }
        if completed.contains(stepID) {
            completed.remove(stepID)
        } else {
            completed.insert(stepID)
        }
        UserDefaults.standard.set(completed.map(String.init).joined(separator: ","), forKey: completedKey)
    }
}
