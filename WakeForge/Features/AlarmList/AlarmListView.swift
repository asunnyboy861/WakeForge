import SwiftUI
import SwiftData

struct AlarmListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\AlarmProfile.fireHour), SortDescriptor(\AlarmProfile.fireMinute)]) private var alarms: [AlarmProfile]
    @Query private var streaks: [StreakState]

    @StateObject private var purchase = SubscriptionManager.shared
    @State private var showEditor = false
    @State private var editingProfile: AlarmProfile?
    @State private var showPaywall = false
    @State private var permissionMessage: String?
    @AppStorage("wf.autoeditor.shown") private var autoEditorShown = false

    private var streak: StreakState? {
        streaks.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                WFTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        header
                        if alarms.isEmpty {
                            emptyState
                        } else {
                            alarmCards
                        }
                        if let permissionMessage {
                            Text(permissionMessage)
                                .font(WFTheme.font(12))
                                .foregroundStyle(WFTheme.danger)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        newAlarmButton
                        debugTools
                    }
                    .padding(.vertical, 12)
                    .frame(maxWidth: 640)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showEditor) {
                AlarmEditorView(profile: nil) { }
            }
            .sheet(item: $editingProfile) { profile in
                AlarmEditorView(profile: profile) { }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .task {
                await requestAuthorizationIfNeeded()
                await AlarmScheduler.shared.reconcile(alarms)
                maybeAutoOpenEditor()
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Mornings")
                    .font(WFTheme.font(32, weight: .black))
                    .foregroundStyle(.white)
                Text(nextAlarmText)
                    .font(WFTheme.font(14))
                    .foregroundStyle(WFTheme.muted)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                StreakFlame(count: streak?.current ?? 0)
                Text(purchase.isPro ? "Pro · unlimited wakes" : "\(QuotaStore.shared.remaining) free wakes left")
                    .font(WFTheme.font(11, weight: .medium))
                    .foregroundStyle(WFTheme.muted)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var nextAlarmText: String {
        guard let next = alarms.filter({ $0.isEnabled }).map({ $0.nextFireDate }).sorted().first else {
            return "No alarm set"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE h:mm a"
        return "Next: \(formatter.string(from: next))"
    }

    private var emptyState: some View {
        WFCard {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: "alarm.add")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(WFTheme.gold)
                Text("No alarms yet")
                    .font(WFTheme.font(20, weight: .bold))
                    .foregroundStyle(.white)
                Text("Set one alarm for tomorrow morning. Pick a task and earn your wake-up.")
                    .font(WFTheme.font(14))
                    .foregroundStyle(WFTheme.muted)
            }
        }
        .padding(.horizontal, 20)
    }

    private var alarmCards: some View {
        VStack(spacing: 12) {
            ForEach(alarms) { alarm in
                alarmCard(alarm)
            }
        }
        .padding(.horizontal, 20)
    }

    private func alarmCard(_ alarm: AlarmProfile) -> some View {
        HStack(spacing: 14) {
            Button {
                editingProfile = alarm
            } label: {
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(alarm.timeLabel)
                            .font(WFTheme.font(30, weight: .black))
                            .foregroundStyle(.white)
                        HStack(spacing: 4) {
                            Text(alarm.kind.title)
                                .font(WFTheme.font(12, weight: .semibold))
                                .foregroundStyle(WFTheme.muted)
                            if alarm.hasBackup {
                                Text("· +2 min backup")
                                    .font(WFTheme.font(11))
                                    .foregroundStyle(WFTheme.muted)
                            }
                        }
                        Text(daysLabel(for: alarm))
                            .font(WFTheme.font(11))
                            .foregroundStyle(WFTheme.muted)
                    }
                    Spacer()
                    TaskGlyph(kind: alarm.kind, size: 40)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Alarm at \(alarm.timeLabel), \(alarm.kind.title)")

            Toggle("", isOn: Binding(
                get: { alarm.isEnabled },
                set: { value in setEnabled(alarm, value) }
            ))
            .labelsHidden()
            .tint(WFTheme.forge)
            .accessibilityLabel("Enable alarm at \(alarm.timeLabel)")
        }
        .padding(16)
        .background(WFTheme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .contextMenu {
            Button(role: .destructive) {
                delete(alarm)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func daysLabel(for alarm: AlarmProfile) -> String {
        let days = alarm.repeatDays
        if days.isEmpty { return "One time" }
        if days.count == 7 { return "Every day" }
        if Set(days) == Set([.monday, .tuesday, .wednesday, .thursday, .friday]) { return "Weekdays" }
        return days.map { $0.shortLabel }.joined(separator: " ")
    }

    private var newAlarmButton: some View {
        Button {
            if alarms.count >= 3 && !purchase.isPro {
                showPaywall = true
            } else {
                showEditor = true
            }
        } label: {
            Label("New Alarm", systemImage: "plus")
        }
        .buttonStyle(WFPrimaryButtonStyle())
        .padding(.horizontal, 20)
        .padding(.top, 4)
    }

    @ViewBuilder
    private var debugTools: some View {
        #if DEBUG
        Button {
            let alarm = alarms.first
            NotificationCenter.default.post(
                name: .wfStartWake,
                object: nil,
                userInfo: [
                    "alarmID": (alarm?.id ?? UUID()).uuidString,
                    "profileID": (alarm?.id ?? UUID()).uuidString,
                    "kind": (alarm?.kind ?? .pushup).rawValue,
                    "target": alarm?.taskTarget ?? 10
                ]
            )
        } label: {
            Text("Debug: simulate a wake")
                .font(WFTheme.font(12))
                .foregroundStyle(WFTheme.muted)
        }
        .padding(.top, 6)
        #endif
    }

    private func setEnabled(_ alarm: AlarmProfile, _ value: Bool) {
        alarm.isEnabled = value
        try? context.save()
        if value {
            Task {
                let granted = await AlarmScheduler.shared.requestAuthorization()
                if granted {
                    await AlarmScheduler.shared.schedule(alarm)
                    permissionMessage = nil
                } else {
                    permissionMessage = "Alarm permission is off. Enable alarms for WakeForge in Settings."
                }
            }
        } else {
            AlarmScheduler.shared.cancel(alarm)
        }
    }

    private func delete(_ alarm: AlarmProfile) {
        AlarmScheduler.shared.cancel(alarm)
        context.delete(alarm)
        try? context.save()
    }

    private func requestAuthorizationIfNeeded() async {
        guard !alarms.isEmpty else { return }
        let granted = await AlarmScheduler.shared.requestAuthorization()
        if !granted && AlarmScheduler.shared.authorizationState == .denied {
            permissionMessage = "Alarm permission is off. Enable alarms for WakeForge in Settings."
        }
    }

    private func maybeAutoOpenEditor() {
        guard alarms.isEmpty, !autoEditorShown else { return }
        autoEditorShown = true
        showEditor = true
    }
}

extension Notification.Name {
    static let wfStartWake = Notification.Name("wf.start.wake")
}
