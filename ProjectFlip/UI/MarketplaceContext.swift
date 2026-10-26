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
        }.font(.system(.title3, design: .default, weight: .semibold)).monospacedDigit()
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
            Text(GameText.string("living.audience.\(definition.category.rawValue)", locale: locale)).font(.caption).foregroundStyle(GameStyle.secondaryText)
        }
    }
}

/// Surfaces actual pending work and ready handoffs, never forecast offers or hidden liquidity scores.
struct OpenTradesView: View {
    let store: GameStore
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market
    var body: some View {
        if let sale = store.snapshot.activeSales.first, store.snapshot.needsBuyerAction(sale) {
            handoff(title: GameText.string("journey.offerWaiting", locale: locale), symbol: "bubble.left.fill", id: "marketBuyerOffer", deadline: store.snapshot.buyerActionDeadline(sale)) {
                SaleListingView(store: store, listingID: sale.id)
            }
        } else if let seller = store.snapshot.readySellerConversations.first {
            handoff(title: GameText.format("living.sellerReady", locale: locale, 1), symbol: "bubble.left.and.bubble.right.fill", id: "marketSellerReady", deadline: seller.counterExpiresAt) {
                ConversationView(store: store, listingID: seller.listingID)
            }
        } else if let brief = ClientEngine.activeBrief(in: store.snapshot),
                  let item = store.snapshot.player.inventory.first(where: { ClientEngine.qualifies($0, request: brief.request) && ItemTransfer.available($0.id, state: store.snapshot) }) {
            let name = GameText.string("client.\(brief.client.id).name.\(market.region.rawValue)", locale: locale)
            handoff(title: GameText.format("clients.ready", locale: locale, name), symbol: "person.crop.circle.badge.checkmark", id: "marketClientReady") {
                OwnedItemView(store: store, itemID: item.id)
            }
        } else if let item = store.snapshot.player.inventory.first(where: { ItemTransfer.available($0.id, state: store.snapshot) }) {
            handoff(title: GameText.string(item.inspected ? "hunt.sell" : "hunt.inspect", locale: locale), symbol: "shippingbox", id: "marketStockReady") {
                OwnedItemView(store: store, itemID: item.id)
            }
        } else if let job = store.snapshot.inspectionJobs.first(where: { $0.status == .pending }) {
            handoff(title: GameText.format("living.inspections", locale: locale, Int64(1)), symbol: "viewfinder", id: "marketReportPending") {
                OwnedItemView(store: store, itemID: job.itemID)
            }
        } else if store.snapshot.shipments.contains(where: { $0.status == .pending }) {
            handoff(title: GameText.string("hunt.delivery", locale: locale), symbol: "shippingbox", id: "marketDeliveryPending") {
                InventoryView(store: store)
            }
        } else if let seller = store.snapshot.conversations.first(where: { !$0.closed && $0.pendingReplyEventID != nil }) {
            handoff(title: GameText.string("seller.awaitingReply", locale: locale), symbol: "clock", id: "marketSellerPending") {
                ConversationView(store: store, listingID: seller.listingID)
            }
        } else if let sale = store.snapshot.activeSales.first {
            handoff(title: GameText.string("hunt.followSale", locale: locale), symbol: "tag", id: "marketSalePending") {
                SaleListingView(store: store, listingID: sale.id)
            }
        }
    }
    private func handoff<Destination: View>(title: String, symbol: String, id: String, deadline: Date? = nil, @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 5) {
                    Label(title, systemImage: symbol).font(.subheadline.bold())
                    if let deadline, let projected = store.projectedDeadline(deadline) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(GameText.string("offer.expires", locale: locale))
                            Text(projected, style: .timer).monospacedDigit()
                        }.font(.caption).foregroundStyle(GameStyle.secondaryText)
                    }
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right").font(.caption)
            }.foregroundStyle(GameStyle.gain).padding(12).frame(minHeight: 44)
                .background(GameStyle.panel, in: RoundedRectangle(cornerRadius: 12))
        }.buttonStyle(.plain).accessibilityIdentifier(id)
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
                Text("living.ifSoldAtAsk").font(.caption).foregroundStyle(GameStyle.secondaryText)
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
                        .accessibilityAddTraits(.isHeader)
                    ValueRangeView(estimate: read.estimate).accessibilityIdentifier("tradeReadRange")
                    Text("tradeRead.margin").font(.caption).foregroundStyle(GameStyle.secondaryText)
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 6) { margin(read.lowerMargin); Text(verbatim: "…"); margin(read.upperMargin) }
                        VStack(alignment: .leading, spacing: 4) { margin(read.lowerMargin); margin(read.upperMargin) }
                    }.font(.system(.title3, design: .default, weight: .semibold)).monospacedDigit()
                        .accessibilityIdentifier("tradeReadMargin")
                    Text(disclosed.isEmpty ? "tradeRead.claim" : "tradeRead.disclosed").font(.caption).foregroundStyle(GameStyle.secondaryText)
                    ForEach(disclosed, id: \.self) { defect in
                        Label(GameText.string(defect.key, locale: locale), systemImage: "exclamationmark.triangle.fill")
                            .font(.caption.bold()).foregroundStyle(GameStyle.loss)
                    }
                    Text("tradeRead.caution").font(.caption).foregroundStyle(GameStyle.secondaryText)
                }.frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityElement(children: .contain).accessibilityIdentifier("tradeRead")
            }
        }
    }
    private func margin(_ amount: Money) -> some View {
        Text(amount.formatted(locale: locale, market: market, signed: true))
            .foregroundStyle(amount < .zero ? GameStyle.loss : GameStyle.gain).fixedSize()
    }
}
