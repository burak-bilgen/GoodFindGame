import SwiftUI

private struct MarketConfigurationKey: EnvironmentKey { static let defaultValue = MarketConfiguration.us }
extension EnvironmentValues {
    var marketConfiguration: MarketConfiguration {
        get { self[MarketConfigurationKey.self] }
        set { self[MarketConfigurationKey.self] = newValue }
    }
}

struct MarketSettingsView: View {
    let store: GameStore
    @Environment(\.locale) private var locale
    var body: some View {
        GameList {
            Section("region.title") {
                Text("region.shared").font(.headline)
                Text("region.fixed").font(.caption).foregroundStyle(GameStyle.secondaryText)
                Picker("region.currency", selection: Binding(get: { store.snapshot.marketConfiguration.currency }, set: { currency in
                    store.perform { var next = store.snapshot; next.marketConfiguration.currency = currency; try store.commit(next) }
                })) {
                    ForEach(GameCurrency.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }.accessibilityIdentifier("displayCurrency")
                Text("region.fx").font(.caption).foregroundStyle(GameStyle.secondaryText)
            }
            if store.snapshot.sharedMarketMigrationNotice {
                Section("region.migrationTitle") {
                    Text("region.sharedMigration")
                    Button("action.ok") { store.perform { var next = store.snapshot; next.sharedMarketMigrationNotice = false; try store.commit(next) } }
                }
            }
            if store.snapshot.economyMigrationNotice {
                Section("region.migrationTitle") {
                    Text("region.migration")
                    Button("action.ok") { store.perform { var next = store.snapshot; next.economyMigrationNotice = false; try store.commit(next) } }
                }
            }
        }.gameScreen().navigationTitle("region.title").navigationBarTitleDisplayMode(.inline)
    }
}
