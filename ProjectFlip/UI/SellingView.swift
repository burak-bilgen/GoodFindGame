import SwiftUI

struct CreateListingView: View {
    let store: GameStore
    let itemID: ItemID
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market
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
                    HStack(spacing: 14) {
                        DeviceArt(symbol: definition.artSymbol, identity: definition.id, appearance: .owned(item)).frame(width: 96, height: 96)
                        VStack(alignment: .leading, spacing: 8) {
                            GameEyebrow(key: "game.sellingStage")
                            Text(definition.displayName(locale: locale)).font(.system(.title2, design: .rounded, weight: .heavy))
                        }
                    }
                    InvestmentContext(store: store, item: item, definition: definition)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("selling.asking").font(.headline)
                        TextField("selling.asking", text: $price).keyboardType(.decimalPad).focused($editing)
                            .font(.system(.largeTitle, design: .rounded, weight: .black)).textFieldStyle(.plain)
                            .padding(14).background(GameStyle.gain.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(GameStyle.gain.opacity(0.4), lineWidth: 1))
                            .accessibilityIdentifier("askingPrice")
                        AskingResultView(item: item, askingPrice: price)
                        PriceSuggestions(store: store, item: item, definition: definition, price: $price)
                        Text("game.price.hint").font(.caption).foregroundStyle(.secondary)
                        Button("selling.publish") {
                            editing = false
                            store.perform {
                                try store.publish(itemID: itemID, askingPrice: Money.parse(price, locale: locale, market: market))
                                publishedID = store.snapshot.playerListings.last(where: { $0.itemID == itemID })?.id
                                GameFeel.play(.submitted)
                            }
                        }.buttonStyle(GameButton()).accessibilityIdentifier("publishListing")
                    }.gameCard()
                }
            }.padding(16)
        }.gameScreen().navigationTitle("selling.create").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { if editing { Button("action.done") { editing = false } } } }
            .onAppear {
                if price.isEmpty, let item = store.snapshot.player.inventory.first(where: { $0.id == itemID }), let definition = store.definition(for: item) {
                    switch Result(catching: { try ValueEstimate(item: item, definition: definition, knowledge: store.snapshot.inspectionKnowledge, marketBasisPoints: store.snapshot.marketMultiplier(for: definition)) }) {
                    case .success(let estimate): price = estimate.midpoint.inputText(locale: locale, market: market)
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
    @Environment(\.marketConfiguration) private var market
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch Result(catching: { try item.purchasePrice.adding(item.inspectionCost).adding(item.repairCost) }) {
            case .success(let invested): LabeledContent("selling.invested") { Text(invested.formatted(locale: locale, market: market)).bold().foregroundStyle(.primary) }
            case .failure: Text("trade.unavailable")
            }
            switch Result(catching: { try ValueEstimate(item: item, definition: definition, knowledge: store.snapshot.inspectionKnowledge, marketBasisPoints: store.snapshot.marketMultiplier(for: definition)) }) {
            case .success(let estimate):
                Text("living.estimateRange").font(.caption).foregroundStyle(.secondary)
                ValueRangeView(estimate: estimate)
            case .failure: Text("inspection.valueUnavailable")
            }
            Text("inspection.estimateWarning").font(.caption).foregroundStyle(.secondary)
            MarketAudienceView(store: store, definition: definition)

        }.gameCard()
    }
}

struct SellingView: View {
    let store: GameStore
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                if store.snapshot.playerListings.isEmpty { Text("selling.empty").foregroundStyle(.secondary) }
                ForEach(store.snapshot.playerListings.reversed()) { listing in
                    NavigationLink { SaleListingView(store: store, listingID: listing.id) } label: {
                        HStack(spacing: 12) {
                            if let item = store.snapshot.player.inventory.first(where: { $0.id == listing.itemID }) ?? listing.itemSnapshot, let definition = store.definition(for: item) {
                                DeviceArt(symbol: definition.artSymbol, identity: definition.id, appearance: .owned(item)).frame(width: 80, height: 80)
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(definition.displayName(locale: locale)).font(.headline)
                                    Text(listing.askingPrice.formatted(locale: locale, market: market)).bold()
                                    if listing.status == .active && listing.offers.contains(where: { [.pending, .countered].contains($0.status) }) {
                                        Label("buyer.new", systemImage: "bubble.left.fill").font(.caption.bold()).foregroundStyle(GameStyle.gain)
                                    } else { Text(GameText.string("selling.\(listing.status.rawValue)", locale: locale)).font(.caption).foregroundStyle(.secondary) }
                                }
                            }
                        }.frame(maxWidth: .infinity, alignment: .leading).gameCard()
                    }.buttonStyle(.plain).accessibilityIdentifier("sale.\(listing.id.rawValue)")
                }
            }.padding(16)
        }.gameScreen().navigationTitle("selling.title")
    }
}

struct SaleListingView: View {
    let store: GameStore
    let listingID: ListingID
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market
    @Environment(\.dynamicTypeSize) private var typeSize
    @GameReduceMotion private var reduceMotion
    @State private var counterAmount = ""
    @State private var counterComposerExpanded = false
    @State private var newPrice = ""
    @FocusState private var editing: Bool
    var body: some View {
        if let listing = store.snapshot.playerListings.first(where: { $0.id == listingID }) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Color.clear.frame(height: 1).id("saleTop").accessibilityHidden(true)
                        if listing.status != .sold, let item = store.snapshot.player.inventory.first(where: { $0.id == listing.itemID }) ?? listing.itemSnapshot, let definition = store.definition(for: item) {
                            HStack(spacing: 14) {
                                DeviceArt(symbol: definition.artSymbol, identity: definition.id, appearance: .owned(item)).frame(width: 80, height: 80)
                                Text(definition.displayName(locale: locale)).font(.system(.title2, design: .rounded, weight: .heavy))
                            }
                        }
                        if listing.status == .sold {
                            Label("selling.sold", systemImage: "checkmark.seal.fill").foregroundStyle(GameStyle.gain).accessibilityIdentifier("saleCompleted")
                            switch Result(catching: { try TradeRecord(listing: listing) }) {
                            case .success(let record):
                                TradePayoff(record: record, item: listing.itemSnapshot).id("saleOutcome")
                                HuntButton()
                                CareerHuntPrompt(store: store)
                                NavigationLink("trade.receipt") { TradeReceiptView(record: record, item: listing.itemSnapshot) }
                            case .failure: Text("trade.unavailable")
                            }
                        } else {
                            LabeledContent("selling.asking") { Text(listing.askingPrice.formatted(locale: locale, market: market)).font(.title2.bold()) }
                            HStack {
                                Label(listing.views.formatted(.number.locale(locale)), systemImage: "eye")
                                Text("selling.views").font(.caption)
                                Spacer()
                                Label(listing.favorites.formatted(.number.locale(locale)), systemImage: "heart")
                                Text("selling.favorites").font(.caption)
                            }.font(.subheadline).accessibilityIdentifier("listingAttention")
                            if listing.views == 0 && listing.status == .active { Text("living.justListed").font(.caption).foregroundStyle(.secondary) }
                            let awaitingReply = store.snapshot.hasBuyerReply(for: listing.id)
                            if let offer = listing.offers.last, [.pending, .countered].contains(offer.status) {
                                VStack(alignment: .leading, spacing: 14) {
                                    GameStamp(key: awaitingReply ? "living.replyPending" : offer.status == .countered ? "buyer.counterHeading" : "buyer.new", symbol: awaitingReply ? "clock" : offer.status == .countered ? "arrow.left.arrow.right" : "bolt.fill").id("buyerDecision")
                                    if awaitingReply {
                                        Text("living.buyerConsidering").font(.caption).foregroundStyle(.secondary)
                                        HuntButton()
                                    }
                                    HStack(spacing: 10) {
                                        TraderPortrait(identity: offer.identityIndex)
                                        Text(GameText.marketPerson("name", index: offer.identityIndex, market: market, locale: locale)).font(.headline)
                                    }
                                    GameEyebrow(key: awaitingReply ? "living.previousOffer" : "buyer.offeredPrice")
                                    Text(offer.amount.formatted(locale: locale, market: market)).accessibilityIdentifier("buyerOfferAmount").font(.system(.largeTitle, design: .rounded, weight: .heavy)).contentTransition(.numericText())
                                    if let message = listing.messages.last { Text(GameText.string(message.intent, locale: locale)).font(.subheadline) }
                                    if let item = store.snapshot.player.inventory.first(where: { $0.id == listing.itemID }) {
                                        switch Result(catching: { try offer.amount.subtracting(item.purchasePrice).subtracting(item.inspectionCost).subtracting(item.repairCost) }) {
                                        case .success(let net):
                                            if typeSize.isAccessibilitySize {
                                                VStack(alignment: .leading, spacing: 8) {
                                                    Text("buyer.net")
                                                    ProfitAmount(amount: net).bold().lineLimit(1).minimumScaleFactor(0.5)
                                                }
                                            } else {
                                                LabeledContent("buyer.net") { ProfitAmount(amount: net).bold() }
                                            }
                                        case .failure: Text("trade.unavailable")
                                        }
                                    }
                                    if let expiry = store.snapshot.events.first(where: { event in
                                        guard event.status == .pending else { return false }
                                        if case .buyerOfferExpired(let id, let offerID) = event.payload { return id == listing.id && offerID == offer.id }
                                        return false
                                    }) { DeadlineView(store: store, target: expiry.resolveAt, titleKey: "offer.expires") }
                                    Button("buyer.accept") { store.perform { try store.acceptBuyer(listingID: listing.id) } }.buttonStyle(GameButton()).disabled(awaitingReply).accessibilityIdentifier("acceptBuyerOffer")
                                    Text(offer.status == .countered ? "buyer.pushAgainRisk" : "buyer.pushRisk")
                                        .font(.caption).foregroundStyle(.secondary)
                                    DisclosureGroup("buyer.sendCounter", isExpanded: $counterComposerExpanded) {
                                        VStack(alignment: .leading, spacing: 12) {
                                            Text("buyer.counterAmount").font(.subheadline.weight(.semibold))
                                            TextField("buyer.counterAmount", text: $counterAmount).keyboardType(.decimalPad).focused($editing)
                                                .font(.system(.title2, design: .rounded, weight: .bold)).textFieldStyle(.plain)
                                                .padding(12).background(GameStyle.gain.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                                                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(GameStyle.gain.opacity(0.35), lineWidth: 1))
                                                .accessibilityIdentifier("buyerCounterAmount")
                                            Text("buyer.counterCommitment").font(.caption).foregroundStyle(.secondary)
                                            Button("buyer.sendCounter") {
                                                editing = false
                                                store.perform {
                                                    try store.counterBuyer(listingID: listing.id, amount: Money.parse(counterAmount, locale: locale, market: market))
                                                    counterComposerExpanded = false
                                                    GameFeel.play(.submitted)
                                                }
                                            }.buttonStyle(GameButton(secondary: true)).accessibilityIdentifier("sendBuyerCounter")
                                        }.padding(.top, 10)
                                    }.disabled(awaitingReply)
                                    Button("buyer.reject", role: .destructive) { store.perform { try store.rejectBuyer(listingID: listing.id) } }.disabled(awaitingReply).accessibilityIdentifier("rejectBuyerOffer")
                                }.gameCard(accent: GameStyle.gain)
                            } else if listing.status == .active {
                                VStack(alignment: .leading, spacing: 12) {
                                    GameStamp(key: "selling.live", symbol: "antenna.radiowaves.left.and.right")
                                    Text("selling.noOffers").font(.headline)
                                    if let last = listing.messages.last, ["buyer.withdraw", "buyer.expired"].contains(last.intent) {
                                        Text(GameText.string(last.intent, locale: locale)).font(.subheadline).foregroundStyle(.secondary)
                                    }
                                    if store.snapshot.events.contains(where: { $0.status == .pending && $0.payload.generatesBuyerInterest && $0.payload.targetID == listing.id.rawValue }) {
                                        Text("living.interestUncertain").font(.subheadline).foregroundStyle(.secondary)
                                    } else {
                                        Button("buyer.find") { store.perform { try store.findBuyer(listingID: listing.id) } }
                                            .buttonStyle(GameButton(secondary: true)).accessibilityIdentifier("findAnotherBuyer")
                                    }
                                    Text("selling.keepHunting").font(.subheadline).foregroundStyle(.secondary)
                                    HuntButton()
                                }.gameCard()
                            }
                            if listing.status == .expired || listing.status == .cancelled {
                                Text(GameText.string("selling.\(listing.status.rawValue)", locale: locale)).font(.headline)
                                NavigationLink { CreateListingView(store: store, itemID: listing.itemID) } label: { Text("living.relist") }.buttonStyle(GameButton()).accessibilityIdentifier("relistItem")
                            }
                            DisclosureGroup("buyer.activity") {
                                VStack(alignment: .leading, spacing: 12) {
                                    if let end = listing.expiresAt, listing.status == .active { DeadlineView(store: store, target: end, titleKey: "living.listingEnds") }
                                    LabeledContent("selling.views") { Text(listing.views, format: .number) }
                                    LabeledContent("selling.favorites") { Text(listing.favorites, format: .number) }
                                    ForEach(listing.messages) { DialogueBubble(message: $0) }
                                }.padding(.top, 12)
                            }.gameCard()
                            if listing.status == .active {
                                DisclosureGroup("selling.updatePrice") {
                                    VStack(spacing: 12) {
                                        TextField("selling.asking", text: $newPrice).keyboardType(.decimalPad).focused($editing).textFieldStyle(GamePriceFieldStyle()).accessibilityIdentifier("salePrice")
                                            .task {
                                                await Task.yield()
                                                proxy.scrollTo("salePriceEditor", anchor: .center)
                                            }
                                        Button("selling.updatePrice") {
                                            editing = false
                                            store.perform { try store.changePrice(listingID: listing.id, amount: Money.parse(newPrice, locale: locale, market: market)) }
                                        }.accessibilityIdentifier("updateSalePrice")
                                    }.padding(.top, 12).id("salePriceEditor")
                                }.gameCard()
                                Button("living.withdraw", role: .destructive) { store.perform { try store.withdrawListing(listingID: listing.id) } }.accessibilityIdentifier("withdrawListing")
                            }
                        }
                    }.padding(16)
                        .animation(reduceMotion ? nil : .easeOut(duration: 0.25), value: listing.status)
                        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: listing.messages.count)
                }.gameScreen().navigationTitle("selling.title").navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .topBarTrailing) { if editing { Button("action.done") { editing = false } } } }
                    .onAppear { if newPrice.isEmpty { newPrice = listing.askingPrice.inputText(locale: locale, market: market); counterAmount = newPrice } }
                    .onChange(of: listing.messages.last?.id) { _, _ in
                        counterComposerExpanded = false
                        if ["buyer.counter", "buyer.hold"].contains(listing.messages.last?.intent ?? "") {
                            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) { proxy.scrollTo("buyerDecision", anchor: .top) }
                        }
                        if let last = listing.messages.last, ["buyer.counter", "buyer.hold", "buyer.withdraw", "buyer.expired"].contains(last.intent) { GameFeel.play(.reply) }
                    }
                    .onChange(of: listing.status) { _, status in
                        if status == .sold {
                            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) { proxy.scrollTo("saleTop", anchor: .top) }
                            switch Result(catching: { try TradeRecord(listing: listing) }) {
                            case .success(let record): GameFeel.play(record.netProfit >= .zero ? .profit : .loss)
                            case .failure: break // The unavailable-result message remains visible in the view.
                            }
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
    @Environment(\.marketConfiguration) private var market
    @Environment(\.dynamicTypeSize) private var typeSize
    @GameReduceMotion private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var payoffSize = 46
    @State private var appeared = false
    private var outcome: TradeOutcomePresentation { TradeOutcomePresentation(record: record, item: item) }
    @ViewBuilder private var objectHero: some View {
        if let item, let definition = try? SeedContent.load().items.first(where: { $0.id == item.definitionID }) {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        DeviceArt(symbol: definition.artSymbol, identity: definition.id, appearance: .owned(item)).frame(width: 90, height: 90)
                        Spacer(minLength: 0)
                        DealSeal(successful: record.netProfit >= .zero)
                    }
                    Text(definition.displayName(locale: locale)).font(.headline).fixedSize(horizontal: false, vertical: true)
                }
            } else {
                HStack(spacing: 14) {
                    DeviceArt(symbol: definition.artSymbol, identity: definition.id, appearance: .owned(item)).frame(width: 90, height: 90)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(definition.displayName(locale: locale)).font(.headline).fixedSize(horizontal: false, vertical: true)
                        Label("selling.sold", systemImage: "tag.fill").font(.caption.bold()).foregroundStyle(GameStyle.amber)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    DealSeal(successful: record.netProfit >= .zero)
                }
            }
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !typeSize.isAccessibilitySize { objectHero }
            HStack(spacing: 12) {
                Image(systemName: record.netProfit > .zero ? "trophy.fill" : record.netProfit < .zero ? "arrow.uturn.down.circle.fill" : "equal.circle.fill")
                    .font(.system(size: 30, weight: .bold)).foregroundStyle(GameStyle.amber)
                    .padding(14).background(GameStyle.amber.opacity(0.12), in: Circle()).accessibilityHidden(true)
                Text(GameText.string(record.netProfit > .zero ? "result.win" : record.netProfit < .zero ? "result.loss" : "result.even", locale: locale))
                    .font(.system(.title2, design: .rounded, weight: .black)).foregroundStyle(.white)
            }
            if record.kind == .consignment { Text("recovery.receipt").font(.subheadline).foregroundStyle(GameStyle.amber) }
            if record.kind == .liquidation { Text("recovery.liquidationReceipt").font(.subheadline).foregroundStyle(GameStyle.amber) }
            Text(record.netProfit.formatted(locale: locale, market: market, signed: true, precise: true)).font(.system(size: payoffSize, weight: .black, design: .rounded))
                .lineLimit(1).minimumScaleFactor(0.45)
                .foregroundStyle(record.netProfit < .zero ? Color(red: 1, green: 0.57, blue: 0.53) : GameStyle.light(.gaming))
                .contentTransition(.numericText()).accessibilityIdentifier("tradePayoff")
                .offset(y: appeared || reduceMotion ? 0 : 8).opacity(appeared || reduceMotion ? 1 : 0)
            if typeSize.isAccessibilitySize { objectHero }
            if record.inspectionCost > .zero || record.repairCost > .zero {
                Text("result.afterCosts").font(.caption).foregroundStyle(.white.opacity(0.74))
            }
            Text(GameText.format("result.route", locale: locale, record.acquiredFor.formatted(locale: locale, market: market, precise: true), record.soldFor.formatted(locale: locale, market: market, precise: true))).font(.subheadline)
            if record.totalCost > .zero {
                LabeledContent("result.roi") {
                    Text((Decimal(record.netProfit.minorUnits) / Decimal(record.totalCost.minorUnits)).formatted(.percent.precision(.fractionLength(1)).locale(locale))).bold()
                }.font(.subheadline)
            }
            Text(GameText.string(outcome.lessonKey, locale: locale))
                .accessibilityIdentifier("tradeLesson")
                .font(.subheadline).foregroundStyle(.white.opacity(0.74))
            if record.netProfit < .zero && !outcome.defects.isEmpty {
                Text("result.knownIssues").font(.caption.weight(.semibold)).foregroundStyle(.white.opacity(0.74))
                ForEach(outcome.defects, id: \.self) { defect in
                    Text(GameText.string(defect.key, locale: locale)).font(.caption.bold())
                        .foregroundStyle(Color(red: 1, green: 0.57, blue: 0.53)).accessibilityIdentifier("tradeDefect.\(defect.rawValue)")
                }
            }
        }
        .padding(22).frame(maxWidth: .infinity, alignment: .leading).foregroundStyle(.white)
        .background(LinearGradient(colors: [GameStyle.panelTop, GameStyle.ink], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 26))
        .overlay(RoundedRectangle(cornerRadius: 26).strokeBorder(GameStyle.amber.opacity(0.35), lineWidth: 1))
        .overlay { if record.netProfit > .zero { GamePayoffBurst() } }
        .onAppear { withAnimation(reduceMotion ? nil : .easeOut(duration: 0.4)) { appeared = true } }
    }
}

/// Public estimates suggest a range of bets, never an exact optimal sale price.
private struct PriceSuggestions: View {
    let store: GameStore
    let item: ItemInstance
    let definition: ItemDefinition
    @Binding var price: String
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        switch Result(catching: { try ValueEstimate(item: item, definition: definition, knowledge: store.snapshot.inspectionKnowledge, marketBasisPoints: store.snapshot.marketMultiplier(for: definition)) }) {
        case .success(let estimate):
            if typeSize.isAccessibilitySize {
                VStack(spacing: 8) { choices(estimate) }
            } else {
                HStack(alignment: .top, spacing: 8) { choices(estimate) }
            }
        case .failure: EmptyView() // The adjacent investment panel reports unavailable estimates.
        }
    }
    @ViewBuilder private func choices(_ estimate: ValueEstimate) -> some View {
        ForEach(0..<3) { index in
            let suggested = [estimate.lower, estimate.midpoint, estimate.upper][index]
            Group {
                Button {
                    price = suggested.inputText(locale: locale, market: market)
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: ["hare", "scope", "hourglass"][index]).font(.title3)
                        Text(GameText.string(["game.price.fast", "game.price.balanced", "game.price.patient"][index], locale: locale)).font(.caption2.bold())
                        Text(suggested.formatted(locale: locale, market: market)).font(.caption.bold()).lineLimit(1).minimumScaleFactor(0.5)
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(10)
                        .background(GameStyle.gain.opacity(price == suggested.inputText(locale: locale, market: market) ? 0.18 : 0.06), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(GameStyle.gain.opacity(price == suggested.inputText(locale: locale, market: market) ? 0.65 : 0.12), lineWidth: 1))
                }.buttonStyle(.plain).foregroundStyle(GameStyle.gain).accessibilityIdentifier("priceSuggestion.\(index)")
            }
        }
    }
}
