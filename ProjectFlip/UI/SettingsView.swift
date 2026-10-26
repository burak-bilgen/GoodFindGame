import SwiftUI
import UIKit

struct SettingsView: View {
    let store: GameStore
    @AppStorage("gameSoundEnabled") private var sounds = false
    @Environment(\.locale) private var locale
    @Environment(\.openURL) private var openURL
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    Label("settings.experience", systemImage: "waveform").font(.headline)
                    Toggle("feel.sounds", isOn: $sounds).tint(GameStyle.gain).accessibilityIdentifier("soundSetting")
                    Text("feel.soundsHint").font(.caption).foregroundStyle(GameStyle.secondaryText)
                    Text("settings.accessibility").font(.caption).foregroundStyle(GameStyle.secondaryText)
                }.gameCard()
                VStack(alignment: .leading, spacing: 14) {
                    Label("region.title", systemImage: "globe").font(.headline)
                    Picker("region.currency", selection: Binding(get: { store.snapshot.marketConfiguration.currency }, set: { value in
                        store.perform { var next = store.snapshot; next.marketConfiguration.currency = value; try store.commit(next) }
                    })) {
                        ForEach(GameCurrency.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }.tint(GameStyle.gain).accessibilityIdentifier("displayCurrency")
                    Text("region.fx").font(.caption).foregroundStyle(GameStyle.secondaryText)
                    LabeledContent("settings.language") { Text(locale.localizedString(forLanguageCode: locale.language.languageCode?.identifier ?? "en") ?? "English") }
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        Button("settings.changeLanguage") { openURL(url) }.buttonStyle(GameButton(secondary: true))
                    }
                    Text("region.fixed").font(.caption).foregroundStyle(GameStyle.secondaryText).accessibilityIdentifier("sharedMarketExplanation")
                }.gameCard()
                NavigationLink { NotificationSettingsView(store: store) } label: { GameMenuRow(titleKey: "notifications.settings", symbol: "bell.badge.fill") }.buttonStyle(.plain).accessibilityIdentifier("notificationSettings")
                if store.snapshot.sharedMarketMigrationNotice || store.snapshot.economyMigrationNotice {
                    NavigationLink { MarketSettingsView(store: store) } label: { GameMenuRow(titleKey: "region.migrationTitle", symbol: "info.circle") }.buttonStyle(.plain)
                }
                NavigationLink { SupportView() } label: { GameMenuRow(titleKey: "support.title", symbol: "questionmark.circle") }.buttonStyle(.plain).accessibilityIdentifier("openSupport")
                NavigationLink { PrivacyView() } label: { GameMenuRow(titleKey: "privacy.title", symbol: "hand.raised") }.buttonStyle(.plain).accessibilityIdentifier("openPrivacy")
                VStack(alignment: .leading, spacing: 8) {
                    Text("notifications.title").font(.headline)
                    Text("settings.localSave").font(.caption).foregroundStyle(GameStyle.secondaryText)
                    LabeledContent("settings.version") { Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0") }
                }.font(.caption).gameCard()
            }.padding(16)
        }.gameScreen().navigationTitle("settings.title").navigationBarTitleDisplayMode(.inline)
    }
}
