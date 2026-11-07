import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = SubscriptionManager.shared

    private enum Tier: String, CaseIterable, Identifiable {
        case free, monthly, yearly
        var id: String { rawValue }
        var title: String {
            switch self {
            case .free: return "Free"
            case .monthly: return "Monthly"
            case .yearly: return "Annual"
            }
        }
    }

    @State private var tier: Tier = .yearly
    @State private var isPurchasing = false
    @State private var alertMessage: String?

    private let privacyURL = URL(string: "https://asunnyboy861.github.io/WakeForge/privacy.html")!
    private let termsURL = URL(string: "https://asunnyboy861.github.io/WakeForge/terms.html")!
    private let supportURL = URL(string: "https://asunnyboy861.github.io/WakeForge/support.html")!

    var body: some View {
        NavigationStack {
            ZStack {
                WFTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        header
                        tierCards
                        purchaseButton
                        restoreRow
                        legalBlock
                    }
                    .padding(.vertical, 18)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
        .alert("Subscription", isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button("OK", role: .cancel) { alertMessage = nil }
        } message: {
            Text(alertMessage ?? "")
        }
        .task {
            await manager.loadProducts()
            await manager.refreshEntitlement()
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(WFTheme.emberGradient)
            Text("WakeForge Pro")
                .font(WFTheme.font(30, weight: .black))
                .foregroundStyle(.white)
            Text("Unlimited wakes. Cloud photo checks that understand your photo. No snooze.")
                .font(WFTheme.font(14))
                .foregroundStyle(WFTheme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
        }
        .padding(.top, 10)
    }

    private var tierCards: some View {
        VStack(spacing: 10) {
            tierCard(.free)
            tierCard(.monthly)
            tierCard(.yearly)
        }
        .padding(.horizontal, 20)
    }

    private func tierCard(_ option: Tier) -> some View {
        Button {
            tier = option
        } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(option.title)
                            .font(WFTheme.font(17, weight: .bold))
                            .foregroundStyle(.white)
                        if option == .yearly {
                            Text("Best value")
                                .font(WFTheme.font(10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(WFTheme.forge, in: Capsule())
                        }
                    }
                    Text(detail(for: option))
                        .font(WFTheme.font(12))
                        .foregroundStyle(WFTheme.muted)
                    if option == .yearly {
                        Text("7-day free trial, then $29.99 per year")
                            .font(WFTheme.font(11))
                            .foregroundStyle(WFTheme.muted)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(priceLabel(for: option))
                        .font(WFTheme.font(19, weight: .black))
                        .foregroundStyle(option == .yearly ? WFTheme.gold : .white)
                    if option == .yearly {
                        Text("$0.08 / day")
                            .font(WFTheme.font(10))
                            .foregroundStyle(WFTheme.muted)
                    }
                }
                Image(systemName: tier == option ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(tier == option ? WFTheme.forge : WFTheme.muted)
                    .font(.system(size: 18))
                    .padding(.top, 2)
            }
            .padding(16)
            .background(WFTheme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(tier == option ? WFTheme.forge.opacity(0.7) : Color.clear, lineWidth: 1.5)
            )
            .scaleEffect(tier == option ? 1.01 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(option.title) plan, \(priceLabel(for: option))")
        .accessibilityAddTraits(tier == option ? .isSelected : [])
    }

    private func detail(for option: Tier) -> String {
        switch option {
        case .free:
            return "3 wakes per week · all task types · full streak tracking"
        case .monthly:
            return "Unlimited wakes · cloud photo checks · custom sounds"
        case .yearly:
            return "Everything in Monthly · more daily photo checks · milestone cards"
        }
    }

    private func priceLabel(for option: Tier) -> String {
        switch option {
        case .free:
            return "$0"
        case .monthly:
            return manager.monthlyProduct?.displayPrice ?? "$6.99 / mo"
        case .yearly:
            return manager.yearlyProduct?.displayPrice ?? "$29.99 / yr"
        }
    }

    private var purchaseButton: some View {
        VStack(spacing: 8) {
            Button {
                Task { await purchase() }
            } label: {
                if isPurchasing {
                    ProgressView().tint(.white)
                } else {
                    Text(tier == .free ? "Keep using Free" : (tier == .yearly ? "Start 7-day free trial" : "Subscribe monthly"))
                }
            }
            .buttonStyle(WFPrimaryButtonStyle())
            .disabled(isPurchasing)
            .padding(.horizontal, 20)

            Text("Subscription automatically renews unless canceled at least 24 hours before the end of the current period. Manage or cancel anytime in Settings → Subscription.")
                .font(WFTheme.font(10))
                .foregroundStyle(WFTheme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 26)
        }
    }

    private var restoreRow: some View {
        HStack(spacing: 18) {
            Button("Restore Purchases") {
                Task {
                    await manager.restore()
                    alertMessage = manager.isPro ? "Pro restored." : "No active subscription found."
                }
            }
            .font(WFTheme.font(12, weight: .semibold))
            .foregroundStyle(WFTheme.muted)

            if let error = manager.errorMessage {
                Text(error)
                    .font(WFTheme.font(11))
                    .foregroundStyle(WFTheme.danger)
            }
        }
    }

    private var legalBlock: some View {
        VStack(spacing: 8) {
            HStack(spacing: 18) {
                Link("Privacy Policy", destination: privacyURL)
                Link("Terms of Use", destination: termsURL)
                Link("Support", destination: supportURL)
            }
            .font(WFTheme.font(12, weight: .semibold))
            .foregroundStyle(WFTheme.gold)

            Text("Prices shown are in USD. Payment is charged to your Apple Account at confirmation of purchase.")
                .font(WFTheme.font(10))
                .foregroundStyle(WFTheme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 26)
        }
        .padding(.bottom, 24)
    }

    private func purchase() async {
        if tier == .free {
            dismiss()
            return
        }
        guard let product = tier == .yearly ? manager.yearlyProduct : manager.monthlyProduct else {
            alertMessage = "Subscription options are not available right now. Please try again later."
            return
        }
        isPurchasing = true
        let success = await manager.purchase(product)
        isPurchasing = false
        if success {
            dismiss()
        } else if let error = manager.errorMessage {
            alertMessage = error
        }
    }
}
