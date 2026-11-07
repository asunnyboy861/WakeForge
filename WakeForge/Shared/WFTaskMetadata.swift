import Foundation
import AlarmKit

enum TaskKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case pushup
    case squat
    case photo
    case steps
    case mental

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pushup: return "Push-ups"
        case .squat: return "Squats"
        case .photo: return "Photo Proof"
        case .steps: return "Steps"
        case .mental: return "Mental Challenge"
        }
    }

    var shortTitle: String {
        switch self {
        case .pushup: return "Push-ups"
        case .squat: return "Squats"
        case .photo: return "Photo"
        case .steps: return "Steps"
        case .mental: return "Mental"
        }
    }

    var symbolName: String {
        switch self {
        case .pushup: return "figure.strengthtraining.traditional"
        case .squat: return "figure.cross.training"
        case .photo: return "camera.fill"
        case .steps: return "figure.walk"
        case .mental: return "brain.head.profile"
        }
    }

    var photoPrompt: String? {
        self == .photo ? "a clear view of the sky through a window or from outside" : nil
    }

    var defaultTarget: Int {
        switch self {
        case .pushup: return 10
        case .squat: return 15
        case .photo: return 1
        case .steps: return 500
        case .mental: return 1
        }
    }
}

enum WFWeekday: Int, CaseIterable, Identifiable, Sendable {
    case sunday = 0
    case monday = 1
    case tuesday = 2
    case wednesday = 3
    case thursday = 4
    case friday = 5
    case saturday = 6

    var id: Int { rawValue }

    var shortLabel: String {
        switch self {
        case .sunday: return "S"
        case .monday: return "M"
        case .tuesday: return "T"
        case .wednesday: return "W"
        case .thursday: return "T"
        case .friday: return "F"
        case .saturday: return "S"
        }
    }

    var localeWeekday: Locale.Weekday {
        switch self {
        case .sunday: return .sunday
        case .monday: return .monday
        case .tuesday: return .tuesday
        case .wednesday: return .wednesday
        case .thursday: return .thursday
        case .friday: return .friday
        case .saturday: return .saturday
        }
    }
}

struct WFTaskMetadata: AlarmMetadata {
    var taskKindRaw: String
    var target: Int
    var alarmID: String
    var taskTitle: String

    init(taskKindRaw: String = TaskKind.pushup.rawValue, target: Int = 10, alarmID: String = "", taskTitle: String = "Push-ups") {
        self.taskKindRaw = taskKindRaw
        self.target = target
        self.alarmID = alarmID
        self.taskTitle = taskTitle
    }

    var kind: TaskKind {
        TaskKind(rawValue: taskKindRaw) ?? .pushup
    }
}
