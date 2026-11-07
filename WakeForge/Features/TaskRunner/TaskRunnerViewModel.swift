import Foundation
import SwiftData

@MainActor
final class TaskRunnerViewModel: ObservableObject {
    enum Route {
        case running
        case celebration
        case released
    }

    let alarmID: UUID
    let profileID: UUID
    let target: Int

    @Published var activeKind: TaskKind
    @Published var progress: Int = 0
    @Published var failureLevel: Int = 0
    @Published var message: String?
    @Published var route: Route = .running
    @Published var coolDownSeconds: Int = 0
    @Published var isSettling = false
    @Published var outcome: WFOutcome?
    @Published var showTaskPicker = false
    @Published var showPaywall = false

    private var eventID: UUID?
    private var coolDownTask: Task<Void, Never>?

    init(alarmID: UUID, profileID: UUID, kind: TaskKind, target: Int) {
        self.alarmID = alarmID
        self.profileID = profileID
        self.activeKind = kind
        self.target = max(1, target)
    }

    var displayKind: TaskKind { activeKind }

    func begin(in context: ModelContext) {
        let event = WakeEvent(alarmProfileID: profileID, firedAt: Date(), taskKindRaw: activeKind.rawValue)
        context.insert(event)
        try? context.save()
        eventID = event.id
        AppGroupStore.clearEscaped()
    }

    func updateProgress(_ value: Int) {
        progress = min(target, max(0, value))
    }

    func succeeded(reps: Int, in context: ModelContext) {
        guard route == .running, !isSettling else { return }
        settle(.earned, reps: reps, in: context)
    }

    func registerFailure(reason: String) {
        guard route == .running, isSettling == false else { return }
        failureLevel += 1
        switch failureLevel {
        case 1:
            message = reason.isEmpty ? "We couldn't verify that. Adjust and try once more." : reason
        case 2:
            message = "Still no luck. Switch to another task below, or try again."
            showTaskPicker = true
        default:
            message = "No task is forcing a loop. Your alarm will release after a short cool-down."
            beginCoolDown()
        }
    }

    func switchTask(to kind: TaskKind) {
        guard route == .running else { return }
        activeKind = kind
        progress = 0
        message = "Switched to \(kind.title). Complete it to earn your morning."
        showTaskPicker = false
    }

    func beginCoolDown() {
        guard coolDownTask == nil else { return }
        coolDownSeconds = 90
        coolDownTask = Task { [weak self] in
            while true {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled, let self else { return }
                if self.coolDownSeconds <= 0 { return }
                self.coolDownSeconds -= 1
            }
        }
    }

    func releaseNow(in context: ModelContext) {
        settle(.skipDay, reps: 0, in: context)
    }

    func settle(_ result: WFOutcome, reps: Int, in context: ModelContext) {
        guard !isSettling else { return }
        isSettling = true
        coolDownTask?.cancel()
        coolDownTask = nil

        AlarmScheduler.shared.stop(alarmID)
        AppGroupStore.clearPending()

        let event = fetchEvent(in: context) ?? {
            let created = WakeEvent(alarmProfileID: profileID, firedAt: Date(), taskKindRaw: activeKind.rawValue)
            context.insert(created)
            return created
        }()
        event.resolvedAt = Date()
        event.outcome = result
        event.repCount = reps
        event.photoDeleted = true
        event.taskKindRaw = activeKind.rawValue

        StreakStore.shared.record(result, reps: reps, in: context)
        if !SubscriptionManager.shared.isPro {
            QuotaStore.shared.consume()
        }
        if result == .earned {
            MorningChainStore.shared.start()
        }
        outcome = result
        route = result == .skipDay ? .released : .celebration
    }

    func manualConfirm(in context: ModelContext) {
        settle(.fallback, reps: progress, in: context)
    }

    private func fetchEvent(in context: ModelContext) -> WakeEvent? {
        guard let eventID else { return nil }
        let descriptor = FetchDescriptor<WakeEvent>(predicate: #Predicate { $0.id == eventID })
        return try? context.fetch(descriptor).first
    }
}
