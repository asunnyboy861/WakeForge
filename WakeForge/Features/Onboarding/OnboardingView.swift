import SwiftUI
import SwiftData

struct OnboardingView: View {
    @AppStorage("wf.onboarding.done") private var completed = false
    @AppStorage("wf.default.task") private var defaultTaskRaw = TaskKind.pushup.rawValue
    @State private var page = 0
    @State private var showPaywall = false
    @State private var pulse = false

    var body: some View {
        ZStack {
            WFTheme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    if page < 2 {
                        Button("Skip") { completed = true }
                            .font(WFTheme.font(14, weight: .semibold))
                            .foregroundStyle(WFTheme.muted)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                TabView(selection: $page) {
                    introPage.tag(0)
                    taskPage.tag(1)
                    pricePage.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxWidth: 640)
                .animation(.easeInOut, value: page)

                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Capsule()
                            .fill(index == page ? WFTheme.forge : WFTheme.surfaceRaised)
                            .frame(width: index == page ? 22 : 8, height: 8)
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private var introPage: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle()
                    .fill(WFTheme.forge.opacity(0.16))
                    .frame(width: 200, height: 200)
                    .scaleEffect(pulse ? 1.08 : 0.94)
                Circle()
                    .fill(WFTheme.forge.opacity(0.28))
                    .frame(width: 150, height: 150)
                    .scaleEffect(pulse ? 1.05 : 0.95)
                VStack(spacing: 6) {
                    Image(systemName: "alarm.fill")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(WFTheme.gold)
                    Image(systemName: "arrow.down")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(WFTheme.muted)
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }

            VStack(spacing: 10) {
                Text("The alarm you can't cheat")
                    .font(WFTheme.font(30, weight: .black))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
                    .lineLimit(2)
                    .padding(.horizontal, 24)
                Text("It rings. You do the task. Then it stops — verified on this device.")
                    .font(WFTheme.font(16))
                    .foregroundStyle(WFTheme.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
            Spacer()
            Button("Continue") { page = 1 }
                .buttonStyle(WFPrimaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
        }
    }

    private var taskPage: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Pick your morning task")
                    .font(WFTheme.font(28, weight: .black))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text("You can change it any time. Push-ups ×10 is ready to go.")
                    .font(WFTheme.font(15))
                    .foregroundStyle(WFTheme.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }
            .padding(.top, 30)

            VStack(spacing: 10) {
                ForEach(TaskKind.allCases) { kind in
                    Button {
                        defaultTaskRaw = kind.rawValue
                    } label: {
                        HStack(spacing: 14) {
                            TaskGlyph(kind: kind, size: 42)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(kind.title)
                                    .font(WFTheme.font(16, weight: .bold))
                                    .foregroundStyle(.white)
                                Text(subtitle(for: kind))
                                    .font(WFTheme.font(12))
                                    .foregroundStyle(WFTheme.muted)
                            }
                            Spacer()
                            Image(systemName: defaultTask == kind ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(defaultTask == kind ? WFTheme.forge : WFTheme.muted)
                        }
                        .padding(14)
                        .background(WFTheme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(defaultTask == kind ? WFTheme.forge.opacity(0.6) : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(kind.title), \(defaultTask == kind ? "selected" : "not selected")")
                }
            }
            .padding(.horizontal, 20)

            Spacer()

            Button("Continue") { page = 2 }
                .buttonStyle(WFPrimaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
        }
    }

    private var defaultTask: TaskKind {
        TaskKind(rawValue: defaultTaskRaw) ?? .pushup
    }

    private func subtitle(for kind: TaskKind) -> String {
        switch kind {
        case .pushup: return "10 reps, counted by your front camera"
        case .squat: return "15 reps, counted on device"
        case .photo: return "Snap the sky, verified by AI"
        case .steps: return "500 steps from Apple Health"
        case .mental: return "A 30-second brain challenge"
        }
    }

    private var pricePage: some View {
        VStack(spacing: 18) {
            VStack(spacing: 8) {
                Text("Honest pricing")
                    .font(WFTheme.font(28, weight: .black))
                    .foregroundStyle(.white)
                Text("No trial traps. No surprise upgrade.")
                    .font(WFTheme.font(15))
                    .foregroundStyle(WFTheme.muted)
            }
            .padding(.top, 30)

            VStack(spacing: 12) {
                priceRow(title: "Free forever", price: "$0", detail: "3 wakes every week, all task types")
                priceRow(title: "Pro Monthly", price: "$6.99 / mo", detail: "Unlimited wakes, cloud photo checks")
                priceRow(title: "Pro Annual", price: "$29.99 / yr", detail: "7-day free trial, about $0.08 per day", highlighted: true)
            }
            .padding(.horizontal, 20)

            Text("Cancel anytime in Settings → Subscription. We never auto-upgrade your plan.")
                .font(WFTheme.font(12))
                .foregroundStyle(WFTheme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            Spacer()

            VStack(spacing: 10) {
                Button("Start free") {
                    completed = true
                }
                .buttonStyle(WFPrimaryButtonStyle())

                Button("See Pro details") {
                    showPaywall = true
                }
                .buttonStyle(WFSecondaryButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
    }

    private func priceRow(title: String, price: String, detail: String, highlighted: Bool = false) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(WFTheme.font(16, weight: .bold))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(WFTheme.font(12))
                    .foregroundStyle(WFTheme.muted)
            }
            Spacer()
            Text(price)
                .font(WFTheme.font(18, weight: .black))
                .foregroundStyle(highlighted ? WFTheme.gold : .white)
        }
        .padding(16)
        .background(WFTheme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(highlighted ? WFTheme.forge.opacity(0.6) : Color.clear, lineWidth: 1.5)
        )
    }
}
