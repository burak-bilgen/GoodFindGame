import SwiftUI

struct DeadlineView: View {
    let store: GameStore
    let target: Date
    let titleKey: String
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                GameActivityLights()
                Text(GameText.string(titleKey, locale: locale))
            }
            if let projected = store.projectedDeadline(target) { Text(projected, style: .timer).monospacedDigit() }
            else { Text("time.unavailable") }
        }.font(.subheadline).foregroundStyle(.secondary)
    }
}

struct WhileAwayView: View {
    let store: GameStore
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 10) {
                        Image(systemName: "moon.stars.fill").font(.largeTitle).foregroundStyle(GameStyle.amber).accessibilityHidden(true)
                        Text("game.return").font(.system(.title2, design: .rounded, weight: .black)).foregroundStyle(.white)
                        Text("game.returnHint").font(.subheadline).foregroundStyle(.white.opacity(0.75))
                    }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
                        .background(GameStyle.ink, in: RoundedRectangle(cornerRadius: 22))
                    ForEach(ResolvedEventKind.allCases, id: \.self) { kind in
                        let outcomes = store.snapshot.awayReport.filter { $0.kind == kind }
                        if !outcomes.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(GameText.string("away.\(kind.rawValue)", locale: locale)).font(.headline)
                                    Spacer()
                                    Text(outcomes.count, format: .number).font(.headline.monospacedDigit()).foregroundStyle(GameStyle.gain)
                                }
                                ForEach(outcomes) { outcome in
                                    NavigationLink { destination(outcome) } label: {
                                        HStack(spacing: 12) {
                                            Image(systemName: "arrow.up.right").font(.headline).foregroundStyle(GameStyle.gain)
                                            VStack(alignment: .leading, spacing: 6) {
                                                Text(eventName(outcome)).font(.subheadline.bold()).foregroundStyle(.primary)
                                                Text(outcome.occurredAt, format: .dateTime.hour().minute().locale(locale)).font(.caption).foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.secondary)
                                        }.padding(.vertical, 6)
                                    }.buttonStyle(.plain).accessibilityIdentifier("awayEvent.\(outcome.id)")
                                }
                            }.gameCard()
                        }
                    }
                }.padding(16)
            }.gameScreen()
            .navigationTitle("away.title")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("action.done") { store.perform { try store.acknowledgeAwayReport() } } } }
        }
    }

    private func eventName(_ event: ResolvedEvent) -> String {
        if let listing = store.snapshot.market.first(where: { $0.id.rawValue == event.targetID }), let definition = store.definition(for: listing.item) { return definition.displayName(locale: locale) }
        if let listing = store.snapshot.playerListings.first(where: { $0.id.rawValue == event.targetID }),
           let item = store.snapshot.player.inventory.first(where: { $0.id == listing.itemID }) ?? listing.itemSnapshot,
           let definition = store.definition(for: item) { return definition.displayName(locale: locale) }
        if let shipment = store.snapshot.shipments.first(where: { $0.id == event.targetID }), let definition = store.definition(for: shipment.item) { return definition.displayName(locale: locale) }
        if let job = store.snapshot.inspectionJobs.first(where: { $0.id == event.targetID }),
           let item = store.snapshot.player.inventory.first(where: { $0.id == job.itemID }), let definition = store.definition(for: item) { return definition.displayName(locale: locale) }
        return GameText.string("away.\(event.kind.rawValue)", locale: locale)
    }

    @ViewBuilder private func destination(_ outcome: ResolvedEvent) -> some View {
        if let trend = store.snapshot.marketTrends.first(where: { $0.id == outcome.targetID }) {
            MarketTrendDetailView(store: store, trend: trend)
        } else if store.snapshot.market.contains(where: { $0.id.rawValue == outcome.targetID }) {
            if [.priceDrop, .listingClosed].contains(outcome.kind) { ListingDetailView(store: store, listingID: ListingID(outcome.targetID)) }
            else { ConversationView(store: store, listingID: ListingID(outcome.targetID)) }
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
