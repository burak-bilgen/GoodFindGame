import SwiftUI

struct CreateListingView: View {
    let store: GameStore
    let itemID: ItemID
    @Environment(\.locale) private var locale
    @State private var price = ""
    @State private var published = false
    var body: some View {
        Form {
            if published {
                Label("selling.live", systemImage: "checkmark.circle.fill").accessibilityIdentifier("listingPublished")
            } else {
                TextField("selling.asking", text: $price).keyboardType(.decimalPad).accessibilityIdentifier("askingPrice")
                Text("selling.priceHint").font(.caption).foregroundStyle(.secondary)
                Button("selling.publish") {
                    store.perform {
                        try store.commit(ResaleEngine().create(itemID: itemID, askingPrice: Money.parse(price, locale: locale), state: store.snapshot, definitions: store.definitions, now: .now))
                        published = true
                    }
                }.accessibilityIdentifier("publishListing")
            }
        }.navigationTitle("selling.create")
            .onAppear {
                if price.isEmpty, let item = store.snapshot.player.inventory.first(where: { $0.id == itemID }), let definition = store.definition(for: item) {
                    switch Result(catching: { try InspectionEngine().estimatedValue(item: item, definition: definition) }) {
                    case .success(let estimate): price = estimate.inputText(locale: locale)
                    case .failure: store.errorKey = "inspection.valueUnavailable"
                    }
                }
            }
    }
}

struct SellingView: View {
    let store: GameStore
    @Environment(\.locale) private var locale
    var body: some View {
        List {
            if store.snapshot.playerListings.isEmpty { Text("selling.empty").foregroundStyle(.secondary) }
            ForEach(store.snapshot.playerListings) { listing in
                NavigationLink {
                    SaleListingView(store: store, listingID: listing.id)
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        if let item = store.snapshot.player.inventory.first(where: { $0.id == listing.itemID }), let definition = store.definition(for: item) { Text(definition.name).font(.headline) }
                        Text(listing.askingPrice.formatted(locale: locale))
                        Text(GameText.string("selling.\(listing.status.rawValue)", locale: locale)).font(.caption)
                    }
                }.accessibilityIdentifier("sale.\(listing.id.rawValue)")
            }
        }.navigationTitle("selling.title")
    }
}

struct SaleListingView: View {
    let store: GameStore
    let listingID: ListingID
    @Environment(\.locale) private var locale
    var body: some View {
        if let listing = store.snapshot.playerListings.first(where: { $0.id == listingID }) {
            List {
                LabeledContent("selling.asking") { Text(listing.askingPrice.formatted(locale: locale)) }
                LabeledContent("selling.views") { Text(listing.views, format: .number) }
                LabeledContent("selling.favorites") { Text(listing.favorites, format: .number) }
                Text("selling.noOffers")
            }.navigationTitle("selling.title")
        }
    }
}
