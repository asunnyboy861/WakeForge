import SwiftUI
import SwiftData

struct AlarmEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let profile: AlarmProfile?
    let onSave: () -> Void

    @State private var time: Date
    @State private var kind: TaskKind
    @State private var difficulty: WFDifficulty
    @State private var days: Set<WFWeekday>
    @State private var backupEnabled: Bool
    @State private var showPaywall = false
    @State private var saveError: String?

    @AppStorage("wf.default.task") private var defaultTaskRaw = TaskKind.pushup.rawValue

    init(profile: AlarmProfile?, onSave: @escaping () -> Void) {
        self.profile = profile
        self.onSave = onSave

        let storedKind = profile.map { TaskKind(rawValue: $0.taskKindRaw) ?? .pushup }
            ?? TaskKind(rawValue: UserDefaults.standard.string(forKey: "wf.default.task") ?? "") ?? .pushup

        var components = DateComponents()
        components.hour = profile?.fireHour ?? 7
        components.minute = profile?.fireMinute ?? 0
        let date = Calendar.current.date(from: components) ?? Date()

        _time = State(initialValue: date)
        _kind = State(initialValue: storedKind)
        _difficulty = State(initialValue: profile.map { WFDifficulty(rawValue: $0.difficultyRaw) ?? .standard } ?? .standard)
        _days = State(initialValue: Set(profile?.repeatDays ?? [.monday, .tuesday, .wednesday, .thursday, .friday]))
        _backupEnabled = State(initialValue: profile?.hasBackup ?? false)
    }

    private var target: Int {
        let base = Double(kind.defaultTarget) * difficulty.multiplier
        return max(1, Int(base.rounded()))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                WFTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 22) {
                        DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                            .colorScheme(.dark)

                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "Task")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(TaskKind.allCases) { task in
                                        taskCard(task)
                                    }
                                }
                                .padding(.horizontal, 2)
                            }
                        }
                        .padding(.horizontal, 20)

                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                SectionHeader(title: "Difficulty")
                                Spacer()
                                Text("\(kind.shortTitle) × \(target)")
                                    .font(WFTheme.font(12, weight: .semibold))
                                    .foregroundStyle(WFTheme.gold)
                            }
                            Picker("Difficulty", selection: $difficulty) {
                                ForEach(WFDifficulty.allCases) { level in
                                    Text(level.label).tag(level)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(.horizontal, 20)

                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "Repeat")
                            HStack(spacing: 8) {
                                ForEach(WFWeekday.allCases) { day in
                                    Button {
                                        if days.contains(day) {
                                            days.remove(day)
                                        } else {
                                            days.insert(day)
                                        }
                                    } label: {
                                        Text(day.shortLabel)
                                            .font(WFTheme.font(14, weight: .bold))
                                            .foregroundStyle(days.contains(day) ? .white : WFTheme.muted)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 38)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .fill(days.contains(day) ? WFTheme.forge : WFTheme.surface)
                                            )
                                    }
                                    .accessibilityLabel("Repeat on \(dayName(day))")
                                }
                            }
                            Text(days.isEmpty ? "One-time alarm" : "Repeats every selected day")
                                .font(WFTheme.font(11))
                                .foregroundStyle(WFTheme.muted)
                        }
                        .padding(.horizontal, 20)

                        Toggle(isOn: Binding(
                            get: { backupEnabled },
                            set: { newValue in
                                if newValue && !SubscriptionManager.shared.isPro {
                                    showPaywall = true
                                } else {
                                    backupEnabled = newValue
                                }
                            }
                        )) {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text("Backup alarm (+2 min)")
                                        .font(WFTheme.font(15, weight: .semibold))
                                        .foregroundStyle(.white)
                                    if !SubscriptionManager.shared.isPro {
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 11))
                                            .foregroundStyle(WFTheme.gold)
                                    }
                                }
                                Text("A second alarm if the first one doesn't wake you.")
                                    .font(WFTheme.font(12))
                                    .foregroundStyle(WFTheme.muted)
                            }
                        }
                        .tint(WFTheme.forge)
                        .padding(.horizontal, 20)

                        if let saveError {
                            Text(saveError)
                                .font(WFTheme.font(12))
                                .foregroundStyle(WFTheme.danger)
                        }

                        Button(profile == nil ? "Save alarm" : "Update alarm") {
                            save()
                        }
                        .buttonStyle(WFPrimaryButtonStyle())
                        .padding(.horizontal, 20)

                        if let profile {
                            Button(role: .destructive) {
                                AlarmScheduler.shared.cancel(profile)
                                context.delete(profile)
                                try? context.save()
                                dismiss()
                            } label: {
                                Text("Delete alarm")
                                    .font(WFTheme.font(14, weight: .semibold))
                                    .foregroundStyle(WFTheme.danger)
                            }
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle(profile == nil ? "New Alarm" : "Edit Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private func taskCard(_ task: TaskKind) -> some View {
        Button {
            kind = task
        } label: {
            VStack(spacing: 8) {
                TaskGlyph(kind: task, size: 46)
                Text(task.shortTitle)
                    .font(WFTheme.font(12, weight: .semibold))
                    .foregroundStyle(.white)
                Text("\(task.defaultTarget)")
                    .font(WFTheme.font(10))
                    .foregroundStyle(WFTheme.muted)
            }
            .frame(width: 88)
            .padding(.vertical, 12)
            .background(WFTheme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(kind == task ? WFTheme.forge : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(task.title), \(kind == task ? "selected" : "not selected")")
    }

    private func dayName(_ day: WFWeekday) -> String {
        switch day {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }

    private func save() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let hour = components.hour ?? 7
        let minute = components.minute ?? 0
        let repeatRaw = days.sorted { $0.rawValue < $1.rawValue }.map { String($0.rawValue) }.joined(separator: ",")

        let targetProfile: AlarmProfile
        if let profile {
            profile.fireHour = hour
            profile.fireMinute = minute
            profile.repeatDaysRaw = repeatRaw
            profile.taskKindRaw = kind.rawValue
            profile.taskTarget = target
            profile.difficultyRaw = difficulty.rawValue
            profile.isEnabled = true
            profile.hasBackup = backupEnabled
            targetProfile = profile
        } else {
            let created = AlarmProfile(
                repeatDaysRaw: repeatRaw,
                taskKindRaw: kind.rawValue,
                taskTarget: target,
                difficultyRaw: difficulty.rawValue,
                hasBackup: backupEnabled
            )
            created.fireHour = hour
            created.fireMinute = minute
            context.insert(created)
            targetProfile = created
        }

        defaultTaskRaw = kind.rawValue
        UserDefaults.standard.set(target, forKey: "wf.last.target")
        try? context.save()

        Task {
            let granted = await AlarmScheduler.shared.requestAuthorization()
            guard granted else {
                saveError = "Alarm permission is required. Enable alarms for WakeForge in Settings."
                return
            }
            let scheduled = await AlarmScheduler.shared.schedule(targetProfile)
            if scheduled {
                onSave()
                dismiss()
            } else {
                saveError = "The alarm could not be scheduled. Try again."
            }
        }
    }
}
