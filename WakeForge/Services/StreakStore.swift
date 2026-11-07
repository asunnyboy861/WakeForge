import Foundation
import SwiftData

@MainActor
final class StreakStore {
    static let shared = StreakStore()

    func state(in context: ModelContext) -> StreakState {
        let descriptor = FetchDescriptor<StreakState>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let created = StreakState()
        context.insert(created)
        return created
    }

    func record(_ outcome: WFOutcome, reps: Int, in context: ModelContext) {
        let state = state(in: context)
        switch outcome {
        case .earned:
            state.current += 1
            state.best = max(state.best, state.current)
            state.lastWakeDate = Date()
        case .fallback:
            state.current = max(0, state.current / 2)
            state.lastWakeDate = Date()
        case .skipDay:
            state.current = 0
        }
        state.totalReps += reps
        try? context.save()
    }

    func awardChainCompletion(in context: ModelContext) {
        let state = state(in: context)
        state.chainCompletedCount += 1
        try? context.save()
    }
}
