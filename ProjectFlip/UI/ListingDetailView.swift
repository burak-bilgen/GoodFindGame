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
                    DeviceArt(symbol: definition.artSymbol, identity: definition.id, appearance: .advertised(listing)).frame(maxWidth: typeSize.isAccessibilitySize ? 240 : 320).frame(maxWidth: .infinity)
                        .overlay(alignment: .topTrailing) {
                            let watched = store.snapshot.watchedListingIDs.contains(listing.id)
                            Button {
                                store.perform { try store.toggleWatch(listingID: listing.id) }
                            } label: {
                                Label(watched ? "market.unwatch" : "market.watch", systemImage: watched ? "bookmark.fill" : "bookmark")
                                    .labelStyle(.iconOnly).font(.title3)
                                    .frame(width: 44, height: 44).contentShape(Rectangle())
                                    .background(GameStyle.panel, in: RoundedRectangle(cornerRadius: 12))
                            }.buttonStyle(.plain).foregroundStyle(GameStyle.gain).accessibilityIdentifier("toggleWatch")
                        }
                    Text("art.sellerPresentation").font(.caption).foregroundStyle(GameStyle.secondaryText)
                    VStack(alignment: .leading, spacing: 10) {
                        Text(GameText.string("category.\(definition.category.rawValue)", locale: locale))
                            .font(.caption.weight(.bold)).foregroundStyle(GameStyle.category(definition.category)).accessibilityIdentifier("listingCategoryName")
                        Text(definition.displayName(locale: locale)).font(.system(.title, design: .default, weight: .semibold))
                        HStack(alignment: .firstTextBaseline) {
                            Text(listing.askingPrice.formatted(locale: locale, market: market, precise: true)).accessibilityIdentifier("listingAskingAmount").font(.system(.largeTitle, design: .default, weight: .bold)).minimumScaleFactor(0.65).lineLimit(1)
                            Spacer(minLength: 0)
                            Image(systemName: "tag.fill").foregroundStyle(GameStyle.gain).accessibilityHidden(true)
                        }
                        if let lifecycle = store.snapshot.marketListingStates.first(where: { $0.id == listing.id }) {
                            if lifecycle.priceDroppedAt != nil {
                                HStack {
                                    Label("listing.priceDrop", systemImage: "arrow.down.right").foregroundStyle(GameStyle.gain)
                                    Text(lifecycle.initialAskingPrice.formatted(locale: locale, market: market)).strikethrough().foregroundStyle(GameStyle.secondaryText)
                                }.font(.subheadline)
                            }
                            if listing.available { DeadlineView(store: store, target: lifecycle.expiresAt, titleKey: "listing.expires") }
                            else { Text(GameText.string(lifecycle.closureReason?.key ?? "listing.unavailable", locale: locale)).bold() }
                        }
                    }
                    if listing.available { ClientListingHint(store: store, definitionID: definition.id) }
                    TradeReadView(store: store, listing: listing, price: listing.askingPrice)
                        .gameCard(accent: GameStyle.amber)
                    VStack(alignment: .leading, spacing: 12) {
                        GameStamp(key: "listing.description", symbol: "quote.bubble.fill")
                        Text(GameText.string(listing.descriptionIntent, locale: locale)).font(.title3)
                        LabeledContent("listing.claimedCondition") { Text(listing.claimedCondition, format: .number).bold() }
                        Text("listing.claimWarning").font(.caption).foregroundStyle(GameStyle.secondaryText)
                    }.gameCard()
                    VStack(alignment: .leading, spacing: 10) {
                        SellerSummary(seller: listing.seller, playerTradeCount: store.previousTradeCount(with: listing.seller.id))
                        Text(GameText.string("seller.voice.\(listing.seller.archetype.rawValue)", locale: locale)).font(.subheadline).foregroundStyle(GameStyle.secondaryText)
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

            }
            Text(GameText.marketPerson("city", index: seller.identityIndex, market: market, locale: locale)).font(.caption).foregroundStyle(GameStyle.secondaryText)
            if playerTradeCount > 0 { Text("seller.history.trades \(playerTradeCount)").font(.caption).foregroundStyle(GameStyle.secondaryText) }
        }
    }
}
