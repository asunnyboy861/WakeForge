import Foundation

struct PendingAlarm {
    let id: UUID
    let kind: TaskKind
    let target: Int
    let title: String
    let firedAt: Date
}

enum AppGroupStore {
    static let suiteName = "group.com.zzoutuo.WakeForge"

    private static var store: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    private static let activeKey = "wf.pending.active"
    private static let escapeKey = "wf.pending.escaped"

    static func register(_ profileID: UUID, kind: TaskKind, target: Int, title: String) {
        let defaults = store
        defaults.set(profileID.uuidString, forKey: "wf.task.\(profileID.uuidString).kind")
        defaults.set(target, forKey: "wf.task.\(profileID.uuidString).target")
        defaults.set(title, forKey: "wf.task.\(profileID.uuidString).title")
    }

    static func unregister(_ profileID: UUID) {
        let defaults = store
        defaults.removeObject(forKey: "wf.task.\(profileID.uuidString).kind")
        defaults.removeObject(forKey: "wf.task.\(profileID.uuidString).target")
        defaults.removeObject(forKey: "wf.task.\(profileID.uuidString).title")
        defaults.removeObject(forKey: "wf.pending.\(profileID.uuidString).firedAt")
        if defaults.string(forKey: activeKey) == profileID.uuidString {
            defaults.removeObject(forKey: activeKey)
        }
    }

    static func markFiring(alarmID: UUID) {
        let defaults = store
        let raw = alarmID.uuidString
        let kind = TaskKind(rawValue: defaults.string(forKey: "wf.task.\(raw).kind") ?? "") ?? .pushup
        let target = defaults.integer(forKey: "wf.task.\(raw).target")
        let title = defaults.string(forKey: "wf.task.\(raw).title") ?? kind.title
        markFiring(alarmID: alarmID, kind: kind, target: target == 0 ? kind.defaultTarget : target, title: title)
    }

    static func markFiring(alarmID: UUID, kind: TaskKind, target: Int, title: String) {
        let defaults = store
        defaults.set(alarmID.uuidString, forKey: activeKey)
        defaults.set(kind.rawValue, forKey: "wf.pending.\(alarmID.uuidString).kind")
        defaults.set(target, forKey: "wf.pending.\(alarmID.uuidString).target")
        defaults.set(title, forKey: "wf.pending.\(alarmID.uuidString).title")
        defaults.set(Date(), forKey: "wf.pending.\(alarmID.uuidString).firedAt")
        defaults.set(false, forKey: escapeKey)
    }

    static func pendingAlarm() -> PendingAlarm? {
        let defaults = store
        guard let raw = defaults.string(forKey: activeKey), let id = UUID(uuidString: raw) else { return nil }
        let kind = TaskKind(rawValue: defaults.string(forKey: "wf.pending.\(raw).kind") ?? "") ?? .pushup
        let target = defaults.integer(forKey: "wf.pending.\(raw).target")
        let title = defaults.string(forKey: "wf.pending.\(raw).title") ?? kind.title
        let firedAt = defaults.object(forKey: "wf.pending.\(raw).firedAt") as? Date ?? Date()
        return PendingAlarm(id: id, kind: kind, target: target == 0 ? kind.defaultTarget : target, title: title, firedAt: firedAt)
    }

    static func clearPending() {
        let defaults = store
        if let raw = defaults.string(forKey: activeKey) {
            defaults.removeObject(forKey: "wf.pending.\(raw).kind")
            defaults.removeObject(forKey: "wf.pending.\(raw).target")
            defaults.removeObject(forKey: "wf.pending.\(raw).title")
            defaults.removeObject(forKey: "wf.pending.\(raw).firedAt")
        }
        defaults.removeObject(forKey: activeKey)
    }

    static func markEscaped() {
        store.set(true, forKey: escapeKey)
    }

    static func clearEscaped() {
        store.set(false, forKey: escapeKey)
    }

    static func hasEscaped() -> Bool {
        store.bool(forKey: escapeKey)
    }
}
