import SwiftUI

struct ListingDetailView: View {
    let store: GameStore
    let listingID: ListingID
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        if let listing = store.snapshot.market.first(where: { $0.id == listingID }), let definition = store.definition(for: listing.item) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    DeviceArt(symbol: definition.artSymbol, identity: definition.id, appearance: .advertised(listing)).frame(maxWidth: 180).frame(maxWidth: .infinity)
                    Text("art.sellerPresentation").font(.caption).foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 10) {
                        Text(GameText.string("category.\(definition.category.rawValue)", locale: locale))
                            .font(.caption.weight(.bold)).foregroundStyle(GameStyle.category(definition.category)).accessibilityIdentifier("listingCategoryName")
                        Text(definition.displayName(locale: locale)).font(.system(.title, design: .rounded, weight: .heavy))
                        HStack(alignment: .firstTextBaseline) {
                            Text(listing.askingPrice.formatted(locale: locale, market: market, precise: true)).accessibilityIdentifier("listingAskingAmount").font(.system(.largeTitle, design: .rounded, weight: .black)).minimumScaleFactor(0.65).lineLimit(1)
                            Spacer(minLength: 0)
                            Image(systemName: "tag.fill").foregroundStyle(GameStyle.gain).accessibilityHidden(true)
                        }
                        if let lifecycle = store.snapshot.marketListingStates.first(where: { $0.id == listing.id }) {
                            if lifecycle.priceDroppedAt != nil {
                                HStack {
                                    Label("listing.priceDrop", systemImage: "arrow.down.right").foregroundStyle(GameStyle.gain)
                                    Text(lifecycle.initialAskingPrice.formatted(locale: locale, market: market)).strikethrough().foregroundStyle(.secondary)
                                }.font(.subheadline)
                            }
                            if listing.available { DeadlineView(store: store, target: lifecycle.expiresAt, titleKey: "listing.expires") }
                            else { Text(GameText.string(lifecycle.closureReason?.key ?? "listing.unavailable", locale: locale)).bold() }
                        }
                    }
                    TradeReadView(store: store, listing: listing, price: listing.askingPrice)
                        .gameCard(accent: GameStyle.amber)
                    VStack(alignment: .leading, spacing: 12) {
                        GameStamp(key: "listing.description", symbol: "quote.bubble.fill")
                        Text(GameText.string(listing.descriptionIntent, locale: locale)).font(.title3)
                        LabeledContent("listing.claimedCondition") { Text(listing.claimedCondition, format: .number).bold() }
                        Text("listing.claimWarning").font(.caption).foregroundStyle(.secondary)
                    }.gameCard()
                    VStack(alignment: .leading, spacing: 10) {
                        SellerSummary(seller: listing.seller, playerTradeCount: store.previousTradeCount(with: listing.seller.id))
                        Text(GameText.string("seller.voice.\(listing.seller.archetype.rawValue)", locale: locale)).font(.subheadline).foregroundStyle(.secondary)
                    }.gameCard()
                }.padding(16)
            }.gameScreen()
            .safeAreaInset(edge: .bottom) {
                if listing.available && !CareerEngine.canAccess(definition, state: store.snapshot) && store.snapshot.career.legacyAgreements?.contains(listing.id) != true {
                    NavigationLink { TraderCareerView(store: store) } label: {
                        Label(GameText.string(CareerEngine.requiredTier(for: definition).key, locale: locale), systemImage: "lock.fill")
                    }.buttonStyle(GameButton(secondary: true)).padding(16).background(GameStyle.ink)
                } else if listing.available || store.snapshot.conversations.contains(where: { $0.listingID == listing.id }) {
                        NavigationLink {
                            ConversationView(store: store, listingID: listing.id)
                        } label: {
                            Text(listing.available ? "offer.start" : "messages.title")
                        }
                        .buttonStyle(GameButton())
                        .accessibilityIdentifier("openConversation")
                        .padding().background(GameStyle.ink.opacity(0.98))
                }
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
    @Environment(\.marketConfiguration) private var market
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                TraderPortrait(identity: seller.identityIndex)
                Text(GameText.marketPerson("name", index: seller.identityIndex, market: market, locale: locale)).font(.headline)
                Spacer()
                Label((Decimal(seller.ratingTenths) / 10).formatted(.number.locale(locale)), systemImage: "star.fill").font(.caption.bold())
                    .accessibilityLabel(Text("seller.rating \((Decimal(seller.ratingTenths) / 10).formatted(.number.locale(locale)))"))
            }
            Text("seller.trades \(seller.tradeCount)").font(.caption).foregroundStyle(.secondary)
            Text(GameText.marketPerson("city", index: seller.identityIndex, market: market, locale: locale)).font(.caption).foregroundStyle(.secondary)
            if playerTradeCount > 0 { Text("seller.history.trades \(playerTradeCount)").font(.caption).foregroundStyle(.secondary) }
        }
    }
}
