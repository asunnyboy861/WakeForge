import Foundation
import HealthKit

final class StepsService {
    static let shared = StepsService()

    private let store = HKHealthStore()

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    private var stepType: HKQuantityType? {
        HKQuantityType.quantityType(forIdentifier: .stepCount)
    }

    func requestAuthorization() async -> Bool {
        guard isAvailable, let stepType else { return false }
        do {
            try await store.requestAuthorization(toShare: [], read: [stepType])
            return true
        } catch {
            return false
        }
    }

    func todaySteps() async -> Double? {
        guard let stepType else { return nil }
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, _ in
                let value = statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }
}
