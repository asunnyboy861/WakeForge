import SwiftUI
import SwiftData

struct RootView: View {
    @AppStorage("wf.onboarding.done") private var onboarded = false
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase

    @State private var activeWake: ActiveWake?
    @State private var showPaywall = false
    @State private var paywallAfterWake = false
    @State private var selectedTab = 0
    @State private var showDemoCelebration = false

    var body: some View {
        Group {
            if onboarded {
                tabView
            } else {
                OnboardingView()
            }
        }
        .preferredColorScheme(.dark)
        .onOpenURL { url in
            handleDeepLink(url)
        }
        .onReceive(NotificationCenter.default.publisher(for: .wfStartWake)) { notification in
            guard let info = notification.userInfo,
                  let alarmRaw = info["alarmID"] as? String, let alarmID = UUID(uuidString: alarmRaw),
                  let profileRaw = info["profileID"] as? String, let profileID = UUID(uuidString: profileRaw),
                  let kindRaw = info["kind"] as? String, let kind = TaskKind(rawValue: kindRaw),
                  let target = info["target"] as? Int else { return }
            presentWake(alarmID: alarmID, profileID: profileID, kind: kind, target: target)
        }
        .onReceive(NotificationCenter.default.publisher(for: .wfDismissTask)) { _ in
            activeWake = nil
            if paywallAfterWake {
                paywallAfterWake = false
                showPaywall = true
            }
        }
        .fullScreenCover(item: $activeWake) { wake in
            TaskRunnerView(alarmID: wake.alarmID, profileID: wake.profileID, kind: wake.kind, target: wake.target)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .fullScreenCover(isPresented: $showDemoCelebration) {
            CelebrationView(kind: .pushup, target: 10) {
                showDemoCelebration = false
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                checkPendingAlarm()
            }
        }
        .onAppear {
            checkPendingAlarm()
            Task {
                try? await Task.sleep(for: .seconds(0.4))
                handleDebugLaunch()
            }
        }
    }

    private var tabView: some View {
        TabView(selection: $selectedTab) {
            AlarmListView()
                .tabItem { Label("Mornings", systemImage: "alarm.fill") }
                .tag(0)
            StatsView()
                .tabItem { Label("Report", systemImage: "chart.bar.fill") }
                .tag(1)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(2)
        }
        .tint(WFTheme.forge)
    }

    private func presentWake(alarmID: UUID, profileID: UUID, kind: TaskKind, target: Int) {
        guard activeWake == nil else { return }
        paywallAfterWake = !SubscriptionManager.shared.isPro && QuotaStore.shared.remaining == 0
        activeWake = ActiveWake(alarmID: alarmID, profileID: profileID, kind: kind, target: target)
    }

    private func checkPendingAlarm() {
        guard onboarded, activeWake == nil, let pending = AppGroupStore.pendingAlarm() else { return }
        let profileID = resolveProfileID(for: pending.id) ?? pending.id
        presentWake(alarmID: pending.id, profileID: profileID, kind: pending.kind, target: pending.target)
    }

    private func resolveProfileID(for alarmID: UUID) -> UUID? {
        let descriptor = FetchDescriptor<AlarmProfile>()
        guard let profiles = try? context.fetch(descriptor) else { return nil }
        if let match = profiles.first(where: { $0.id == alarmID || $0.backupID == alarmID }) {
            return match.id
        }
        return nil
    }

    private func handleDebugLaunch() {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-wfDemoTab"), index + 1 < arguments.count {
            switch arguments[index + 1] {
            case "report": selectedTab = 1
            case "settings": selectedTab = 2
            default: selectedTab = 0
            }
        }
        if arguments.contains("-wfDemoPaywall") {
            showPaywall = true
        }
        if arguments.contains("-wfDemoCelebrate") {
            seedDemoStreak()
            showDemoCelebration = true
        }
        guard activeWake == nil,
              let index = arguments.firstIndex(of: "-wfDemoWake"),
              index + 1 < arguments.count,
              let kind = TaskKind(rawValue: arguments[index + 1]) else { return }
        presentWake(alarmID: UUID(), profileID: UUID(), kind: kind, target: kind.defaultTarget)
        #endif
    }

    private func seedDemoStreak() {
        #if DEBUG
        let state = StreakStore.shared.state(in: context)
        if state.current == 0 {
            state.current = 1
            state.best = max(state.best, 1)
            state.totalReps = max(state.totalReps, 240)
            try? context.save()
        }
        #endif
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "wakeforge", url.host == "task" else { return }
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        guard let raw = components?.queryItems?.first(where: { $0.name == "alarm" })?.value,
              let alarmID = UUID(uuidString: raw) else { return }
        let profileID = resolveProfileID(for: alarmID) ?? alarmID
        let profile = (try? context.fetch(FetchDescriptor<AlarmProfile>()))?.first(where: { $0.id == profileID || $0.backupID == alarmID })
        let kind = profile?.kind ?? .pushup
        let target = profile?.taskTarget ?? kind.defaultTarget
        presentWake(alarmID: alarmID, profileID: profileID, kind: kind, target: target)
    }
}

struct ActiveWake: Identifiable {
    let id = UUID()
    let alarmID: UUID
    let profileID: UUID
    let kind: TaskKind
    let target: Int
}
