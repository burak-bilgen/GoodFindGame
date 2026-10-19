import SwiftUI

struct DeadlineView: View {
    let store: GameStore
    let target: Date
    let titleKey: String
    @Environment(\.locale) private var locale
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(GameText.string(titleKey, locale: locale))
            if let projected = store.projectedDeadline(target) { Text(projected, style: .timer).monospacedDigit() }
            else { Text("time.unavailable") }
        }.font(.subheadline).foregroundStyle(.secondary)
    }
}

struct WhileAwayView: View {
    let store: GameStore
    @Environment(\.locale) private var locale
    var body: some View {
        NavigationStack {
            List {
                ForEach(ResolvedEventKind.allCases, id: \.self) { kind in
                    let outcomes = store.snapshot.awayReport.filter { $0.kind == kind }
                    if !outcomes.isEmpty {
                        NavigationLink {
                            List(outcomes) { outcome in
                                NavigationLink { destination(outcome) } label: {
                                    Text(GameText.string("away.\(kind.rawValue)", locale: locale))
                                    Text(outcome.occurredAt, format: .dateTime.hour().minute().locale(locale))
                                }
                            }.navigationTitle(GameText.string("away.\(kind.rawValue)", locale: locale))
                        } label: {
                            LabeledContent { Text(outcomes.count, format: .number) } label: { Text(GameText.string("away.\(kind.rawValue)", locale: locale)) }
                        }
                    }
                }
            }
            .navigationTitle("away.title")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("action.done") { store.perform { try store.acknowledgeAwayReport() } } } }
        }
    }

    @ViewBuilder private func destination(_ outcome: ResolvedEvent) -> some View {
        if store.snapshot.market.contains(where: { $0.id.rawValue == outcome.targetID }) {
            ConversationView(store: store, listingID: ListingID(outcome.targetID))
        } else if store.snapshot.playerListings.contains(where: { $0.id.rawValue == outcome.targetID }) {
            SaleListingView(store: store, listingID: ListingID(outcome.targetID))
        } else if let shipment = store.snapshot.shipments.first(where: { $0.id == outcome.targetID }), store.snapshot.player.inventory.contains(where: { $0.id == shipment.item.id }) {
            OwnedItemView(store: store, itemID: shipment.item.id)
        } else if let job = store.snapshot.inspectionJobs.first(where: { $0.id == outcome.targetID }), store.snapshot.player.inventory.contains(where: { $0.id == job.itemID }) {
            OwnedItemView(store: store, itemID: job.itemID)
        } else {
            Text("away.alreadyHandled").padding()
        }
    }
}
