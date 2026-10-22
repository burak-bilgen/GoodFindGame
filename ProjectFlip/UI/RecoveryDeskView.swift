import SwiftUI

struct RecoveryDeskView: View {
    let store: GameStore
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market
    @State private var liquidation: ItemID?
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("recovery.principle").font(.subheadline)
                if let id = store.snapshot.recovery.itemID, let item = store.snapshot.player.inventory.first(where: { $0.id == id }) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("recovery.consigned").font(.headline)
                        Text("recovery.task").font(.subheadline).foregroundStyle(.secondary)
                        if let definition = store.definition(for: item) { DeviceArt(symbol: definition.artSymbol, identity: definition.id, appearance: store.appearance(for: item)).frame(height: 180) }
                        if item.inspected {
                            let fee = min(RecoveryEngine.serviceFee, max(.zero, (try? RecoveryEngine.capitalFloor.subtracting(store.snapshot.player.cash)) ?? .zero))
                            Button { store.perform { try store.completeRecovery(); GameFeel.play(.accepted) } } label: {
                                Text(GameText.format("recovery.returnFor", locale: locale, fee.formatted(locale: locale, market: market)))
                            }.buttonStyle(GameButton()).accessibilityIdentifier("completeRecovery")
                        } else {
                            Button("inspection.basic") { store.perform { try store.inspect(itemID: id, professionally: false); GameFeel.play(.reveal) } }.buttonStyle(GameButton()).accessibilityIdentifier("inspectRecovery")
                        }
                    }.gameCard(accent: GameStyle.amber)
                } else if RecoveryEngine.canBegin(store.snapshot) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("recovery.task").font(.subheadline)
                        Text(GameText.format("recovery.limit", locale: locale, RecoveryEngine.capitalFloor.formatted(locale: locale, market: market))).font(.caption).foregroundStyle(.secondary)
                        Button("recovery.begin") { store.perform { try store.beginRecovery(); GameFeel.play(.submitted) } }.buttonStyle(GameButton()).accessibilityIdentifier("beginRecovery")
                    }.gameCard(accent: GameStyle.amber)
                } else { Text("recovery.notEligible").font(.subheadline).foregroundStyle(.secondary) }
                Text("recovery.liquidation").font(.title2.bold())
                Text("recovery.liquidationWarning").font(.caption).foregroundStyle(.secondary)
                ForEach(store.snapshot.player.inventory) { item in
                    if let definition = store.definition(for: item), let quote = try? RecoveryEngine.liquidationQuote(item, definition: definition, state: store.snapshot), quote > .zero {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(definition.displayName(locale: locale)).font(.headline)
                            Text(quote.formatted(locale: locale, market: market)).font(.title3.bold()).foregroundStyle(GameStyle.amber)
                            Button("recovery.liquidate", role: .destructive) { liquidation = item.id }.buttonStyle(GameButton(secondary: true)).accessibilityIdentifier("liquidate.\(item.id.rawValue)")
                        }.gameCard()
                    }
                }
            }.padding(16)
        }.gameScreen().navigationTitle("recovery.title").navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("recovery.confirm", isPresented: Binding(get: { liquidation != nil }, set: { if !$0 { liquidation = nil } }), titleVisibility: .visible) {
                Button("recovery.liquidate", role: .destructive) { if let id = liquidation { store.perform { try store.liquidate(id); GameFeel.play(.loss) } }; liquidation = nil }
                Button("action.cancel", role: .cancel) { liquidation = nil }
            }
    }
}
