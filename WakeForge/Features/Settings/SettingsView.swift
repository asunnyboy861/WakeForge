import SwiftUI
import SwiftData

struct SettingsView: View {
    @StateObject private var purchase = SubscriptionManager.shared
    @Environment(\.openURL) private var openURL
    @Environment(\.modelContext) private var context

    @AppStorage("wf.health.enabled") private var healthEnabled = true

    @State private var showPaywall = false
    @State private var showHealthKitInfo = false
    @State private var showEditor = false

    private let privacyURL = URL(string: "https://asunnyboy861.github.io/WakeForge/privacy.html")!
    private let termsURL = URL(string: "https://asunnyboy861.github.io/WakeForge/terms.html")!
    private let supportURL = URL(string: "https://asunnyboy861.github.io/WakeForge/support.html")!

    private var versionLabel: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                WFTheme.background.ignoresSafeArea()
                List {
                    proSection
                    taskSection
                    healthSection
                    aiSection
                    subscriptionSection
                    legalSection
                    aboutSection
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Settings")
            .preferredColorScheme(.dark)
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showHealthKitInfo) {
                HealthKitInfoView()
            }
            .sheet(isPresented: $showEditor) {
                AlarmEditorView(profile: nil) { }
            }
            .task {
                await purchase.refreshEntitlement()
            }
        }
    }

    private var proSection: some View {
        Section {
            HStack(spacing: 14) {
                Image(systemName: purchase.isPro ? "flame.fill" : "flame")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(purchase.isPro ? WFTheme.gold : WFTheme.muted)
                VStack(alignment: .leading, spacing: 3) {
                    Text(purchase.isPro ? "WakeForge Pro" : "WakeForge Free")
                        .font(WFTheme.font(17, weight: .bold))
                        .foregroundStyle(.white)
                    Text(purchase.isPro ? "Unlimited wakes are active." : "\(QuotaStore.shared.remaining) free wakes left this week.")
                        .font(WFTheme.font(12))
                        .foregroundStyle(WFTheme.muted)
                }
                Spacer()
                if !purchase.isPro {
                    Button("Upgrade") { showPaywall = true }
                        .font(WFTheme.font(12, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(WFTheme.forge, in: Capsule())
                }
            }
            .padding(.vertical, 4)
        }
        .listRowBackground(WFTheme.surface)
    }

    private var taskSection: some View {
        Section {
            Button {
                showEditor = true
            } label: {
                Label("Add a photo task", systemImage: "camera.viewfinder")
                    .foregroundStyle(.white)
            }
        } header: {
            SectionHeader(title: "Task Market")
        } footer: {
            Text("Photo tasks work for anyone who doesn't want a workout alarm: the sky, a watered plant, a made bed.")
                .font(WFTheme.font(11))
                .foregroundStyle(WFTheme.muted)
        }
        .listRowBackground(WFTheme.surface)
    }

    private var healthSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "heart.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.red)
                VStack(alignment: .leading, spacing: 2) {
                    Text("HealthKit Integration")
                        .font(WFTheme.font(15, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("Read today's step count from Apple Health via HealthKit")
                        .font(WFTheme.font(11))
                        .foregroundStyle(WFTheme.muted)
                }
                Spacer()
                Button("Learn More") { showHealthKitInfo = true }
                    .font(WFTheme.font(11, weight: .semibold))
                    .foregroundStyle(WFTheme.gold)
            }
            .padding(.vertical, 4)

            Toggle(isOn: $healthEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Verify step tasks with HealthKit")
                        .font(WFTheme.font(14, weight: .medium))
                        .foregroundStyle(.white)
                    Text("WakeForge reads steps only. It never writes health data.")
                        .font(WFTheme.font(11))
                        .foregroundStyle(WFTheme.muted)
                }
            }
            .tint(WFTheme.forge)
        } header: {
            HStack {
                Text("Apple Health (HealthKit)")
                Spacer()
                Image(systemName: "heart.text.square.fill")
                    .foregroundStyle(.red)
            }
        } footer: {
            Text("WakeForge uses the HealthKit framework to read today's step count so a step task can be verified. This requires your explicit permission. No health data is written to Apple Health.")
                .font(WFTheme.font(10))
                .foregroundStyle(WFTheme.muted)
        }
        .listRowBackground(WFTheme.surface)
    }

    private var aiSection: some View {
        Section {
            HStack {
                Label("Apple Intelligence", systemImage: "sparkles")
                    .foregroundStyle(.white)
                Spacer()
                Text(AppleAIService.isAvailable ? "Ready" : "Unavailable")
                    .font(WFTheme.font(11, weight: .semibold))
                    .foregroundStyle(AppleAIService.isAvailable ? WFTheme.success : WFTheme.muted)
            }
            HStack {
                Label("Cloud photo checks", systemImage: "cloud.fill")
                    .foregroundStyle(.white)
                Spacer()
                Text(GLMMeta.statusLabel)
                    .font(WFTheme.font(11, weight: .semibold))
                    .foregroundStyle(WFTheme.muted)
            }
            NavigationLink {
                AISettingsView()
            } label: {
                Label("Custom API Key", systemImage: "key.fill")
                    .foregroundStyle(.white)
            }
        } header: {
            SectionHeader(title: "AI & BYO")
        } footer: {
            Text("Use your own key for unlimited AI. On a supported device, Apple Intelligence runs on device at no cost.")
                .font(WFTheme.font(10))
                .foregroundStyle(WFTheme.muted)
        }
        .listRowBackground(WFTheme.surface)
    }

    private var subscriptionSection: some View {
        Section {
            Button {
                openURL(URL(string: "https://apps.apple.com/account/subscriptions")!)
            } label: {
                HStack {
                    Label("Manage Subscription", systemImage: "creditcard.fill")
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11))
                        .foregroundStyle(WFTheme.muted)
                }
            }
            Button {
                Task {
                    await purchase.restore()
                }
            } label: {
                Label("Restore Purchases", systemImage: "arrow.clockwise")
                    .foregroundStyle(.white)
            }
        } header: {
            SectionHeader(title: "Subscription")
        } footer: {
            Text("Plans renew automatically unless canceled at least 24 hours before the period ends.")
                .font(WFTheme.font(10))
                .foregroundStyle(WFTheme.muted)
        }
        .listRowBackground(WFTheme.surface)
    }

    private var legalSection: some View {
        Section {
            NavigationLink {
                ContactSupportView()
            } label: {
                Label("Contact Support", systemImage: "envelope.fill")
                    .foregroundStyle(.white)
            }
            Link(destination: privacyURL) {
                Label("Privacy Policy", systemImage: "hand.raised.fill")
                    .foregroundStyle(.white)
            }
            Link(destination: termsURL) {
                Label("Terms of Use", systemImage: "doc.text.fill")
                    .foregroundStyle(.white)
            }
            Link(destination: supportURL) {
                Label("Support Page", systemImage: "questionmark.circle.fill")
                    .foregroundStyle(.white)
            }
        } header: {
            SectionHeader(title: "Legal")
        } footer: {
            Text("Camera frames are analyzed on device and never uploaded. Photos are discarded 10 seconds after verification.")
                .font(WFTheme.font(10))
                .foregroundStyle(WFTheme.muted)
        }
        .listRowBackground(WFTheme.surface)
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                    .foregroundStyle(WFTheme.muted)
                Spacer()
                Text(versionLabel)
                    .foregroundStyle(.white)
            }
            Text("Copyright © 2026 he zhou")
                .font(WFTheme.font(11))
                .foregroundStyle(WFTheme.muted)
        } header: {
            SectionHeader(title: "About")
        }
        .listRowBackground(WFTheme.surface)
    }
}

@MainActor
enum GLMMeta {
    static var statusLabel: String {
        GLMClient.shared.cloudAvailable ? "Available" : "Not configured"
    }
}
