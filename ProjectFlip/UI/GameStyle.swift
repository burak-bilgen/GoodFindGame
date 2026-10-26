import SwiftUI

/// The game's world uses one appearance, including sheets and native controls.
/// Set both the presentation preference and environment at the window boundary.
struct GameTheme: ViewModifier {
    func body(content: Content) -> some View {
        content.preferredColorScheme(.dark).environment(\.colorScheme, .dark)
            .tint(GameStyle.gain)
            .foregroundStyle(GameStyle.paper)
            .background(GameStyle.ink)
    }
}

/// A quiet charcoal surface, warm paper type and restrained sage accents.
enum GameStyle {
    static let ink = Color("LaunchBackground")
    static let panel = Color(red: 0.105, green: 0.122, blue: 0.115)
    static let panelTop = Color(red: 0.14, green: 0.16, blue: 0.145)
    static let paper = Color(red: 0.95, green: 0.94, blue: 0.88)
    static let secondaryText = Color(red: 0.71, green: 0.75, blue: 0.71)
    static let line = Color(red: 0.28, green: 0.32, blue: 0.29)
    static let amber = Color(red: 0.96, green: 0.75, blue: 0.46)
    static let gain = Color("AccentColor")
    static let loss = Color("LossColor")
    static func category(_ category: ItemCategory) -> Color {
        switch category {
        case .gaming: Color("GamingCategory")
        case .cameras: Color("CameraCategory")
        case .retro: Color("RetroCategory")
        case .home: Color(red: 0.96, green: 0.62, blue: 0.38)
        case .furniture: Color(red: 0.72, green: 0.78, blue: 0.49)
        case .everyday: Color(red: 0.44, green: 0.72, blue: 0.93)
        }
    }
    /// Display lighting is decorative; it never represents price, rarity or truth.
    static func light(_ category: ItemCategory) -> Color {
        switch category {
        case .gaming: Color(red: 0.36, green: 0.83, blue: 0.80)
        case .cameras: Color(red: 0.72, green: 0.62, blue: 1)
        case .retro: amber
        case .home: Color(red: 0.96, green: 0.62, blue: 0.38)
        case .furniture: Color(red: 0.72, green: 0.78, blue: 0.49)
        case .everyday: Color(red: 0.44, green: 0.72, blue: 0.93)
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
    func body(content: Content) -> some View {
        content.padding(18)
            .background(GameStyle.panel, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(accent?.opacity(0.25) ?? GameStyle.line.opacity(0.45), lineWidth: 0.75))
            .gameEntrance()
    }
}

private struct GameScreenStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.scrollContentBackground(.hidden)
            // Final actions must scroll above both the custom dock and native navigation chrome.
            .contentMargins(.bottom, GameDock.scrollClearance, for: .scrollContent)
            .background { GameBackdrop().ignoresSafeArea() }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar(.hidden, for: .tabBar)
    }
}

/// Static depth without a grid or per-frame rendering work.
struct GameBackdrop: View {
    var body: some View {
        ZStack(alignment: .topTrailing) {
            GameStyle.ink
            RadialGradient(colors: [GameStyle.gain.opacity(0.055), .clear], center: .topTrailing, startRadius: 0, endRadius: 500)
        }.accessibilityHidden(true).allowsHitTesting(false)
    }
}

struct GameButton: ButtonStyle {
    var secondary = false
    @Environment(\.isEnabled) private var enabled
    @GameReduceMotion private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(.headline, design: .default, weight: .semibold))
            .frame(maxWidth: .infinity).padding(.vertical, 16).padding(.horizontal, 16)
            .foregroundStyle(secondary ? GameStyle.paper : GameStyle.ink)
            .background(secondary ? GameStyle.panelTop : GameStyle.gain, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(secondary ? GameStyle.line.opacity(0.75) : .clear, lineWidth: 0.75))
            .opacity(enabled ? 1 : 0.4)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct GamePriceFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration.padding(12).background(GameStyle.ink, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(GameStyle.line, lineWidth: 1))
    }
}

struct GameEyebrow: View {
    let key: String
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market
    var body: some View {
        Text(GameText.string(key, locale: locale)).font(.caption2.weight(.semibold)).tracking(0.6).foregroundStyle(GameStyle.gain)
    }
}

/// A visible state label; color always has accompanying text and an icon.
struct GameStamp: View {
    let key: String
    let symbol: String
    var color: Color = GameStyle.gain
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market
    @GameReduceMotion private var reduceMotion
    var body: some View {
        Label(GameText.string(key, locale: locale), systemImage: symbol)
            .font(.caption.weight(.bold)).padding(.horizontal, 10).padding(.vertical, 7)
            .foregroundStyle(color).background(color.opacity(0.10), in: Capsule())
            .symbolEffect(.bounce, options: .nonRepeating, value: reduceMotion ? "" : key)
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

struct GameStageBanner: View {
    let titleKey: String
    let eyebrowKey: String
    let symbol: String
    var color: Color = GameStyle.gain
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 7) {
                GameEyebrow(key: eyebrowKey)
                Text(LocalizedStringKey(titleKey)).font(.system(.title2, design: .default, weight: .bold))
            }
            Spacer(minLength: 0)
            Image(systemName: symbol).font(.system(size: 32, weight: .bold)).foregroundStyle(color)
                .padding(16).background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                .accessibilityHidden(true)
        }.frame(maxWidth: .infinity, alignment: .leading).gameCard(accent: color)
    }
}

struct GameMenuRow: View {
    let titleKey: String
    let symbol: String
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol).font(.title3.bold()).foregroundStyle(GameStyle.gain)
                .frame(width: 28).accessibilityHidden(true)
            Text(LocalizedStringKey(titleKey)).font(.headline).foregroundStyle(.primary)
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(GameStyle.line).accessibilityHidden(true)
        }.frame(maxWidth: .infinity, alignment: .leading).gameCard()
    }
}

/// Native list behavior with the same panel palette as every custom game surface.
struct GameList<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        List { content.listRowBackground(GameStyle.panel).listRowSeparatorTint(GameStyle.line) }
            .listStyle(.insetGrouped).scrollContentBackground(.hidden)
    }
}

struct GameForm<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        Form { content.listRowBackground(GameStyle.panel).listRowSeparatorTint(GameStyle.line) }
            .scrollContentBackground(.hidden)
    }
}
