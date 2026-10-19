import SwiftUI

struct InventoryView: View {
    let store: GameStore
    @Environment(\.locale) private var locale
    var body: some View {
        List {
            if store.snapshot.player.inventory.isEmpty && !store.snapshot.shipments.contains(where: { $0.status == .pending }) {
                Text("inventory.empty").foregroundStyle(.secondary)
            }
            ForEach(store.snapshot.shipments.filter { $0.status == .pending }) { shipment in
                VStack(alignment: .leading, spacing: 8) {
                    if let definition = store.definition(for: shipment.item) { Text(definition.name).font(.headline) }
                    DeadlineView(store: store, target: shipment.arrivesAt, titleKey: "shipping.inTransit")
                }.accessibilityIdentifier("shipment.\(shipment.item.id.rawValue)")
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
                if store.snapshot.inspectionKnowledge.canInspect(item, category: definition.category) {
                    Button(item.inspected ? "knowledge.reinspect" : "inspection.basic") {
                        store.perform { try store.inspect(itemID: item.id, professionally: false) }
                    }.accessibilityIdentifier("basicInspect")
                }
                if item.inspected {
                    LabeledContent("inspection.condition") { Text(item.condition, format: .number) }
                    switch Result(catching: { try InspectionEngine().estimatedValue(item: item, definition: definition, marketBasisPoints: store.snapshot.marketMultiplier(for: definition)) }) {
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
                if let job = store.snapshot.inspectionJobs.first(where: { $0.itemID == item.id && $0.status == .pending }) {
                    DeadlineView(store: store, target: job.completesAt, titleKey: "inspection.pendingReport")
                } else if !item.professionallyInspected {
                    Section("inspection.professional") {
                        Text("inspection.professionalDescription")
                        Text(InspectionEngine().professionalCost.formatted(locale: locale)).bold()
                        Button("inspection.professionalStart") {
                            store.perform { try store.inspect(itemID: item.id, professionally: true) }
                        }.accessibilityIdentifier("professionalInspect")
                    }
                }
                Section("knowledge.title") {
                    KnowledgeSummary(knowledge: store.snapshot.inspectionKnowledge, category: definition.category)
                    Text("knowledge.inspectionLimit").font(.caption).foregroundStyle(.secondary)
                    NavigationLink("knowledge.open") { KnowledgeView(store: store) }
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
