import SwiftUI

/// A preview of the existing purchase debit, not a reservation or an extra fee.
struct PurchaseDecision: View {
    let store: GameStore
    let listingID: ListingID
    let price: Money
    @Environment(\.locale) private var locale
    @Environment(\.returnToHunt) private var hunt

    private var hasCash: Bool { store.snapshot.player.cash >= price }
    private var hasRoom: Bool {
        store.snapshot.player.inventory.count + store.snapshot.shipments.filter { $0.status == .pending }.count < store.snapshot.player.inventoryCapacity
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            GameStamp(key: "offer.agreed", symbol: "checkmark.seal.fill")
            if let listing = store.snapshot.market.first(where: { $0.id == listingID }), let definition = store.definition(for: listing.item) {
                HStack(spacing: 12) {
                    DeviceArt(symbol: definition.artSymbol, identity: definition.id, appearance: .advertised(listing)).frame(width: 64, height: 64)
                    Text(definition.name).font(.system(.headline, design: .rounded, weight: .heavy))
                }
            }
            Text(price.formatted(locale: locale)).accessibilityIdentifier("purchaseAgreedAmount").font(.system(.largeTitle, design: .rounded, weight: .heavy))
                .lineLimit(1).minimumScaleFactor(0.5)
            Label("living.standardDelivery", systemImage: "shippingbox").font(.caption).foregroundStyle(.secondary)
            Text("journey.commit").font(.subheadline).foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 6) {
                Text(hasCash ? "purchase.cashAfter" : "purchase.cashNeeded").font(.caption).foregroundStyle(.secondary)
                switch Result(catching: {
                    hasCash ? try store.snapshot.player.cash.subtracting(price) : try price.subtracting(store.snapshot.player.cash)
                }) {
                case .success(let difference):
                    Text(difference.formatted(locale: locale)).font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(hasCash ? Color.primary : GameStyle.loss)
                        .lineLimit(1).minimumScaleFactor(0.5).accessibilityIdentifier("purchaseBudgetAmount")
                case .failure: Text("trade.unavailable")
                }
            }.padding(12).frame(maxWidth: .infinity, alignment: .leading)
                .background(GameStyle.gain.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
            if !hasCash {
                Label("error.insufficientCash", systemImage: "wallet.bifold").font(.caption).foregroundStyle(GameStyle.loss)
            }
            if !hasRoom {
                Label("error.inventoryFull", systemImage: "shippingbox.fill").font(.caption).foregroundStyle(.secondary)
            }
            Button("purchase.confirm") {
                store.perform { try store.purchase(listingID: listingID); GameFeel.play(.purchase) }
            }.buttonStyle(GameButton()).disabled(!hasCash || !hasRoom).accessibilityIdentifier("confirmPurchase")
            Button("offer.walkAway", role: .destructive) {
                store.perform { try store.walkAway(listingID: listingID); hunt() }
            }.accessibilityIdentifier("declinePurchase")
        }.gameCard()
    }
}
