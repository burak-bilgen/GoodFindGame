import SwiftUI

/// Only the public asking price, known costs and visible negotiation status.
struct SalePriceRevisionPreview: View {
    let item: ItemInstance
    let listing: PlayerListing
    let proposedPrice: Money?
    let draft: String
    let awaitingReply: Bool
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let proposedPrice {
                if proposedPrice == listing.askingPrice {
                    Text("selling.priceUnchanged").font(.caption).foregroundStyle(GameStyle.secondaryText)
                        .accessibilityIdentifier("salePriceUnchanged")
                } else {
                    LabeledContent("selling.currentAsking") { Text(listing.askingPrice.formatted(locale: locale, market: market, precise: true)).bold() }
                    AskingResultView(item: item, askingPrice: draft)
                    Text("living.notGuaranteed").font(.caption).foregroundStyle(GameStyle.secondaryText)
                    Text(awaitingReply || listing.offers.contains(where: { [.pending, .countered].contains($0.status) }) ? "selling.repriceOfferWarning" : "selling.repriceSearch")
                        .font(.subheadline).foregroundStyle(GameStyle.amber).accessibilityIdentifier("saleRepricingConsequence")
                    Text("selling.repriceExpiry").font(.caption).foregroundStyle(GameStyle.secondaryText)
                }
            } else { Text("error.invalidAmount").font(.caption).foregroundStyle(GameStyle.loss) }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}
