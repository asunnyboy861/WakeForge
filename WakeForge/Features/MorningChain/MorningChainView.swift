import SwiftUI
import SwiftData

struct MorningChainView: View {
    let onFinish: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = MorningChainStore.shared

    var body: some View {
        NavigationStack {
            ZStack {
                WFTheme.background.ignoresSafeArea()
                VStack(spacing: 18) {
                    TimelineView(.periodic(from: .now, by: 1)) { _ in
                        VStack(spacing: 4) {
                            Text(timeLabel)
                                .font(WFTheme.font(32, weight: .black))
                                .foregroundStyle(WFTheme.gold)
                                .contentTransition(.numericText())
                            Text(store.isActive ? "left to finish the chain" : "The window closed")
                                .font(WFTheme.font(13))
                                .foregroundStyle(WFTheme.muted)
                        }
                    }

                    VStack(spacing: 10) {
                        ForEach(MorningChainStore.steps) { step in
                            Button {
                                store.toggle(step.id)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: step.symbol)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(WFTheme.gold)
                                        .frame(width: 30)
                                    Text(step.title)
                                        .font(WFTheme.font(15, weight: .semibold))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Image(systemName: store.completed.contains(step.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(store.completed.contains(step.id) ? WFTheme.success : WFTheme.muted)
                                }
                                .padding(16)
                                .background(WFTheme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .disabled(!store.isActive)
                            .accessibilityLabel("\(step.title), \(store.completed.contains(step.id) ? "done" : "not done")")
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer()

                    Button {
                        if store.isComplete {
                            StreakStore.shared.awardChainCompletion(in: context)
                            dismiss()
                        } else {
                            dismiss()
                        }
                    } label: {
                        Text(store.isComplete ? "Claim chain badge" : "Finish later")
                    }
                    .buttonStyle(WFPrimaryButtonStyle(enabled: store.isComplete))
                    .disabled(!store.isComplete)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
                .padding(.top, 30)
            }
            .navigationTitle("Morning Chain")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var timeLabel: String {
        let seconds = store.secondsRemaining
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
