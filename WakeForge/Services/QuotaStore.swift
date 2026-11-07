import Foundation

@MainActor
final class QuotaStore: ObservableObject {
    static let shared = QuotaStore()
    static let freeLimit = 3

    @Published private(set) var used: Int
    @Published private(set) var bonus: Int

    private let usedKey = "wf.quota.used"
    private let bonusKey = "wf.quota.bonus"
    private let weekKey = "wf.quota.week"

    private init() {
        used = UserDefaults.standard.integer(forKey: usedKey)
        bonus = UserDefaults.standard.integer(forKey: bonusKey)
        rollIfNeeded()
    }

    var remaining: Int {
        max(0, Self.freeLimit + bonus - used)
    }

    var hasFreeWake: Bool {
        remaining > 0
    }

    func consume() {
        rollIfNeeded()
        guard SubscriptionManager.shared.isPro == false else { return }
        used += 1
        UserDefaults.standard.set(used, forKey: usedKey)
    }

    func grantBonusWake() {
        guard bonus == 0 else { return }
        bonus = 1
        UserDefaults.standard.set(bonus, forKey: bonusKey)
    }

    private func rollIfNeeded() {
        let start = Self.currentWeekStart()
        if let stored = UserDefaults.standard.object(forKey: weekKey) as? Date,
           Calendar.current.isDate(stored, inSameDayAs: start) {
            return
        }
        used = 0
        bonus = 0
        UserDefaults.standard.set(0, forKey: usedKey)
        UserDefaults.standard.set(0, forKey: bonusKey)
        UserDefaults.standard.set(start, forKey: weekKey)
    }

    static func currentWeekStart() -> Date {
        var calendar = Calendar.current
        calendar.firstWeekday = 1
        let now = Date()
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        return calendar.date(from: components) ?? calendar.startOfDay(for: now)
    }
}
