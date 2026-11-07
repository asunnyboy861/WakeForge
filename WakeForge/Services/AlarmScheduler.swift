import AlarmKit
import AppIntents
import SwiftUI

@MainActor
final class AlarmScheduler {
    static let shared = AlarmScheduler()

    var authorizationState: AlarmManager.AuthorizationState {
        AlarmManager.shared.authorizationState
    }

    func requestAuthorization() async -> Bool {
        do {
            let state = try await AlarmManager.shared.requestAuthorization()
            return state == .authorized
        } catch {
            return false
        }
    }

    @discardableResult
    func schedule(_ profile: AlarmProfile) async -> Bool {
        try? AlarmManager.shared.cancel(id: profile.id)
        if profile.hasBackup {
            try? AlarmManager.shared.cancel(id: profile.backupID)
        }

        let kind = profile.kind
        AppGroupStore.register(profile.id, kind: kind, target: profile.taskTarget, title: kind.title)
        if profile.hasBackup {
            AppGroupStore.register(profile.backupID, kind: kind, target: profile.taskTarget, title: kind.title)
        }

        let schedule = makeSchedule(hour: profile.fireHour, minute: profile.fireMinute, days: profile.repeatDays, fireDate: profile.nextFireDate)
        let metadata = WFTaskMetadata(taskKindRaw: kind.rawValue, target: profile.taskTarget, alarmID: profile.id.uuidString, taskTitle: kind.title)
        let attributes = AlarmAttributes(presentation: presentation(for: kind), metadata: metadata, tintColor: WFTheme.forge)
        let configuration: AlarmManager.AlarmConfiguration<WFTaskMetadata> = .alarm(
            schedule: schedule,
            attributes: attributes,
            stopIntent: WFStopAlarmIntent(alarmID: profile.id.uuidString),
            secondaryIntent: WFOpenTaskIntent(alarmID: profile.id.uuidString, taskKind: kind.rawValue),
            sound: .default
        )

        do {
            _ = try await AlarmManager.shared.schedule(id: profile.id, configuration: configuration)
            if profile.hasBackup {
                let backupSchedule = makeSchedule(
                    hour: profile.fireHour,
                    minute: profile.fireMinute + 2,
                    days: profile.repeatDays,
                    fireDate: profile.backupFireDate
                )
                let backupMetadata = WFTaskMetadata(taskKindRaw: kind.rawValue, target: profile.taskTarget, alarmID: profile.backupID.uuidString, taskTitle: kind.title)
                let backupAttributes = AlarmAttributes(presentation: presentation(for: kind), metadata: backupMetadata, tintColor: WFTheme.forge)
                let backupConfiguration: AlarmManager.AlarmConfiguration<WFTaskMetadata> = .alarm(
                    schedule: backupSchedule,
                    attributes: backupAttributes,
                    stopIntent: WFStopAlarmIntent(alarmID: profile.backupID.uuidString),
                    secondaryIntent: WFOpenTaskIntent(alarmID: profile.backupID.uuidString, taskKind: kind.rawValue),
                    sound: .default
                )
                _ = try? await AlarmManager.shared.schedule(id: profile.backupID, configuration: backupConfiguration)
            }
            return true
        } catch {
            return false
        }
    }

    func cancel(_ profile: AlarmProfile) {
        try? AlarmManager.shared.cancel(id: profile.id)
        try? AlarmManager.shared.cancel(id: profile.backupID)
        AppGroupStore.unregister(profile.id)
        AppGroupStore.unregister(profile.backupID)
    }

    func stop(_ alarmID: UUID) {
        try? AlarmManager.shared.stop(id: alarmID)
        try? AlarmManager.shared.cancel(id: alarmID)
    }

    func reconcile(_ profiles: [AlarmProfile]) async {
        guard let alarms = try? AlarmManager.shared.alarms else { return }
        let systemIDs = Set(alarms.map { $0.id })
        for profile in profiles where profile.isEnabled {
            if !systemIDs.contains(profile.id) {
                await schedule(profile)
            }
        }
        for profile in profiles where !profile.isEnabled {
            if systemIDs.contains(profile.id) {
                cancel(profile)
            }
        }
    }

    private func makeSchedule(hour: Int, minute: Int, days: [WFWeekday], fireDate: Date) -> Alarm.Schedule {
        let total = (hour * 60 + minute) % (24 * 60)
        let normalizedHour = total / 60
        let normalizedMinute = total % 60
        if days.isEmpty {
            return .fixed(fireDate)
        }
        return .relative(
            Alarm.Schedule.Relative(
                time: Alarm.Schedule.Relative.Time(hour: normalizedHour, minute: normalizedMinute),
                repeats: .weekly(days.map { $0.localeWeekday })
            )
        )
    }

    private func presentation(for kind: TaskKind) -> AlarmPresentation {
        let alert = AlarmPresentation.Alert(
            title: "WakeForge · \(kind.shortTitle)",
            stopButton: AlarmButton(text: "Stop", textColor: .white, systemImageName: "xmark"),
            secondaryButton: AlarmButton(text: "Rise & Fight", textColor: .white, systemImageName: kind.symbolName),
            secondaryButtonBehavior: .custom
        )
        return AlarmPresentation(alert: alert)
    }
}

struct WFStopAlarmIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop Alarm"
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Alarm ID") var alarmID: String

    init() {}

    init(alarmID: String) {
        self.alarmID = alarmID
    }

    func perform() async throws -> some IntentResult {
        if let id = UUID(uuidString: alarmID) {
            try? AlarmManager.shared.stop(id: id)
            try? AlarmManager.shared.cancel(id: id)
            AppGroupStore.markEscaped()
        }
        return .result()
    }
}

struct WFOpenTaskIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Rise & Fight"
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Alarm ID") var alarmID: String
    @Parameter(title: "Task Kind") var taskKind: String

    init() {}

    init(alarmID: String, taskKind: String) {
        self.alarmID = alarmID
        self.taskKind = taskKind
    }

    func perform() async throws -> some IntentResult & OpensIntent {
        if let id = UUID(uuidString: alarmID) {
            AppGroupStore.markFiring(alarmID: id)
        }
        let urlString = "wakeforge://task?alarm=\(alarmID)"
        let url = URL(string: urlString) ?? URL(string: "wakeforge://task")!
        return .result(opensIntent: OpenURLIntent(url))
    }
}
