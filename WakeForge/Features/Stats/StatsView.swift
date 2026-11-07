import SwiftUI
import SwiftData

struct StatsView: View {
    @Query(sort: \WakeEvent.firedAt, order: .reverse) private var events: [WakeEvent]
    @Query private var streaks: [StreakState]

    @State private var narrative: String?

    private var streak: StreakState? {
        streaks.first
    }

    private var weekStart: Date {
        QuotaStore.currentWeekStart()
    }

    private var weekEvents: [WakeEvent] {
        events.filter { $0.firedAt >= weekStart }
    }

    private var earnedCount: Int {
        weekEvents.filter { $0.outcome == .earned }.count
    }

    private var skipCount: Int {
        weekEvents.filter { $0.outcome == .skipDay }.count
    }

    private var weekReps: Int {
        weekEvents.reduce(0) { $0 + $1.repCount }
    }

    private var lifetimeReps: Int {
        streak?.totalReps ?? events.reduce(0) { $0 + $1.repCount }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                WFTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        header
                        weeklyCard
                        chartCard
                        milestones
                        if let narrative {
                            WFCard {
                                Text(narrative)
                                    .font(WFTheme.font(14))
                                    .foregroundStyle(.white)
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 12)
                    .frame(maxWidth: 640)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationBarHidden(true)
            .task {
                narrative = await AIProviderRouter.shared.weeklyNarrative(
                    reps: lifetimeReps,
                    earned: earnedCount,
                    skipped: skipCount
                )
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Report")
                .font(WFTheme.font(32, weight: .black))
                .foregroundStyle(.white)
            Text("This week started Sunday")
                .font(WFTheme.font(13))
                .foregroundStyle(WFTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
    }

    private var weeklyCard: some View {
        WFCard {
            HStack(spacing: 18) {
                statBlock(value: "\(earnedCount)", label: "Earned")
                Divider().overlay(WFTheme.surfaceRaised)
                statBlock(value: "\(skipCount)", label: "Skip days")
                Divider().overlay(WFTheme.surfaceRaised)
                statBlock(value: "\(weekReps)", label: "Reps")
            }
        }
        .padding(.horizontal, 20)
    }

    private func statBlock(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(WFTheme.font(26, weight: .black))
                .foregroundStyle(.white)
            Text(label)
                .font(WFTheme.font(11, weight: .medium))
                .foregroundStyle(WFTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var chartCard: some View {
        WFCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SectionHeader(title: "Last 7 days")
                    Spacer()
                    Text("\(lifetimeReps) lifetime reps")
                        .font(WFTheme.font(11, weight: .semibold))
                        .foregroundStyle(WFTheme.gold)
                }
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(days, id: \.self) { day in
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(result(for: day) ? WFTheme.forge : WFTheme.surfaceRaised)
                                .frame(height: result(for: day) ? 56 : 12)
                            Text(weekdayLabel(day))
                                .font(WFTheme.font(10, weight: .medium))
                                .foregroundStyle(WFTheme.muted)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 80, alignment: .bottom)

                Text(heightComparison)
                    .font(WFTheme.font(13))
                    .foregroundStyle(WFTheme.muted)
            }
        }
        .padding(.horizontal, 20)
    }

    private var days: [Date] {
        let calendar = Calendar.current
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset - 6, to: Date())
        }
    }

    private func result(for day: Date) -> Bool {
        let calendar = Calendar.current
        return events.contains { calendar.isDate($0.firedAt, inSameDayAs: day) && $0.outcome == .earned }
    }

    private func weekdayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }

    private var heightComparison: String {
        let floors = Double(lifetimeReps) / 20.0
        if floors < 0.1 { return "Your first reps will start stacking up here." }
        return String(format: "Your lifetime push-ups stack up to about %.1f floors.", floors)
    }

    private var milestones: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Milestones")
            HStack(spacing: 10) {
                milestone(days: 7, achieved: (streak?.best ?? 0) >= 7)
                milestone(days: 30, achieved: (streak?.best ?? 0) >= 30)
                milestone(days: 100, achieved: (streak?.best ?? 0) >= 100)
            }
        }
        .padding(.horizontal, 20)
    }

    private func milestone(days: Int, achieved: Bool) -> some View {
        VStack(spacing: 6) {
            Image(systemName: achieved ? "seal.fill" : "seal")
                .font(.system(size: 22))
                .foregroundStyle(achieved ? WFTheme.gold : WFTheme.muted)
            Text("\(days) days")
                .font(WFTheme.font(12, weight: .semibold))
                .foregroundStyle(achieved ? .white : WFTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(WFTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityLabel("\(days) day milestone, \(achieved ? "unlocked" : "locked")")
    }
}
