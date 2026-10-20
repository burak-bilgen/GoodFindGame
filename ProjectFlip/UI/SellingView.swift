import SwiftUI

struct CreateListingView: View {
    let store: GameStore
    let itemID: ItemID
    @Environment(\.locale) private var locale
    @State private var price = ""
    @State private var publishedID: ListingID?
    @FocusState private var editing: Bool
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let publishedID {
                    Label("selling.live", systemImage: "checkmark.circle.fill").font(.title2.bold()).foregroundStyle(GameStyle.gain).accessibilityIdentifier("listingPublished")
                    NavigationLink { SaleListingView(store: store, listingID: publishedID) } label: { Text("selling.follow") }.buttonStyle(GameButton()).accessibilityIdentifier("followPlayerListing")
                } else if let item = store.snapshot.player.inventory.first(where: { $0.id == itemID }), let definition = store.definition(for: item) {
                    DeviceArt(symbol: definition.artSymbol, identity: definition.id).frame(height: 170)
                    Text(definition.name).font(.system(.title, design: .rounded, weight: .heavy))
                    InvestmentContext(store: store, item: item, definition: definition)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("selling.asking").font(.headline)
                        TextField("selling.asking", text: $price).keyboardType(.decimalPad).focused($editing)
                            .font(.largeTitle.bold()).textFieldStyle(.roundedBorder).accessibilityIdentifier("askingPrice")
                        Text("selling.stakes").font(.subheadline).foregroundStyle(.secondary)
                        Button("selling.publish") {
                            editing = false
                            store.perform {
                                try store.publish(itemID: itemID, askingPrice: Money.parse(price, locale: locale))
                                publishedID = store.snapshot.playerListings.last(where: { $0.itemID == itemID })?.id
                                GameFeel.play(.submitted)
                            }
                        }.buttonStyle(GameButton()).accessibilityIdentifier("publishListing")
                    }.gameCard()
                }
            }.padding(16)
        }.gameScreen().navigationTitle("selling.create").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("action.done") { editing = false } } }
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

struct InvestmentContext: View {
    let store: GameStore
    let item: ItemInstance
    let definition: ItemDefinition
    @Environment(\.locale) private var locale
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch Result(catching: { try item.purchasePrice.adding(item.inspectionCost).adding(item.repairCost) }) {
            case .success(let invested): LabeledContent("selling.invested") { Text(invested.formatted(locale: locale)).bold() }
            case .failure: Text("trade.unavailable")
            }
            switch Result(catching: { try InspectionEngine().estimatedValue(item: item, definition: definition, marketBasisPoints: store.snapshot.marketMultiplier(for: definition)) }) {
            case .success(let estimate): LabeledContent("inspection.estimatedValue") { Text(estimate.formatted(locale: locale)).bold() }
            case .failure: Text("inspection.valueUnavailable")
            }
            Text("inspection.estimateWarning").font(.caption).foregroundStyle(.secondary)
        }.gameCard()
    }
}

struct SellingView: View {
    let store: GameStore
    @Environment(\.locale) private var locale
    var body: some View {
        List {
            if store.snapshot.playerListings.isEmpty { Text("selling.empty").foregroundStyle(.secondary) }
            ForEach(store.snapshot.playerListings.reversed()) { listing in
                NavigationLink { SaleListingView(store: store, listingID: listing.id) } label: {
                    HStack(spacing: 12) {
                        if let item = store.snapshot.player.inventory.first(where: { $0.id == listing.itemID }) ?? listing.itemSnapshot, let definition = store.definition(for: item) {
                            DeviceArt(symbol: definition.artSymbol, identity: definition.id).frame(width: 80, height: 90)
                            VStack(alignment: .leading, spacing: 8) {
                                Text(definition.name).font(.headline)
                                Text(listing.askingPrice.formatted(locale: locale)).bold()
                                if listing.status == .active && listing.offers.contains(where: { [.pending, .countered].contains($0.status) }) {
                                    Label("buyer.new", systemImage: "bubble.left.fill").font(.caption.bold()).foregroundStyle(GameStyle.gain)
                                } else { Text(GameText.string("selling.\(listing.status.rawValue)", locale: locale)).font(.caption).foregroundStyle(.secondary) }
                            }
                        }
                    }
                }.accessibilityIdentifier("sale.\(listing.id.rawValue)")
            }
        }.gameScreen().navigationTitle("selling.title")
    }
}

struct SaleListingView: View {
    let store: GameStore
    let listingID: ListingID
    @Environment(\.locale) private var locale
    @GameReduceMotion private var reduceMotion
    @State private var counterAmount = ""
    @State private var newPrice = ""
    @FocusState private var editing: Bool
    var body: some View {
        if let listing = store.snapshot.playerListings.first(where: { $0.id == listingID }) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if let item = store.snapshot.player.inventory.first(where: { $0.id == listing.itemID }) ?? listing.itemSnapshot, let definition = store.definition(for: item) {
                        DeviceArt(symbol: definition.artSymbol, identity: definition.id).frame(height: listing.status == .sold ? 140 : 170)
                        Text(definition.name).font(.system(.title, design: .rounded, weight: .heavy))
                    }
                    if listing.status == .sold {
                        Label("selling.sold", systemImage: "checkmark.seal.fill").foregroundStyle(GameStyle.gain).accessibilityIdentifier("saleCompleted")
                        switch Result(catching: { try TradeRecord(listing: listing) }) {
                        case .success(let record):
                            TradePayoff(record: record, item: listing.itemSnapshot)
                            HuntButton()
                            NavigationLink("trade.receipt") { TradeReceiptView(record: record) }
                        case .failure: Text("trade.unavailable")
                        }
                    } else {
                        LabeledContent("selling.asking") { Text(listing.askingPrice.formatted(locale: locale)).font(.title2.bold()) }
                        if let offer = listing.offers.last, [.pending, .countered].contains(offer.status) {
                            VStack(alignment: .leading, spacing: 14) {
                                GameEyebrow(key: "buyer.new")
                                Label(GameText.string("npc.name.\(offer.identityIndex % 10)", locale: locale), systemImage: "person.crop.circle.fill").font(.headline)
                                Text(offer.amount.formatted(locale: locale)).font(.system(.largeTitle, design: .rounded, weight: .heavy)).contentTransition(.numericText())
                                if let message = listing.messages.last { Text(GameText.string(message.intent, locale: locale)).font(.subheadline) }
                                if let item = store.snapshot.player.inventory.first(where: { $0.id == listing.itemID }) {
                                    switch Result(catching: { try offer.amount.subtracting(item.purchasePrice).subtracting(item.inspectionCost).subtracting(item.repairCost) }) {
                                    case .success(let net): LabeledContent("buyer.net") { ProfitAmount(amount: net).bold() }
                                    case .failure: Text("trade.unavailable")
                                    }
                                }
                                if let expiry = store.snapshot.events.first(where: { event in
                                    guard event.status == .pending else { return false }
                                    if case .buyerOfferExpired(let id, let offerID) = event.payload { return id == listing.id && offerID == offer.id }
                                    return false
                                }) { DeadlineView(store: store, target: expiry.resolveAt, titleKey: "offer.expires") }
                                Button("buyer.accept") { store.perform { try store.acceptBuyer(listingID: listing.id) } }.buttonStyle(GameButton()).accessibilityIdentifier("acceptBuyerOffer")
                                DisclosureGroup("buyer.sendCounter") {
                                    VStack(spacing: 12) {
                                        TextField("buyer.counterAmount", text: $counterAmount).keyboardType(.decimalPad).focused($editing).textFieldStyle(.roundedBorder).accessibilityIdentifier("buyerCounterAmount")
                                        Button("buyer.sendCounter") {
                                            editing = false
                                            store.perform {
                                                try store.counterBuyer(listingID: listing.id, amount: Money.parse(counterAmount, locale: locale))
                                                GameFeel.play(.submitted)
                                            }
                                        }.buttonStyle(.bordered).accessibilityIdentifier("sendBuyerCounter")
                                    }.padding(.top, 10)
                                }
                                Button("buyer.reject", role: .destructive) { store.perform { try store.rejectBuyer(listingID: listing.id) } }
                            }.gameCard()
                        } else if listing.status == .active {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("selling.noOffers").font(.headline)
                                if let last = listing.messages.last, ["buyer.withdraw", "buyer.expired"].contains(last.intent) {
                                    Text(GameText.string(last.intent, locale: locale)).font(.subheadline).foregroundStyle(.secondary)
                                }
                                if let pending = store.snapshot.events.first(where: { $0.status == .pending && $0.payload.generatesBuyerInterest && $0.payload.targetID == listing.id.rawValue }) {
                                    DeadlineView(store: store, target: pending.resolveAt, titleKey: "buyer.awaitingInterest")
                                }
                                Button("buyer.find") { store.perform { try store.findBuyer(listingID: listing.id) } }
                            }.gameCard()
                        }
                        DisclosureGroup("buyer.activity") {
                            VStack(alignment: .leading, spacing: 12) {
                                LabeledContent("selling.views") { Text(listing.views, format: .number) }
                                LabeledContent("selling.favorites") { Text(listing.favorites, format: .number) }
                                ForEach(listing.messages) { DialogueBubble(message: $0) }
                            }.padding(.top, 12)
                        }.gameCard()
                        if listing.status == .active {
                            DisclosureGroup("selling.updatePrice") {
                                VStack(spacing: 12) {
                                    TextField("selling.asking", text: $newPrice).keyboardType(.decimalPad).focused($editing).textFieldStyle(.roundedBorder)
                                    Button("selling.updatePrice") { store.perform { try store.changePrice(listingID: listing.id, amount: Money.parse(newPrice, locale: locale)) } }
                                }.padding(.top, 12)
                            }.gameCard()
                        }
                    }
                }.padding(16)
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.25), value: listing.status)
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: listing.messages.count)
            }.gameScreen().navigationTitle("selling.title").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("action.done") { editing = false } } }
                .onAppear { if newPrice.isEmpty { newPrice = listing.askingPrice.inputText(locale: locale); counterAmount = newPrice } }
                .onChange(of: listing.messages.last?.id) { _, _ in
                    if let last = listing.messages.last, ["buyer.counter", "buyer.withdraw", "buyer.expired"].contains(last.intent) { GameFeel.play(.reply) }
                }
                .onChange(of: listing.status) { _, status in
                    if status == .sold {
                        switch Result(catching: { try TradeRecord(listing: listing) }) {
                        case .success(let record): GameFeel.play(record.netProfit >= .zero ? .profit : .loss)
                        case .failure: break // The unavailable-result message remains visible in the view.
                        }
                    }
                }
        }
    }
}

struct TradePayoff: View {
    let record: TradeRecord
    var item: ItemInstance?
    @Environment(\.locale) private var locale
    private var lessonKey: String {
        if record.netProfit > .zero { return "result.lesson.win" }
        if record.netProfit == .zero { return "result.lesson.even" }
        if record.soldFor >= record.acquiredFor { return "result.lesson.costs" }
        return item?.activeDefects.isEmpty == false ? "result.lesson.fault" : "result.lesson.price"
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GameEyebrow(key: record.netProfit > .zero ? "result.win" : record.netProfit < .zero ? "result.loss" : "result.even")
            Text(record.netProfit.formatted(locale: locale, signed: true)).font(.system(.largeTitle, design: .rounded, weight: .heavy))
                .foregroundStyle(record.netProfit < .zero ? GameStyle.loss : GameStyle.gain).contentTransition(.numericText()).accessibilityIdentifier("tradePayoff")
            if record.inspectionCost > .zero || record.repairCost > .zero {
                Text("result.afterCosts").font(.caption).foregroundStyle(.secondary)
            }
            Text(GameText.format("result.route", locale: locale, record.acquiredFor.formatted(locale: locale), record.soldFor.formatted(locale: locale))).font(.subheadline)
            if record.totalCost > .zero {
                LabeledContent("result.roi") {
                    Text((Decimal(record.netProfit.minorUnits) / Decimal(record.totalCost.minorUnits)).formatted(.percent.precision(.fractionLength(1)).locale(locale))).bold()
                }.font(.subheadline)
            }
            Text(GameText.string(lessonKey, locale: locale))
                .font(.subheadline).foregroundStyle(.secondary)
            if record.netProfit < .zero, let item {
                ForEach(item.activeDefects, id: \.self) { defect in Text(GameText.string(defect.key, locale: locale)).font(.caption.bold()).foregroundStyle(GameStyle.loss) }
            }
        }.gameCard()
    }
}
