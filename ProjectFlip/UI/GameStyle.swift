import SwiftUI

/// The game's world uses one appearance, including sheets and native controls.
/// Set both the presentation preference and environment at the window boundary.
struct GameTheme: ViewModifier {
    func body(content: Content) -> some View {
        content.preferredColorScheme(.dark).environment(\.colorScheme, .dark)
            .tint(GameStyle.gain)
            .background(GameStyle.ink)
    }
}

/// Midnight trading desk: deep blue panels, mint instruments and amber actions.
enum GameStyle {
    static let ink = Color("LaunchBackground")
    static let panel = Color(red: 0.085, green: 0.13, blue: 0.19)
    static let panelTop = Color(red: 0.12, green: 0.19, blue: 0.26)
    static let line = Color(red: 0.25, green: 0.39, blue: 0.47)
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
    func body(content: Content) -> some View {
        content.padding(16)
            .background(LinearGradient(colors: [GameStyle.panelTop, GameStyle.panel], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(accent?.opacity(0.65) ?? GameStyle.line.opacity(0.65), lineWidth: 1))
            .overlay(alignment: .topLeading) {
                Capsule().fill(accent ?? GameStyle.gain.opacity(0.7)).frame(width: 28, height: 3).padding(.leading, 18)
            }
            .background(RoundedRectangle(cornerRadius: 18).fill(.black.opacity(0.45)).offset(y: 5))
            .gameEntrance()
    }
}

private struct GameScreenStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.scrollContentBackground(.hidden)
            .background { GameBackdrop().ignoresSafeArea() }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar(.hidden, for: .tabBar)
    }
}

/// A static instrument grid gives screens a game-world surface, with no render timer.
struct GameBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.07, green: 0.13, blue: 0.20), GameStyle.ink], startPoint: .topLeading, endPoint: .bottomTrailing)
            Canvas { context, size in
                var grid = Path()
                for x in stride(from: CGFloat(0), through: size.width, by: 36) { grid.move(to: CGPoint(x: x, y: 0)); grid.addLine(to: CGPoint(x: x, y: size.height)) }
                for y in stride(from: CGFloat(0), through: size.height, by: 36) { grid.move(to: CGPoint(x: 0, y: y)); grid.addLine(to: CGPoint(x: size.width, y: y)) }
                context.stroke(grid, with: .color(GameStyle.gain.opacity(0.035)), lineWidth: 0.5)
                for index in 0..<18 {
                    let x = CGFloat((index * 97 + 13) % 400) / 400 * size.width
                    let y = CGFloat((index * 131 + 37) % 850) / 850 * size.height
                    context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 2, height: 2)), with: .color(GameStyle.gain.opacity(0.16)))
                }
            }
        }.accessibilityHidden(true).allowsHitTesting(false)
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
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .offset(y: configuration.isPressed ? 2 : 0)
            .animation(reduceMotion ? nil : .spring(response: 0.24, dampingFraction: 0.6), value: configuration.isPressed)
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
        Text(GameText.string(key, locale: locale)).font(.caption2.weight(.heavy)).tracking(1.5).foregroundStyle(GameStyle.gain)
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
                Text(LocalizedStringKey(titleKey)).font(.system(.title2, design: .rounded, weight: .black))
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
