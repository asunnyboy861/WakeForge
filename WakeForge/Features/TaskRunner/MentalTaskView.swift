import SwiftUI
import SwiftData

struct MentalTaskView: View {
    @ObservedObject var viewModel: TaskRunnerViewModel
    let context: ModelContext

    @State private var challenge: MorningChallenge?
    @State private var answer = ""
    @State private var isLoading = true
    @State private var isJudging = false
    @State private var feedback: String?

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(WFTheme.gold)
                Text(challenge?.question ?? "Preparing your challenge…")
                    .font(WFTheme.font(22, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .frame(minHeight: 120)

            if let feedback {
                Text(feedback)
                    .font(WFTheme.font(13, weight: .medium))
                    .foregroundStyle(WFTheme.danger)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            TextField("Type your answer", text: $answer, axis: .vertical)
                .font(WFTheme.font(17))
                .foregroundStyle(.white)
                .padding(16)
                .background(WFTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .lineLimit(2...5)
                .padding(.horizontal, 24)
                .textInputAutocapitalization(.sentences)

            Button {
                Task { await submit() }
            } label: {
                if isJudging {
                    ProgressView().tint(.white)
                } else {
                    Text("Submit answer")
                }
            }
            .buttonStyle(WFPrimaryButtonStyle(enabled: !answer.isEmpty && challenge != nil))
            .disabled(answer.isEmpty || challenge == nil || isJudging)
            .padding(.horizontal, 24)

            Spacer(minLength: 0)
        }
        .padding(.top, 20)
        .task {
            let streak = StreakStore.shared.state(in: context).current
            challenge = await AIProviderRouter.shared.makeChallenge(streak: streak, recent: [])
            isLoading = false
        }
    }

    private func submit() async {
        guard let challenge else { return }
        isJudging = true
        feedback = nil
        let streak = StreakStore.shared.state(in: context).current
        let passed = await AIProviderRouter.shared.judgeAnswer(answer, challenge: challenge, streak: streak)
        isJudging = false
        if passed {
            viewModel.succeeded(reps: 0, in: context)
        } else {
            feedback = "That answer did not land. Try again or switch tasks."
            answer = ""
            viewModel.registerFailure(reason: "Answer did not match the challenge.")
        }
    }
}
