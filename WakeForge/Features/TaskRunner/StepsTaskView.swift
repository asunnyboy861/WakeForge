import SwiftUI
import SwiftData

struct StepsTaskView: View {
    @ObservedObject var viewModel: TaskRunnerViewModel
    let context: ModelContext

    @State private var steps: Double = 0
    @State private var isLoading = true
    @State private var checks = 0
    @State private var authorized = false
    @AppStorage("wf.health.enabled") private var healthEnabled = true

    private var goal: Double { Double(viewModel.target) }

    var body: some View {
        VStack(spacing: 22) {
            ZStack {
                Circle()
                    .stroke(WFTheme.surfaceRaised, lineWidth: 12)
                Circle()
                    .trim(from: 0, to: min(1, steps / max(goal, 1)))
                    .stroke(WFTheme.emberGradient, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Text("\(Int(steps))")
                        .font(WFTheme.font(44, weight: .black))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                    Text("of \(viewModel.target)")
                        .font(WFTheme.font(14, weight: .medium))
                        .foregroundStyle(WFTheme.muted)
                }
            }
            .frame(width: 210, height: 210)

            Text(healthEnabled ? (authorized ? "Walk until the ring closes. We read today's step count from Apple Health." : "Allow Apple Health access to verify your steps.") : "Step verification is turned off in Settings. Enable HealthKit step verification or pick another task.")
                .font(WFTheme.font(14))
                .foregroundStyle(WFTheme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            VStack(spacing: 12) {
                if healthEnabled {
                    Button {
                        Task { await refresh() }
                    } label: {
                        Label("Check steps", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(WFPrimaryButtonStyle())
                    .disabled(isLoading)
                }

                if !StepsService.shared.isAvailable || !healthEnabled {
                    Button("Use another task") {
                        viewModel.registerFailure(reason: healthEnabled ? "Health data isn't available on this device." : "HealthKit step verification is off.")
                    }
                    .buttonStyle(WFSecondaryButtonStyle())
                }
            }
            .padding(.horizontal, 24)
        }
        .task {
            guard healthEnabled else {
                isLoading = false
                return
            }
            authorized = await StepsService.shared.requestAuthorization()
            await refresh()
        }
    }

    private func refresh() async {
        isLoading = true
        let value = await StepsService.shared.todaySteps() ?? 0
        steps = value
        isLoading = false
        if value >= goal {
            viewModel.succeeded(reps: 0, in: context)
            return
        }
        checks += 1
        if checks >= 3 {
            viewModel.registerFailure(reason: "You are \(Int(max(0, goal - value))) steps short. Switch task or keep walking.")
            checks = 0
        }
    }
}
