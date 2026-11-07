import Foundation
import SwiftData

enum WFDifficulty: String, CaseIterable, Identifiable {
    case easy
    case standard
    case hell

    var id: String { rawValue }

    var label: String {
        switch self {
        case .easy: return "Easy"
        case .standard: return "Standard"
        case .hell: return "Hell"
        }
    }

    var multiplier: Double {
        switch self {
        case .easy: return 0.6
        case .standard: return 1.0
        case .hell: return 1.6
        }
    }
}

enum WFOutcome: String {
    case earned
    case fallback
    case skipDay

    var label: String {
        switch self {
        case .earned: return "Earned"
        case .fallback: return "Fallback"
        case .skipDay: return "Skip Day"
        }
    }
}

@Model
final class AlarmProfile {
    @Attribute(.unique) var id: UUID
    var fireHour: Int
    var fireMinute: Int
    var repeatDaysRaw: String
    var taskKindRaw: String
    var taskTarget: Int
    var difficultyRaw: String
    var isEnabled: Bool
    var hasBackup: Bool
    var backupID: UUID
    var createdAt: Date

    init(
        id: UUID = UUID(),
        fireHour: Int = 7,
        fireMinute: Int = 0,
        repeatDaysRaw: String = "1,2,3,4,5",
        taskKindRaw: String = TaskKind.pushup.rawValue,
        taskTarget: Int = 10,
        difficultyRaw: String = WFDifficulty.standard.rawValue,
        isEnabled: Bool = true,
        hasBackup: Bool = false,
        backupID: UUID = UUID(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.fireHour = fireHour
        self.fireMinute = fireMinute
        self.repeatDaysRaw = repeatDaysRaw
        self.taskKindRaw = taskKindRaw
        self.taskTarget = taskTarget
        self.difficultyRaw = difficultyRaw
        self.isEnabled = isEnabled
        self.hasBackup = hasBackup
        self.backupID = backupID
        self.createdAt = createdAt
    }

    var kind: TaskKind {
        get { TaskKind(rawValue: taskKindRaw) ?? .pushup }
        set { taskKindRaw = newValue.rawValue }
    }

    var difficulty: WFDifficulty {
        get { WFDifficulty(rawValue: difficultyRaw) ?? .standard }
        set { difficultyRaw = newValue.rawValue }
    }

    var repeatDays: [WFWeekday] {
        get {
            repeatDaysRaw
                .split(separator: ",")
                .compactMap { Int($0) }
                .compactMap { WFWeekday(rawValue: $0) }
        }
        set {
            repeatDaysRaw = newValue.map { String($0.rawValue) }.joined(separator: ",")
        }
    }

    var timeLabel: String {
        String(format: "%02d:%02d", fireHour, fireMinute)
    }

    var nextFireDate: Date {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let dayCount = repeatDays.isEmpty ? 8 : 7
        for offset in 0..<dayCount {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            if !repeatDays.isEmpty {
                let weekdayNumber = calendar.component(.weekday, from: day) - 1
                guard let weekday = WFWeekday(rawValue: weekdayNumber), repeatDays.contains(weekday) else { continue }
            }
            guard let candidate = calendar.date(bySettingHour: fireHour, minute: fireMinute, second: 0, of: day), candidate > now else { continue }
            return candidate
        }
        return now
    }

    var backupFireDate: Date {
        Calendar.current.date(byAdding: .minute, value: 2, to: nextFireDate) ?? nextFireDate
    }
}

@Model
final class WakeEvent {
    @Attribute(.unique) var id: UUID
    var alarmProfileID: UUID
    var firedAt: Date
    var resolvedAt: Date?
    var outcomeRaw: String
    var taskKindRaw: String
    var repCount: Int
    var photoDeleted: Bool

    init(
        id: UUID = UUID(),
        alarmProfileID: UUID,
        firedAt: Date = Date(),
        resolvedAt: Date? = nil,
        outcomeRaw: String = "",
        taskKindRaw: String = TaskKind.pushup.rawValue,
        repCount: Int = 0,
        photoDeleted: Bool = false
    ) {
        self.id = id
        self.alarmProfileID = alarmProfileID
        self.firedAt = firedAt
        self.resolvedAt = resolvedAt
        self.outcomeRaw = outcomeRaw
        self.taskKindRaw = taskKindRaw
        self.repCount = repCount
        self.photoDeleted = photoDeleted
    }

    var outcome: WFOutcome? {
        get { WFOutcome(rawValue: outcomeRaw) }
        set { outcomeRaw = newValue?.rawValue ?? "" }
    }

    var kind: TaskKind {
        TaskKind(rawValue: taskKindRaw) ?? .pushup
    }
}

@Model
final class StreakState {
    var current: Int
    var best: Int
    var totalReps: Int
    var lastWakeDate: Date?
    var chainCompletedCount: Int

    init(current: Int = 0, best: Int = 0, totalReps: Int = 0, lastWakeDate: Date? = nil, chainCompletedCount: Int = 0) {
        self.current = current
        self.best = best
        self.totalReps = totalReps
        self.lastWakeDate = lastWakeDate
        self.chainCompletedCount = chainCompletedCount
    }
}
