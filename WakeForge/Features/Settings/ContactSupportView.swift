import SwiftUI

struct ContactSupportView: View {
    @State private var subject: SupportSubject = .general
    @State private var customSubject = ""
    @State private var name = ""
    @State private var email = ""
    @State private var message = ""
    @State private var isSending = false
    @State private var resultMessage: String?
    @State private var isError = false

    private let maxMessage = 1000

    var body: some View {
        ZStack {
            WFTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    subjectGrid
                    if subject == .other {
                        customField
                    }
                    inputField("Name", text: $name, placeholder: "Your name")
                    inputField("Email", text: $email, placeholder: "yourname@example.com", keyboard: .emailAddress)
                    messageField
                    submitButton
                    if let resultMessage {
                        Text(resultMessage)
                            .font(WFTheme.font(13, weight: .semibold))
                            .foregroundStyle(isError ? WFTheme.danger : WFTheme.success)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    Text("We only use your email to respond to this feedback.")
                        .font(WFTheme.font(11))
                        .foregroundStyle(WFTheme.muted)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.vertical, 18)
            }
        }
        .navigationTitle("Contact Support")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }

    private var subjectGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Subject")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(SupportSubject.allCases.filter { $0 != .other }) { item in
                    tile(item)
                }
            }
            tile(.other)
        }
        .padding(.horizontal, 20)
    }

    private func tile(_ item: SupportSubject) -> some View {
        Button {
            subject = item
        } label: {
            VStack(spacing: 6) {
                Image(systemName: item.symbol)
                    .font(.system(size: 18, weight: .semibold))
                Text(item.title)
                    .font(WFTheme.font(12, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(subject == item ? .white : WFTheme.muted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(subject == item ? WFTheme.forge : WFTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(subject == item ? WFTheme.gold : Color.white.opacity(0.06), lineWidth: 1)
            )
            .overlay(alignment: .topTrailing) {
                if subject == item {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.white)
                        .padding(7)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(item.title), \(subject == item ? "selected" : "not selected")")
    }

    private var customField: some View {
        inputField("Custom subject", text: $customSubject, placeholder: "What is this about?")
    }

    private var messageField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Message")
                .font(WFTheme.font(12, weight: .semibold))
                .foregroundStyle(WFTheme.muted)
            TextEditor(text: $message)
                .font(WFTheme.font(15))
                .foregroundStyle(.white)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 140)
                .padding(10)
                .background(WFTheme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .onChange(of: message) { _, value in
                    if value.count > maxMessage {
                        message = String(value.prefix(maxMessage))
                    }
                }
            Text("\(message.count) / \(maxMessage)")
                .font(WFTheme.font(10))
                .foregroundStyle(WFTheme.muted)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 20)
    }

    private var submitButton: some View {
        Button {
            Task { await submit() }
        } label: {
            if isSending {
                ProgressView().tint(.white)
            } else {
                Text("Submit")
            }
        }
        .buttonStyle(WFPrimaryButtonStyle(enabled: canSubmit))
        .disabled(!canSubmit || isSending)
        .padding(.horizontal, 20)
    }

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        isValidEmail(email) &&
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (subject != .other || !customSubject.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    private func inputField(_ label: String, text: Binding<String>, placeholder: String, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(WFTheme.font(12, weight: .semibold))
                .foregroundStyle(WFTheme.muted)
            TextField(placeholder, text: text)
                .font(WFTheme.font(15))
                .foregroundStyle(.white)
                .keyboardType(keyboard)
                .textContentType(keyboard == .emailAddress ? .emailAddress : .name)
                .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
                .autocorrectionDisabled(keyboard == .emailAddress)
                .padding(14)
                .background(WFTheme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(.horizontal, 20)
    }

    private func isValidEmail(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        return trimmed.contains("@") && trimmed.contains(".") && trimmed.count >= 5
    }

    private func submit() async {
        isSending = true
        resultMessage = nil
        let finalSubject = subject == .other ? customSubject : subject.title
        do {
            try await FeedbackService.submit(name: name, email: email, subject: finalSubject, message: message)
            isError = false
            resultMessage = "Thank you. Your feedback has been sent."
            message = ""
        } catch {
            isError = true
            resultMessage = (error as? LocalizedError)?.errorDescription ?? "Something went wrong. Please try again."
        }
        isSending = false
    }
}

enum SupportSubject: String, CaseIterable, Identifiable {
    case general
    case feature
    case bug
    case usage
    case performance
    case ui
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: return "General"
        case .feature: return "Feature Suggestion"
        case .bug: return "Bug Report"
        case .usage: return "Usage Question"
        case .performance: return "Performance"
        case .ui: return "UI Improvement"
        case .other: return "Other"
        }
    }

    var symbol: String {
        switch self {
        case .general: return "bubble.left.fill"
        case .feature: return "lightbulb.fill"
        case .bug: return "ant.fill"
        case .usage: return "questionmark.circle.fill"
        case .performance: return "gauge.with.dots.needle.67percent"
        case .ui: return "paintpalette.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}
