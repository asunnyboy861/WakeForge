import SwiftUI
import SwiftData

struct TaskRunnerView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel: TaskRunnerViewModel

    init(alarmID: UUID, profileID: UUID, kind: TaskKind, target: Int) {
        _viewModel = StateObject(wrappedValue: TaskRunnerViewModel(alarmID: alarmID, profileID: profileID, kind: kind, target: target))
    }

    var body: some View {
        ZStack {
            WFTheme.background.ignoresSafeArea()
            switch viewModel.route {
            case .running:
                runningContent
            case .celebration:
                CelebrationView(kind: viewModel.activeKind, target: viewModel.target) {
                    dismissRunner()
                }
            case .released:
                releasedContent
            }
        }
        .preferredColorScheme(.dark)
        .task {
            viewModel.begin(in: context)
        }
    }

    private var runningContent: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("RISE & FIGHT")
                        .font(WFTheme.font(12, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(WFTheme.gold)
                    Text(viewModel.activeKind.title)
                        .font(WFTheme.font(20, weight: .bold))
                        .foregroundStyle(.white)
                }
                Spacer()
                if viewModel.failureLevel > 0 {
                    Text(levelLabel)
                        .font(WFTheme.font(12, weight: .bold))
                        .foregroundStyle(WFTheme.muted)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            Group {
                switch viewModel.activeKind {
                case .pushup, .squat:
                    RepTaskView(viewModel: viewModel, kind: viewModel.activeKind, context: context)
                case .photo:
                    PhotoTaskView(viewModel: viewModel, context: context)
                case .steps:
                    StepsTaskView(viewModel: viewModel, context: context)
                case .mental:
                    MentalTaskView(viewModel: viewModel, context: context)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if viewModel.coolDownSeconds > 0 {
                coolDownBanner
            }

            if let message = viewModel.message {
                Text(message)
                    .font(WFTheme.font(14, weight: .medium))
                    .foregroundStyle(WFTheme.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
            }

            if viewModel.showTaskPicker {
                taskPicker
            }

            Button {
                viewModel.registerFailure(reason: "Switched course before finishing.")
            } label: {
                Text("Can't finish this?")
            }
            .buttonStyle(WFSecondaryButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
            .accessibilityLabel("Cannot finish this task")
            .accessibilityHint("Shows other ways to earn your morning")
        }
    }

    private var levelLabel: String {
        switch viewModel.failureLevel {
        case 0: return ""
        case 1: return "TRY AGAIN"
        case 2: return "SWITCH TASK"
        default: return "COOL-DOWN"
        }
    }

    private var coolDownBanner: some View {
        VStack(spacing: 6) {
            Text("\(viewModel.coolDownSeconds)s")
                .font(WFTheme.font(34, weight: .black))
                .foregroundStyle(WFTheme.gold)
                .contentTransition(.numericText())
            Text("Your alarm releases automatically when this hits zero.")
                .font(WFTheme.font(13))
                .foregroundStyle(WFTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(WFTheme.surface)
        .padding(.horizontal, 20)
    }

    private var taskPicker: some View {
        VStack(spacing: 10) {
            SectionHeader(title: "Switch task")
                .frame(maxWidth: .infinity, alignment: .leading)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(TaskKind.allCases.filter { $0 != viewModel.activeKind }) { kind in
                    Button {
                        viewModel.switchTask(to: kind)
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: kind.symbolName)
                                .font(.system(size: 20, weight: .bold))
                            Text(kind.shortTitle)
                                .font(WFTheme.font(12, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(WFTheme.surfaceRaised)
                        )
                    }
                    .accessibilityLabel("Switch to \(kind.title)")
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }

    private var releasedContent: some View {
        VStack(spacing: 18) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 54))
                .foregroundStyle(WFTheme.muted)
            Text("Alarm released")
                .font(WFTheme.font(28, weight: .bold))
                .foregroundStyle(.white)
            Text("Today is a Skip Day. Your streak resets, and tomorrow is a clean slate.")
                .font(WFTheme.font(15))
                .foregroundStyle(WFTheme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Done") {
                dismissRunner()
            }
            .buttonStyle(WFPrimaryButtonStyle())
            .padding(.horizontal, 24)
            .padding(.top, 10)
        }
    }

    private func dismissRunner() {
        NotificationCenter.default.post(name: .wfDismissTask, object: nil)
    }
}

extension Notification.Name {
    static let wfDismissTask = Notification.Name("wf.dismiss.task")
}
