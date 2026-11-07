import SwiftUI

enum WFTheme {
    static let forge = Color(red: 1.0, green: 0.416, blue: 0.0)
    static let gold = Color(red: 1.0, green: 0.761, blue: 0.294)
    static let success = Color(red: 0.204, green: 0.780, blue: 0.349)
    static let background = Color(red: 0.039, green: 0.039, blue: 0.043)
    static let surface = Color(red: 0.078, green: 0.078, blue: 0.086)
    static let surfaceRaised = Color(red: 0.117, green: 0.117, blue: 0.125)
    static let muted = Color(red: 0.557, green: 0.557, blue: 0.576)
    static let danger = Color(red: 1.0, green: 0.271, blue: 0.227)

    static let emberGradient = LinearGradient(
        colors: [forge, gold],
        startPoint: .bottomLeading,
        endPoint: .topTrailing
    )

    static func font(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

struct WFCard<Content: View>: View {
    var padding: CGFloat = 18
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(WFTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
    }
}

struct WFPrimaryButtonStyle: ButtonStyle {
    var enabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(WFTheme.font(18, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(enabled ? WFTheme.emberGradient : LinearGradient(colors: [WFTheme.surfaceRaised, WFTheme.surfaceRaised], startPoint: .top, endPoint: .bottom))
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct WFSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(WFTheme.font(16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(WFTheme.surfaceRaised)
            )
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

struct TaskGlyph: View {
    let kind: TaskKind
    var size: CGFloat = 44

    var body: some View {
        Image(systemName: kind.symbolName)
            .font(.system(size: size * 0.42, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                    .fill(WFTheme.emberGradient)
            )
            .accessibilityHidden(true)
    }
}

struct StreakFlame: View {
    let count: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .foregroundStyle(WFTheme.gold)
                .symbolEffect(.pulse, options: .repeating, isActive: count > 0)
            Text("\(count)")
                .font(WFTheme.font(17, weight: .bold))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
            Text(count == 1 ? "day" : "days")
                .font(WFTheme.font(13, weight: .medium))
                .foregroundStyle(WFTheme.muted)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Streak \(count) days")
    }
}

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(WFTheme.font(12, weight: .bold))
            .tracking(1.2)
            .foregroundStyle(WFTheme.muted)
    }
}
