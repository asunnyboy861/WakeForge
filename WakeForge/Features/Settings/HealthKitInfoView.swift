import SwiftUI

struct HealthKitInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                WFTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 54))
                            .foregroundStyle(.red)
                            .padding(.top, 24)
                        Text("HealthKit Integration")
                            .font(WFTheme.font(24, weight: .bold))
                            .foregroundStyle(.white)
                        Text("WakeForge reads today's step count through the HealthKit framework so a step task can be verified before your alarm stops.")
                            .font(WFTheme.font(14))
                            .foregroundStyle(WFTheme.muted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                        VStack(alignment: .leading, spacing: 10) {
                            bullet("Read only", "WakeForge never writes to Apple Health.")
                            bullet("On device", "Step totals stay on your iPhone.")
                            bullet("Optional", "Turn step verification off in Settings at any time.")
                        }
                        .padding(.horizontal, 24)
                        Spacer()
                    }
                }
            }
            .navigationTitle("HealthKit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func bullet(_ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(WFTheme.success)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(WFTheme.font(14, weight: .semibold))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(WFTheme.font(12))
                    .foregroundStyle(WFTheme.muted)
            }
        }
    }
}
