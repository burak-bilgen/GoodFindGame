import SwiftUI

struct ListingDetailView: View {
    let store: GameStore
    let listingID: ListingID
    @Environment(\.locale) private var locale
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if let listing = store.snapshot.market.first(where: { $0.id == listingID }), let definition = store.definition(for: listing.item) {
            List {
                Section {
                    DeviceArt(symbol: definition.artSymbol).frame(height: 210)
                    Text(definition.name).font(.title.bold())
                    LabeledContent("listing.asking") { Text(listing.askingPrice.formatted(locale: locale)).font(.title2.bold()) }
                    LabeledContent("listing.claimedCondition") { Text(listing.claimedCondition, format: .number).monospacedDigit() }
                    switch Result(catching: { try definition.baseValue.scaled(byBasisPoints: store.snapshot.marketMultiplier(for: definition)) }) {
                    case .success(let reference): LabeledContent("listing.referenceValue") { Text(reference.formatted(locale: locale)) }
                    case .failure: Text("inspection.valueUnavailable")
                    }
                    Text("listing.claimWarning").font(.caption).foregroundStyle(.secondary)
                }
                Section("listing.description") {
                    Text(GameText.string(listing.descriptionIntent, locale: locale))
                }
                Section("seller.title") { SellerSummary(seller: listing.seller, playerTradeCount: store.previousTradeCount(with: listing.seller.id)) }
            }
            .safeAreaInset(edge: .bottom) {
                    NavigationLink {
                        ConversationView(store: store, listingID: listing.id)
                    } label: {
                        Text("offer.start").font(.headline).frame(maxWidth: .infinity).padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .foregroundStyle(colorScheme == .dark ? .black : .white)
                    .padding().background(.regularMaterial)
                    .accessibilityIdentifier("openConversation")
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    let watched = store.snapshot.watchedListingIDs.contains(listing.id)
                    Button {
                        store.perform { try store.toggleWatch(listingID: listing.id) }
                    } label: {
                        Label(watched ? "market.unwatch" : "market.watch", systemImage: watched ? "bookmark.fill" : "bookmark")
                    }.accessibilityIdentifier("toggleWatch")
                }
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
    var playerTradeCount = 0
    @Environment(\.locale) private var locale
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(GameText.string("npc.name.\(seller.identityIndex % 10)", locale: locale)).font(.headline)
            Text("seller.rating \((Decimal(seller.ratingTenths) / 10).formatted(.number.locale(locale)))")
            Text("seller.trades \(seller.tradeCount)")
            Text(GameText.string("npc.city.\(seller.identityIndex % 10)", locale: locale)).foregroundStyle(.secondary)
            if playerTradeCount == 0 {
                Text("seller.history.empty").font(.caption).foregroundStyle(.secondary)
            } else {
                Text("seller.history.trades \(playerTradeCount)").font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
