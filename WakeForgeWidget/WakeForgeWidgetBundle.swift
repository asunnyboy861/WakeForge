import WidgetKit
import SwiftUI
import ActivityKit
import AlarmKit

struct WakeForgeAlarmWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<WFTaskMetadata>.self) { context in
            lockScreenView(context: context)
                .activityBackgroundTint(Color.black)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(Color(red: 1.0, green: 0.416, blue: 0.0))
                }
                DynamicIslandExpandedRegion(.center) {
                    Text("Rise & Fight")
                        .font(.system(.headline, design: .rounded))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.attributes.metadata?.target ?? 10)")
                        .font(.system(.headline, design: .rounded))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(taskTitle(context: context))
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: "flame.fill")
                    .foregroundStyle(Color(red: 1.0, green: 0.416, blue: 0.0))
            } compactTrailing: {
                Text("\(context.attributes.metadata?.target ?? 10)")
                    .font(.system(.caption2, design: .rounded))
            } minimal: {
                Image(systemName: "flame.fill")
                    .foregroundStyle(Color(red: 1.0, green: 0.416, blue: 0.0))
            }
        }
    }

    private func lockScreenView(context: ActivityViewContext<AlarmAttributes<WFTaskMetadata>>) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color(red: 1.0, green: 0.761, blue: 0.294))
            VStack(alignment: .leading, spacing: 3) {
                Text("WakeForge")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(.secondary)
                Text(taskTitle(context: context))
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .foregroundStyle(.white)
                Text("No snooze. Just reps.")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .widgetURL(URL(string: "wakeforge://task?alarm=\(context.attributes.metadata?.alarmID ?? "")"))
    }

    private func taskTitle(context: ActivityViewContext<AlarmAttributes<WFTaskMetadata>>) -> String {
        let title = context.attributes.metadata?.taskTitle ?? "Push-ups"
        let target = context.attributes.metadata?.target ?? 10
        return "\(title) × \(target)"
    }
}

@main
struct WakeForgeWidgetBundle: WidgetBundle {
    var body: some Widget {
        WakeForgeAlarmWidget()
    }
}
