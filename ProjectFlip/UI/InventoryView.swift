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
                if !item.inspected {
                    Button("inspection.basic") {
                        store.perform { try store.commit(InspectionEngine().inspect(itemID: item.id, professionally: false, state: store.snapshot)) }
                    }.accessibilityIdentifier("basicInspect")
                } else {
                    LabeledContent("inspection.condition") { Text(item.condition, format: .number) }
                    switch Result(catching: { try InspectionEngine().estimatedValue(item: item, definition: definition) }) {
                    case .success(let estimate):
                        LabeledContent("inspection.estimatedValue") { Text(estimate.formatted(locale: locale)) }
                    case .failure:
                        Text("inspection.valueUnavailable").foregroundStyle(.secondary)
                    }
                    Text("inspection.estimateWarning").font(.caption).foregroundStyle(.secondary)
                    if item.revealedDefects.isEmpty {
                        Text(item.professionallyInspected ? "inspection.professionalClean" : "inspection.noObviousFault")
                    }
                }
                if !item.professionallyInspected {
                    Section("inspection.professional") {
                        Text("inspection.professionalDescription")
                        Text(InspectionEngine().professionalCost.formatted(locale: locale)).bold()
                        Button("inspection.professionalStart") {
                            store.perform { try store.commit(InspectionEngine().inspect(itemID: item.id, professionally: true, state: store.snapshot)) }
                        }.accessibilityIdentifier("professionalInspect")
                    }
                }
                ForEach(item.revealedDefects, id: \.self) { defect in Text(GameText.string(defect.key, locale: locale)) }
                if item.inspected && !store.snapshot.playerListings.contains(where: { $0.itemID == item.id && $0.status == .active }) {
                    NavigationLink("selling.create") { CreateListingView(store: store, itemID: item.id) }
                        .accessibilityIdentifier("createListing")
                } else if store.snapshot.playerListings.contains(where: { $0.itemID == item.id && $0.status == .active }) {
                    Text("selling.alreadyListed").foregroundStyle(.secondary)
                }
            }.navigationTitle("inventory.title")
                .sensoryFeedback(.success, trigger: item.inspected)
        }
    }
}
