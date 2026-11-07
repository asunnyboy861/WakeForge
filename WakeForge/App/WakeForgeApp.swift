import SwiftUI
import SwiftData

@main
struct WakeForgeApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [AlarmProfile.self, WakeEvent.self, StreakState.self])
    }
}
