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
                        var next = try ResaleEngine().create(itemID: itemID, askingPrice: Money.parse(price, locale: locale), state: store.snapshot, definitions: store.definitions, now: .now)
                        guard let listing = next.playerListings.last else { throw TradingError.unavailable }
                        next = try BuyerEngine().generateOffer(listingID: listing.id, state: next, definitions: store.definitions)
                        try store.commit(next)
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
                        if let item = store.snapshot.player.inventory.first(where: { $0.id == listing.itemID }) ?? listing.itemSnapshot, let definition = store.definition(for: item) { Text(definition.name).font(.headline) }
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
    @State private var counterAmount = ""
    @State private var newPrice = ""
    var body: some View {
        if let listing = store.snapshot.playerListings.first(where: { $0.id == listingID }) {
            List {
                LabeledContent("selling.asking") { Text(listing.askingPrice.formatted(locale: locale)) }
                LabeledContent("selling.views") { Text(listing.views, format: .number) }
                LabeledContent("selling.favorites") { Text(listing.favorites, format: .number) }
                ForEach(listing.messages) { message in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(GameText.string(message.intent, locale: locale))
                        if let amount = message.amount { Text(amount.formatted(locale: locale)).bold() }
                    }
                }
                if listing.status == .sold {
                    Label("selling.sold", systemImage: "checkmark.seal.fill").accessibilityIdentifier("saleCompleted")
                } else if let offer = listing.offers.last, [.pending, .countered].contains(offer.status) {
                    Section("buyer.title") {
                        Text(GameText.string("npc.name.\(offer.identityIndex)", locale: locale))
                        Text(offer.amount.formatted(locale: locale)).font(.title2.bold())
                        Button("buyer.accept") {
                            store.perform { try store.commit(BuyerEngine().accept(listingID: listing.id, state: store.snapshot, now: .now)) }
                        }.accessibilityIdentifier("acceptBuyerOffer")
                        Button("buyer.reject") {
                            store.perform { try store.commit(BuyerEngine().reject(listingID: listing.id, state: store.snapshot)) }
                        }
                        TextField("buyer.counterAmount", text: $counterAmount).keyboardType(.decimalPad)
                        Button("buyer.sendCounter") {
                            store.perform { try store.commit(BuyerEngine().counter(listingID: listing.id, amount: Money.parse(counterAmount, locale: locale), state: store.snapshot, now: .now)) }
                        }
                    }
                } else if listing.status == .active {
                    Text("selling.noOffers")
                    Button("buyer.find") {
                        store.perform { try store.commit(BuyerEngine().generateOffer(listingID: listing.id, state: store.snapshot, definitions: store.definitions)) }
                    }
                }
                if listing.status == .active {
                    Section("selling.asking") {
                        TextField("selling.asking", text: $newPrice).keyboardType(.decimalPad)
                        Button("selling.updatePrice") {
                            store.perform {
                                var next = try BuyerEngine().changePrice(listingID: listing.id, amount: Money.parse(newPrice, locale: locale), state: store.snapshot)
                                next = try BuyerEngine().generateOffer(listingID: listing.id, state: next, definitions: store.definitions)
                                try store.commit(next)
                            }
                        }
                    }
                }
            }.navigationTitle("selling.title")
                .onAppear { if newPrice.isEmpty { newPrice = listing.askingPrice.inputText(locale: locale); counterAmount = newPrice } }
                .sensoryFeedback(.success, trigger: listing.status == .sold)
        }
    }
}
