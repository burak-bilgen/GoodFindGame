import SwiftUI

/// Original trader's workbench: warm paper, ink-blue displays and amber actions.
enum GameStyle {
    static let ink = Color(red: 0.065, green: 0.11, blue: 0.17)
    static let amber = Color(red: 1.0, green: 0.70, blue: 0.32)
    static let gain = Color("AccentColor")
    static let loss = Color("LossColor")
    static func category(_ category: ItemCategory) -> Color {
        switch category {
        case .gaming: Color("GamingCategory")
        case .cameras: Color("CameraCategory")
        case .retro: Color("RetroCategory")
        }
    }
    /// Display lighting is decorative; it never represents price, rarity or truth.
    static func light(_ category: ItemCategory) -> Color {
        switch category {
        case .gaming: Color(red: 0.36, green: 0.83, blue: 0.80)
        case .cameras: Color(red: 0.72, green: 0.62, blue: 1)
        case .retro: amber
        }
    }
}

extension View {
    func gameCard(accent: Color? = nil) -> some View {
        modifier(GameCardStyle(accent: accent))
    }
    func gameScreen() -> some View { modifier(GameScreenStyle()) }
}

private struct GameCardStyle: ViewModifier {
    var accent: Color?
    @Environment(\.colorScheme) private var scheme
    func body(content: Content) -> some View {
        content.padding(16)
            .background(scheme == .dark ? Color(red: 0.10, green: 0.15, blue: 0.21) : Color(red: 1, green: 0.99, blue: 0.96), in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(accent?.opacity(0.55) ?? .primary.opacity(0.10), lineWidth: accent == nil ? 1 : 1.5))
            .background(RoundedRectangle(cornerRadius: 22).fill(scheme == .dark ? .black.opacity(0.35) : GameStyle.ink.opacity(0.10)).offset(y: 4))
    }
}

private struct GameScreenStyle: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    func body(content: Content) -> some View {
        content.scrollContentBackground(.hidden)
            .background {
                (scheme == .dark ? GameStyle.ink : Color(red: 0.94, green: 0.93, blue: 0.88)).ignoresSafeArea()
            }
    }
}

struct GameButton: ButtonStyle {
    var secondary = false
    @Environment(\.isEnabled) private var enabled
    @GameReduceMotion private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(.headline, design: .rounded, weight: .heavy))
            .frame(maxWidth: .infinity).padding(.vertical, 16).padding(.horizontal, 12)
            .foregroundStyle(secondary ? Color.primary : GameStyle.ink)
            .background(LinearGradient(colors: secondary ? [Color.primary.opacity(0.05), Color.primary.opacity(0.08)] : [GameStyle.amber, Color(red: 0.98, green: 0.60, blue: 0.23)], startPoint: .top, endPoint: .bottom), in: RoundedRectangle(cornerRadius: 17))
            .overlay(RoundedRectangle(cornerRadius: 17).strokeBorder(secondary ? Color.primary.opacity(0.22) : .white.opacity(0.35), lineWidth: 1))
            .background(RoundedRectangle(cornerRadius: 17).fill(secondary ? Color.primary.opacity(0.12) : Color(red: 0.56, green: 0.28, blue: 0.08)).offset(y: configuration.isPressed ? 1 : 4))
            .opacity(enabled ? 1 : 0.45)
            .offset(y: configuration.isPressed ? 2 : 0)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct GameEyebrow: View {
    let key: String
    @Environment(\.locale) private var locale
    var body: some View {
        Text(GameText.string(key, locale: locale)).font(.caption2.weight(.heavy)).tracking(1.5).foregroundStyle(.secondary)
    }
}

/// A visible state label; color always has accompanying text and an icon.
struct GameStamp: View {
    let key: String
    let symbol: String
    var color: Color = GameStyle.gain
    @Environment(\.locale) private var locale
    var body: some View {
        Label(GameText.string(key, locale: locale), systemImage: symbol)
            .font(.caption.weight(.bold)).padding(.horizontal, 10).padding(.vertical, 7)
            .foregroundStyle(color).background(color.opacity(0.10), in: Capsule())
    }
}

/// Deterministic, original portraits. Only public NPC identity affects appearance.
struct TraderPortrait: View {
    let identity: Int
    var size: CGFloat = 44
    var body: some View {
        let index = abs(identity % 4)
        let colors: [Color] = [Color(red: 0.47, green: 0.77, blue: 0.75), GameStyle.amber, Color(red: 0.71, green: 0.64, blue: 0.91), Color(red: 0.93, green: 0.61, blue: 0.51)]
        Canvas { context, bounds in
            context.scaleBy(x: bounds.width / 60, y: bounds.height / 60)
            func oval(_ rect: CGRect, _ color: Color) { context.fill(Path(ellipseIn: rect), with: .color(color)) }
            oval(CGRect(x: 7, y: 40, width: 46, height: 36), GameStyle.ink)
            oval(CGRect(x: 17, y: 12, width: 28, height: 35), Color(red: 0.83, green: 0.59, blue: 0.42))
            let hair = Path { p in
                p.move(to: CGPoint(x: 15, y: 27)); p.addQuadCurve(to: CGPoint(x: 42, y: 12), control: CGPoint(x: 10, y: -1))
                p.addQuadCurve(to: CGPoint(x: 46, y: 30), control: CGPoint(x: 51, y: 17))
                p.addLine(to: CGPoint(x: 35, y: 19)); p.closeSubpath()
            }
            context.fill(hair, with: .color(GameStyle.ink))
            oval(CGRect(x: 24, y: 28, width: 3, height: 3), GameStyle.ink)
            oval(CGRect(x: 35, y: 28, width: 3, height: 3), GameStyle.ink)
            if index == 1 || index == 3 {
                context.stroke(Path(roundedRect: CGRect(x: 20, y: 25, width: 22, height: 9), cornerRadius: 3), with: .color(GameStyle.ink), lineWidth: 2)
            }
        }
        .frame(width: size, height: size).background(colors[index], in: RoundedRectangle(cornerRadius: size * 0.32))
        .overlay(RoundedRectangle(cornerRadius: size * 0.32).strokeBorder(.white.opacity(0.25), lineWidth: 1))
        .accessibilityHidden(true)
    }
}

/// Return to the hunt from any navigation stack or notification sheet.
struct HuntActionKey: EnvironmentKey {
    static let defaultValue: @MainActor () -> Void = {}
}
extension EnvironmentValues {
    var returnToHunt: @MainActor () -> Void {
        get { self[HuntActionKey.self] }
        set { self[HuntActionKey.self] = newValue }
    }
}

/// Platform preference with a DEBUG-only override for the same animation paths in QA.
@propertyWrapper struct GameReduceMotion: DynamicProperty {
    @Environment(\.accessibilityReduceMotion) private var platformValue
    var wrappedValue: Bool {
        #if DEBUG
        platformValue || ProcessInfo.processInfo.arguments.contains("--uitest-reduce-motion")
        #else
        platformValue
        #endif
    }
}
