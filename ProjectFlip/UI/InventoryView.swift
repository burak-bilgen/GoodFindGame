import SwiftUI

struct InventoryView: View {
    let store: GameStore
    @Environment(\.locale) private var locale
    var body: some View {
        List {
            if store.snapshot.player.inventory.isEmpty {
                Text("inventory.empty").foregroundStyle(.secondary)
            }
            ForEach(store.snapshot.player.inventory) { item in
                if let definition = store.definition(for: item) {
                    NavigationLink {
                        OwnedItemView(store: store, itemID: item.id)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(definition.name).font(.headline)
                            Text(item.purchasePrice.formatted(locale: locale)).foregroundStyle(.secondary)
                            Text(item.inspected ? "inspection.basicComplete" : "inspection.pendingBasic").font(.caption)
                        }
                    }.accessibilityIdentifier("inventory.\(item.id.rawValue)")
                }
            }
        }.navigationTitle("inventory.title")
    }
}

struct OwnedItemView: View {
    let store: GameStore
    let itemID: ItemID
    @Environment(\.locale) private var locale
    var body: some View {
        if let item = store.snapshot.player.inventory.first(where: { $0.id == itemID }), let definition = store.definition(for: item) {
            List {
                DeviceArt(symbol: definition.artSymbol).frame(height: 180)
                Text(definition.name).font(.title2.bold())
                LabeledContent("purchase.cost") { Text(item.purchasePrice.formatted(locale: locale)) }
                Text(item.inspected ? "inspection.basicComplete" : "inspection.pendingBasic")
                ForEach(item.revealedDefects, id: \.self) { defect in Text(GameText.string(defect.key, locale: locale)) }
            }.navigationTitle("inventory.title")
        }
    }
}
