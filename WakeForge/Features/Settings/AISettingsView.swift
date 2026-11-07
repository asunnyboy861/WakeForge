import SwiftUI

struct AISettingsView: View {
    @StateObject private var byo = BYOStore.shared

    @State private var provider: BYOProvider = .openai
    @State private var baseURL = BYOProvider.openai.defaultBaseURL
    @State private var model = BYOProvider.openai.defaultModel
    @State private var apiKey = ""
    @State private var message: String?

    var body: some View {
        ZStack {
            WFTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    intelligenceCard
                    cloudCard
                    formCard
                    privacyNote
                }
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("AI & BYO")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .onAppear(perform: loadExisting)
    }

    private var intelligenceCard: some View {
        WFCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(WFTheme.gold)
                    Text("Apple Intelligence")
                        .font(WFTheme.font(16, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(AppleAIService.isAvailable ? "Ready" : "Unavailable")
                        .font(WFTheme.font(11, weight: .semibold))
                        .foregroundStyle(AppleAIService.isAvailable ? WFTheme.success : WFTheme.muted)
                }
                Text(AppleAIService.isAvailable ? "Challenges and report copy run on this device at no cost." : "This device does not offer Apple Intelligence. Add your own API key below for cloud checks, or use the built-in challenge bank.")
                    .font(WFTheme.font(12))
                    .foregroundStyle(WFTheme.muted)
            }
        }
        .padding(.horizontal, 20)
    }

    private var cloudCard: some View {
        WFCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "cloud.fill")
                        .foregroundStyle(WFTheme.gold)
                    Text("Cloud photo checks")
                        .font(WFTheme.font(16, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(byo.isConfigured ? "Your key" : GLMMeta.statusLabel)
                        .font(WFTheme.font(11, weight: .semibold))
                        .foregroundStyle(WFTheme.muted)
                }
                Text("Pro includes daily cloud verification. With your own key, cloud checks are unlimited.")
                    .font(WFTheme.font(12))
                    .foregroundStyle(WFTheme.muted)
            }
        }
        .padding(.horizontal, 20)
    }

    private var formCard: some View {
        WFCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Bring your own key")

                Picker("Provider", selection: $provider) {
                    ForEach(BYOProvider.allCases) { item in
                        Text(item.displayName).tag(item)
                    }
                }
                .pickerStyle(.menu)
                .tint(WFTheme.gold)
                .onChange(of: provider) { _, newValue in
                    if !newValue.defaultBaseURL.isEmpty {
                        baseURL = newValue.defaultBaseURL
                        model = newValue.defaultModel
                    }
                }

                field("Base URL", text: $baseURL, placeholder: "https://api.openai.com/v1")
                field("Model", text: $model, placeholder: "gpt-4o-mini")
                field("API Key", text: $apiKey, placeholder: "sk-…", secure: true)

                HStack(spacing: 10) {
                    Button("Save key") { save() }
                        .buttonStyle(WFPrimaryButtonStyle())
                    Button("Remove") { remove() }
                        .buttonStyle(WFSecondaryButtonStyle())
                }

                if let message {
                    Text(message)
                        .font(WFTheme.font(12))
                        .foregroundStyle(WFTheme.muted)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private var privacyNote: some View {
        Text("Keys are stored in the iOS Keychain on this device. They are never uploaded, logged, or bundled with the app.")
            .font(WFTheme.font(11))
            .foregroundStyle(WFTheme.muted)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 28)
    }

    private func field(_ label: String, text: Binding<String>, placeholder: String, secure: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(WFTheme.font(11, weight: .semibold))
                .foregroundStyle(WFTheme.muted)
            Group {
                if secure {
                    SecureField(placeholder, text: text)
                } else {
                    TextField(placeholder, text: text)
                }
            }
            .font(WFTheme.font(14))
            .foregroundStyle(.white)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding(12)
            .background(WFTheme.surfaceRaised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func loadExisting() {
        guard let config = byo.configuration else { return }
        baseURL = config.baseURL
        model = config.model
        apiKey = byo.apiKey ?? ""
        if let match = BYOProvider.allCases.first(where: { $0.displayName == config.providerName }) {
            provider = match
        } else {
            provider = .custom
        }
    }

    private func save() {
        guard !baseURL.trimmingCharacters(in: .whitespaces).isEmpty,
              !model.trimmingCharacters(in: .whitespaces).isEmpty,
              !apiKey.trimmingCharacters(in: .whitespaces).isEmpty else {
            message = "Base URL, model, and key are all required."
            return
        }
        let config = BYOConfiguration(providerName: provider.displayName, baseURL: baseURL, model: model)
        byo.save(configuration: config, apiKey: apiKey)
        message = "Saved. Cloud checks will use your key first."
    }

    private func remove() {
        byo.clear()
        apiKey = ""
        message = "Removed your key. Cloud checks fall back to the built-in channel."
    }
}
