import SwiftUI

/// A model match is public information; it is never a promise about hidden condition.
struct ClientListingHint: View {
    let store: GameStore
    let definitionID: String
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market

    var body: some View {
        if let brief = ClientEngine.activeBrief(in: store.snapshot), brief.request.models.contains(definitionID) {
            VStack(alignment: .leading, spacing: 8) {
                Label(GameText.format("clients.modelMatch", locale: locale, name(brief.client)), systemImage: "scope").font(.subheadline.bold())
                if let cap = brief.request.maximumPayment {
                    Text(GameText.format("clients.budget", locale: locale, cap.formatted(locale: locale, market: market))).font(.caption.bold())
                }
                Text("clients.filterCaution").font(.caption).foregroundStyle(GameStyle.secondaryText)
            }.frame(maxWidth: .infinity, alignment: .leading).gameCard(accent: GameStyle.gain)
                .accessibilityElement(children: .contain).accessibilityIdentifier("clientModelMatch")
        }
    }
    private func name(_ client: ClientDefinition) -> String {
        GameText.string("client.\(client.id).name.\(market.region.rawValue)", locale: locale)
    }
}

struct ClientOwnedOpportunity: View {
    let store: GameStore
    let item: ItemInstance
    let definition: ItemDefinition
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market

    var body: some View {
        if let brief = ClientEngine.activeBrief(in: store.snapshot), brief.request.models.contains(item.definitionID) {
            VStack(alignment: .leading, spacing: 12) {
                let name = GameText.string("client.\(brief.client.id).name.\(market.region.rawValue)", locale: locale)
                Label(GameText.format("clients.modelMatch", locale: locale, name), systemImage: "scope").font(.headline)
                if ClientEngine.qualifies(item, request: brief.request), ItemTransfer.available(item.id, state: store.snapshot),
                   let quote = try? ClientEngine.quote(item, definition: definition, state: store.snapshot) {
                    if let costs = try? item.purchasePrice.adding(item.inspectionCost).adding(item.repairCost),
                       let net = try? quote.subtracting(costs) {
                        Text("buyer.net").font(.caption).foregroundStyle(GameStyle.secondaryText)
                        ProfitAmount(amount: net).font(.title3.bold())
                    }
                    Button {
                        store.perform {
                            try store.fulfillClient(brief.client.id, itemID: item.id, expectedQuote: quote)
                            GameFeel.play(.accepted)
                        }
                    } label: {
                        Text(GameText.format("clients.supplyFor", locale: locale, quote.formatted(locale: locale, market: market)))
                    }.buttonStyle(GameButton()).accessibilityIdentifier("supplyOwnedClient")
                } else {
                    Text("clients.reportRequired").font(.caption).foregroundStyle(GameStyle.secondaryText)
                    Text(GameText.format("clients.condition", locale: locale, brief.request.minimumCondition)).font(.caption)
                    if !ItemTransfer.available(item.id, state: store.snapshot) { Text("clients.itemBusy").font(.caption).foregroundStyle(GameStyle.amber) }
                    NavigationLink { ClientBookView(store: store) } label: { Text("clients.review") }
                        .buttonStyle(GameButton(secondary: true)).accessibilityIdentifier("clientItemBrief")
                }
            }.frame(maxWidth: .infinity, alignment: .leading).gameCard(accent: GameStyle.gain)
                .accessibilityElement(children: .contain).accessibilityIdentifier("clientOwnedOpportunity")
        }
    }
}
