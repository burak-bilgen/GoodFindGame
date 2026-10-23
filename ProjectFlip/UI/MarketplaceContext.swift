import SwiftUI

struct ValueRangeView: View {
    let estimate: ValueEstimate
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 6) {
                Text(estimate.lower.formatted(locale: locale, market: market)).fixedSize()
                Text(verbatim: "–")
                Text(estimate.upper.formatted(locale: locale, market: market)).fixedSize()
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(estimate.lower.formatted(locale: locale, market: market)).fixedSize()
                Text(verbatim: "–")
                Text(estimate.upper.formatted(locale: locale, market: market)).fixedSize()
            }
        }.font(.system(.title3, design: .rounded, weight: .bold)).monospacedDigit()
            .accessibilityElement(children: .ignore).accessibilityLabel(Text(estimate.formatted(locale: locale, market: market)))
    }
}

struct MarketAudienceView: View {
    let store: GameStore
    let definition: ItemDefinition
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market
    var body: some View {
        let demand = try? store.snapshot.marketCalendar?.multiplier(for: definition, at: store.snapshot.lastSimulationAt ?? .now) ?? 10_000
        VStack(alignment: .leading, spacing: 6) {
            if let demand {
                Label(GameText.string(demand > 10_000 ? "living.demandRising" : demand < 10_000 ? "living.demandCooling" : "living.demandSteady", locale: locale), systemImage: "chart.line.uptrend.xyaxis")
            } else { Text("inspection.valueUnavailable") }
            Text(GameText.string("living.audience.\(definition.category.rawValue)", locale: locale)).font(.caption).foregroundStyle(.secondary)
        }
    }
}

/// Counts actual pending work; no forecast offers or hidden liquidity score reach the player.
struct OpenTradesView: View {
    let store: GameStore
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market
    var body: some View {
        let sellers = store.snapshot.conversations.filter { !$0.closed && $0.pendingReplyEventID != nil }
        let readySellers = store.snapshot.conversations.filter { !$0.closed && $0.pendingReplyEventID == nil && ($0.counterPrice != nil || $0.agreedPrice != nil) }
        let idleStock = store.snapshot.player.inventory.filter { ItemTransfer.available($0.id, state: store.snapshot) }
        let readyToInspect = idleStock.filter { !$0.inspected }
        let readyToPrice = idleStock.filter(\.inspected)
        let shipping = store.snapshot.shipments.filter { $0.status == .pending }
        let inspections = store.snapshot.inspectionJobs.filter { $0.status == .pending }
        let sales = store.snapshot.playerListings.filter { $0.status == .active }
        if !sellers.isEmpty || !readySellers.isEmpty || !shipping.isEmpty || !inspections.isEmpty || !sales.isEmpty || !idleStock.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    GameActivityLights()
                    Text("living.inMotion").font(.caption.bold()).foregroundStyle(GameStyle.gain)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                if let seller = readySellers.first {
                    NavigationLink { ConversationView(store: store, listingID: seller.listingID) } label: {
                        Label(GameText.format("living.sellerReady", locale: locale, readySellers.count), systemImage: "bubble.left.and.bubble.right.fill")
                    }
                }
                if let item = readyToInspect.first {
                    NavigationLink { OwnedItemView(store: store, itemID: item.id) } label: {
                        Label(GameText.format("living.inspectReady", locale: locale, readyToInspect.count), systemImage: "viewfinder")
                    }
                }
                if let item = readyToPrice.first {
                    NavigationLink { OwnedItemView(store: store, itemID: item.id) } label: {
                        Label(GameText.format("living.priceReady", locale: locale, readyToPrice.count), systemImage: "tag.fill")
                    }
                }
                if let seller = sellers.first {
                    NavigationLink { ConversationView(store: store, listingID: seller.listingID) } label: {
                        Label(GameText.format("living.sellers", locale: locale, Int64(sellers.count)), systemImage: "bubble.left.and.bubble.right")
                    }
                }
                if !shipping.isEmpty {
                    NavigationLink { InventoryView(store: store) } label: {
                        Label(GameText.format("living.shipping", locale: locale, Int64(shipping.count)), systemImage: "shippingbox")
                    }
                }
                if let inspection = inspections.first {
                    NavigationLink { OwnedItemView(store: store, itemID: inspection.itemID) } label: {
                        Label(GameText.format("living.inspections", locale: locale, Int64(inspections.count)), systemImage: "viewfinder")
                    }
                }
                if !sales.isEmpty {
                    NavigationLink { SellingView(store: store) } label: {
                        Label(GameText.format("living.sales", locale: locale, Int64(sales.count)), systemImage: "tag")
                    }
                }
                    }
                }
            }.font(.caption).padding(.vertical, 4).accessibilityIdentifier("openTrades")
        }
    }
}

struct AskingResultView: View {
    let item: ItemInstance
    let askingPrice: String
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market
    var body: some View {
        if let ask = try? Money.parse(askingPrice, locale: locale, market: market), let total = try? item.purchasePrice.adding(item.inspectionCost).adding(item.repairCost), let result = try? ask.subtracting(total) {
            VStack(alignment: .leading, spacing: 4) {
                Text("living.ifSoldAtAsk").font(.caption).foregroundStyle(.secondary)
                ProfitAmount(amount: result).bold()
            }.accessibilityHint(Text("living.notGuaranteed"))
        }
    }
}

/// The bet is readable before committing cash; the range remains an estimate.
struct TradeReadView: View {
    let store: GameStore
    let listing: MarketplaceListing
    let price: Money
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market
    var body: some View {
        if let definition = store.definition(for: listing.item) {
            let disclosed = store.snapshot.conversations.first { $0.listingID == listing.id }?.knownDefects ?? []
            if let read = try? PublicTradeAppraisal(listing: listing, disclosedDefects: disclosed, price: price,
                                                   definition: definition, knowledge: store.snapshot.inspectionKnowledge,
                                                   marketBasisPoints: store.snapshot.marketMultiplier(for: definition)) {
                VStack(alignment: .leading, spacing: 10) {
                    Label("tradeRead.title", systemImage: "scope").font(.caption.bold()).foregroundStyle(GameStyle.amber)
                    ValueRangeView(estimate: read.estimate).accessibilityIdentifier("tradeReadRange")
                    Text("tradeRead.margin").font(.caption).foregroundStyle(.secondary)
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 6) { margin(read.lowerMargin); Text(verbatim: "…"); margin(read.upperMargin) }
                        VStack(alignment: .leading, spacing: 4) { margin(read.lowerMargin); margin(read.upperMargin) }
                    }.font(.system(.title3, design: .rounded, weight: .heavy)).monospacedDigit()
                        .accessibilityIdentifier("tradeReadMargin")
                    Text(disclosed.isEmpty ? "tradeRead.claim" : "tradeRead.disclosed").font(.caption).foregroundStyle(.secondary)
                    ForEach(disclosed, id: \.self) { defect in
                        Label(GameText.string(defect.key, locale: locale), systemImage: "exclamationmark.triangle.fill")
                            .font(.caption.bold()).foregroundStyle(GameStyle.loss)
                    }
                    Text("tradeRead.caution").font(.caption).foregroundStyle(.secondary)
                }.frame(maxWidth: .infinity, alignment: .leading).accessibilityIdentifier("tradeRead")
            }
        }
    }
    private func margin(_ amount: Money) -> some View {
        Text(amount.formatted(locale: locale, market: market, signed: true))
            .foregroundStyle(amount < .zero ? GameStyle.loss : GameStyle.gain).fixedSize()
    }
}
