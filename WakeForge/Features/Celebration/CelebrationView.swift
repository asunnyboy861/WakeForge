import SwiftUI
import SwiftData

struct CelebrationView: View {
    let kind: TaskKind
    let target: Int
    let onDone: () -> Void

    @Environment(\.modelContext) private var context
    @Query private var streaks: [StreakState]
    @State private var showChain = false
    @State private var animate = false

    private var streak: Int {
        streaks.first?.current ?? 0
    }

    var body: some View {
        ZStack {
            WFTheme.background.ignoresSafeArea()
            ConfettiView(active: animate)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 18) {
                Spacer()

                Image(systemName: "sun.horizon.fill")
                    .font(.system(size: 64, weight: .bold))
                    .foregroundStyle(WFTheme.emberGradient)
                    .scaleEffect(animate ? 1 : 0.6)
                    .opacity(animate ? 1 : 0)

                Text("Morning earned.")
                    .font(WFTheme.font(34, weight: .black))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("+1 🔥  \(streak) day\(streak == 1 ? "" : "s") in a row")
                    .font(WFTheme.font(17, weight: .semibold))
                    .foregroundStyle(WFTheme.gold)

                Text(kind == .pushup || kind == .squat ? "\(target) \(kind.shortTitle.lowercased()) before the alarm stopped." : "\(kind.title) completed before the alarm stopped.")
                    .font(WFTheme.font(14))
                    .foregroundStyle(WFTheme.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                VStack(spacing: 12) {
                    ShareLink(item: "I earned my morning with WakeForge. \(streak)-day streak. No snooze, just reps.") {
                        Label("Share streak card", systemImage: "square.and.arrow.up")
                            .font(WFTheme.font(16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(WFTheme.surfaceRaised, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }

                    Button {
                        showChain = true
                    } label: {
                        Label("Start Morning Chain", systemImage: "link")
                    }
                    .buttonStyle(WFPrimaryButtonStyle())

                    Button("Done") {
                        onDone()
                    }
                    .buttonStyle(WFSecondaryButtonStyle())
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            .padding(.top, 40)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                animate = true
            }
        }
        .sheet(isPresented: $showChain, onDismiss: onDone) {
            MorningChainView(onFinish: onDone)
        }
    }
}

struct ConfettiView: View {
    let active: Bool

    private let pieces: [ConfettiPiece] = (0..<48).map { index in
        ConfettiPiece(
            x: Double.random(in: 0...1),
            delay: Double.random(in: 0...0.6),
            size: Double.random(in: 5...11),
            drift: Double.random(in: -0.25...0.25),
            colorIndex: index % 3
        )
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(pieces) { piece in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color(for: piece.colorIndex))
                        .frame(width: piece.size, height: piece.size * 1.6)
                        .position(
                            x: piece.x * proxy.size.width + (active ? piece.drift * proxy.size.width : 0),
                            y: active ? proxy.size.height + 40 : -60 + piece.delay * 80
                        )
                        .rotationEffect(.degrees(active ? 220 : 0))
                        .opacity(active ? 1 : 0)
                        .animation(
                            .easeIn(duration: 1.4).delay(piece.delay),
                            value: active
                        )
                }
            }
        }
    }

    private func color(for index: Int) -> Color {
        switch index {
        case 0: return WFTheme.forge
        case 1: return WFTheme.gold
        default: return WFTheme.success
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id = UUID()
    let x: Double
    let delay: Double
    let size: Double
    let drift: Double
    let colorIndex: Int
}
