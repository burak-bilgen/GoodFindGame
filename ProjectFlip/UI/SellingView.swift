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
                        try store.publish(itemID: itemID, askingPrice: Money.parse(price, locale: locale))
                        published = true
                    }
                }.accessibilityIdentifier("publishListing")
            }
        }.navigationTitle("selling.create")
            .onAppear {
                if price.isEmpty, let item = store.snapshot.player.inventory.first(where: { $0.id == itemID }), let definition = store.definition(for: item) {
                    switch Result(catching: { try InspectionEngine().estimatedValue(item: item, definition: definition, marketBasisPoints: store.snapshot.marketMultiplier(for: definition)) }) {
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
                    switch Result(catching: { try TradeRecord(listing: listing) }) {
                    case .success(let record):
                        LabeledContent("trade.netProfit") { ProfitAmount(amount: record.netProfit) }
                        NavigationLink("trade.receipt") { TradeReceiptView(record: record) }
                    case .failure: Text("trade.unavailable")
                    }
                } else if let offer = listing.offers.last, [.pending, .countered].contains(offer.status) {
                    Section("buyer.title") {
                        Text(GameText.string("npc.name.\(offer.identityIndex)", locale: locale))
                        Text(offer.amount.formatted(locale: locale)).font(.title2.bold())
                        Button("buyer.accept") {
                            store.perform { try store.acceptBuyer(listingID: listing.id) }
                        }.accessibilityIdentifier("acceptBuyerOffer")
                        Button("buyer.reject") {
                            store.perform { try store.rejectBuyer(listingID: listing.id) }
                        }
                        TextField("buyer.counterAmount", text: $counterAmount).keyboardType(.decimalPad)
                        Button("buyer.sendCounter") {
                            store.perform { try store.counterBuyer(listingID: listing.id, amount: Money.parse(counterAmount, locale: locale)) }
                        }
                    }
                } else if listing.status == .active {
                    Text("selling.noOffers")
                    if let pending = store.snapshot.events.first(where: { $0.status == .pending && $0.payload.generatesBuyerInterest && $0.payload.targetID == listing.id.rawValue }) {
                        DeadlineView(store: store, target: pending.resolveAt, titleKey: "buyer.awaitingInterest")
                    }
                    Button("buyer.find") {
                        store.perform { try store.findBuyer(listingID: listing.id) }
                    }
                }
                if listing.status == .active {
                    Section("selling.asking") {
                        TextField("selling.asking", text: $newPrice).keyboardType(.decimalPad)
                        Button("selling.updatePrice") {
                            store.perform {
                                try store.changePrice(listingID: listing.id, amount: Money.parse(newPrice, locale: locale))
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
