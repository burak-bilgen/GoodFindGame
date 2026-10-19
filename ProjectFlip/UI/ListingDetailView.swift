import SwiftUI

struct ListingDetailView: View {
    let store: GameStore
    let listingID: ListingID
    @Environment(\.locale) private var locale

    var body: some View {
        if let listing = store.snapshot.market.first(where: { $0.id == listingID }), let definition = store.definition(for: listing.item) {
            List {
                Section {
                    DeviceArt(symbol: definition.artSymbol).frame(height: 210)
                    Text(definition.name).font(.title.bold())
                    LabeledContent("listing.asking") { Text(listing.askingPrice.formatted(locale: locale)).font(.title2.bold()) }
                    LabeledContent("listing.claimedCondition") { Text(listing.claimedCondition, format: .number).monospacedDigit() }
                    LabeledContent("listing.referenceValue") { Text(definition.baseValue.formatted(locale: locale)) }
                    Text("listing.claimWarning").font(.caption).foregroundStyle(.secondary)
                }
                Section("listing.description") {
                    Text(GameText.string(listing.descriptionIntent, locale: locale))
                }
                Section("seller.title") { SellerSummary(seller: listing.seller) }
            }
            .safeAreaInset(edge: .bottom) {
                    NavigationLink {
                        ConversationView(store: store, listingID: listing.id)
                    } label: {
                        Text("offer.start").font(.headline).frame(maxWidth: .infinity).padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding().background(.regularMaterial)
                    .accessibilityIdentifier("openConversation")
            }
            .navigationTitle("listing.title")
            .navigationBarTitleDisplayMode(.inline)
        } else {
            ContentUnavailableView("listing.unavailable", systemImage: "tag.slash")
        }
    }
}

struct SellerSummary: View {
    let seller: SellerProfile
    @Environment(\.locale) private var locale
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(GameText.string("npc.name.\(seller.identityIndex % 10)", locale: locale)).font(.headline)
            Text("seller.rating \((Decimal(seller.ratingTenths) / 10).formatted(.number.locale(locale)))")
            Text("seller.trades \(seller.tradeCount)")
            Text(GameText.string("npc.city.\(seller.identityIndex % 10)", locale: locale)).foregroundStyle(.secondary)
            Text("seller.history.empty").font(.caption).foregroundStyle(.secondary)
        }
    }
}
