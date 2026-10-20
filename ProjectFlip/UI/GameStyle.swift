import SwiftUI

/// Shared visual language: warm paper, ink, category color, strong action hierarchy.
enum GameStyle {
    static let ink = Color(red: 0.10, green: 0.17, blue: 0.21)
    static let gain = Color("AccentColor")
    static let loss = Color("LossColor")
    static func category(_ category: ItemCategory) -> Color {
        switch category {
        case .gaming: Color("GamingCategory")
        case .cameras: Color("CameraCategory")
        case .retro: Color("RetroCategory")
        }
    }
}

extension View {
    func gameCard() -> some View {
        padding(16)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(.primary.opacity(0.06), lineWidth: 1))
    }
    func gameScreen() -> some View {
        modifier(GameScreenStyle())
    }
}

private struct GameScreenStyle: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    func body(content: Content) -> some View {
        content.scrollContentBackground(.hidden)
            .background(scheme == .dark ? Color(uiColor: .systemGroupedBackground) : Color(red: 0.97, green: 0.96, blue: 0.93))
    }
}

struct GameButton: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).frame(maxWidth: .infinity).padding(.vertical, 14).padding(.horizontal, 12)
            .foregroundStyle(Color(uiColor: .systemBackground))
            .background(Color("AccentColor").opacity(!enabled ? 0.4 : configuration.isPressed ? 0.75 : 1), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct GameEyebrow: View {
    let key: String
    @Environment(\.locale) private var locale
    var body: some View {
        Text(GameText.string(key, locale: locale)).font(.caption.weight(.heavy)).tracking(1.4).foregroundStyle(.secondary)
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
