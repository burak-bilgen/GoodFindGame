import SwiftUI

struct ListingDetailView: View {
    let store: GameStore
    let listingID: ListingID
    @Environment(\.locale) private var locale

    var body: some View {
        if let listing = store.snapshot.market.first(where: { $0.id == listingID }), let definition = store.definition(for: listing.item) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    DeviceArt(symbol: definition.artSymbol, identity: definition.id).frame(height: 210)
                    VStack(alignment: .leading, spacing: 10) {
                        Text(GameText.string("category.\(definition.category.rawValue)", locale: locale))
                            .font(.caption.weight(.bold)).foregroundStyle(GameStyle.category(definition.category)).accessibilityIdentifier("listingCategoryName")
                        Text(definition.name).font(.system(.title, design: .rounded, weight: .heavy))
                        HStack(alignment: .firstTextBaseline) {
                            Text(listing.askingPrice.formatted(locale: locale)).font(.system(.largeTitle, design: .rounded, weight: .black)).minimumScaleFactor(0.65).lineLimit(1)
                            Spacer(minLength: 0)
                            Image(systemName: "tag.fill").foregroundStyle(GameStyle.gain).accessibilityHidden(true)
                        }
                        if let lifecycle = store.snapshot.marketListingStates.first(where: { $0.id == listing.id }) {
                            if lifecycle.priceDroppedAt != nil {
                                HStack {
                                    Label("listing.priceDrop", systemImage: "arrow.down.right").foregroundStyle(GameStyle.gain)
                                    Text(lifecycle.initialAskingPrice.formatted(locale: locale)).strikethrough().foregroundStyle(.secondary)
                                }.font(.subheadline)
                            }
                            if listing.available { DeadlineView(store: store, target: lifecycle.expiresAt, titleKey: "listing.expires") }
                            else { Text(GameText.string(lifecycle.closureReason?.key ?? "listing.unavailable", locale: locale)).bold() }
                        }
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        GameStamp(key: "listing.description", symbol: "quote.bubble.fill")
                        Text(GameText.string(listing.descriptionIntent, locale: locale)).font(.title3)
                        LabeledContent("listing.claimedCondition") { Text(listing.claimedCondition, format: .number).bold() }
                        Text("listing.claimWarning").font(.caption).foregroundStyle(.secondary)
                    }.gameCard()
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "shippingbox.fill").font(.title).foregroundStyle(GameStyle.amber).accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("game.truth").font(.headline).foregroundStyle(.white)
                                Text("game.unknown").font(.caption).foregroundStyle(GameStyle.amber)
                            }
                        }
                        HStack(alignment: .top, spacing: 12) {
                            mysteryStat("game.conditionUnknown")
                            mysteryStat("game.faultUnknown")
                        }
                        Text("game.truthHint").font(.caption).foregroundStyle(.white.opacity(0.78))
                    }.padding(18).frame(maxWidth: .infinity, alignment: .leading)
                        .background(GameStyle.ink, in: RoundedRectangle(cornerRadius: 22))
                    VStack(alignment: .leading, spacing: 10) {
                        SellerSummary(seller: listing.seller, playerTradeCount: store.previousTradeCount(with: listing.seller.id))
                        Text(GameText.string("seller.voice.\(listing.seller.archetype.rawValue)", locale: locale)).font(.subheadline).foregroundStyle(.secondary)
                    }.gameCard()
                    DisclosureGroup("listing.referenceValue") {
                        VStack(alignment: .leading, spacing: 8) {
                            switch Result(catching: { try definition.baseValue.scaled(byBasisPoints: store.snapshot.marketMultiplier(for: definition)) }) {
                            case .success(let reference): Text(reference.formatted(locale: locale)).font(.title2.bold())
                            case .failure: Text("inspection.valueUnavailable")
                            }
                            Text("listing.referenceCaution").font(.caption).foregroundStyle(.secondary)
                        }.padding(.top, 8)
                    }.gameCard()
                }.padding(16)
            }.gameScreen()
            .safeAreaInset(edge: .bottom) {
                if listing.available || store.snapshot.conversations.contains(where: { $0.listingID == listing.id }) {
                        NavigationLink {
                            ConversationView(store: store, listingID: listing.id)
                        } label: {
                            Text(listing.available ? "offer.start" : "messages.title")
                        }
                        .buttonStyle(GameButton())
                        .accessibilityIdentifier("openConversation")
                        .padding().background(.regularMaterial)
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
    private func mysteryStat(_ key: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("?").font(.system(.title, design: .rounded, weight: .black)).foregroundStyle(GameStyle.amber).accessibilityHidden(true)
            Text(GameText.string(key, locale: locale)).font(.caption.bold()).foregroundStyle(.white)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(12)
            .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct SellerSummary: View {
    let seller: SellerProfile
    var playerTradeCount = 0
    @Environment(\.locale) private var locale
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                TraderPortrait(identity: seller.identityIndex)
                Text(GameText.string("npc.name.\(seller.identityIndex % 10)", locale: locale)).font(.headline)
                Spacer()
                Label((Decimal(seller.ratingTenths) / 10).formatted(.number.locale(locale)), systemImage: "star.fill").font(.caption.bold())
                    .accessibilityLabel(Text("seller.rating \((Decimal(seller.ratingTenths) / 10).formatted(.number.locale(locale)))"))
            }
            Text("seller.trades \(seller.tradeCount)").font(.caption).foregroundStyle(.secondary)
            Text(GameText.string("npc.city.\(seller.identityIndex % 10)", locale: locale)).font(.caption).foregroundStyle(.secondary)
            if playerTradeCount > 0 { Text("seller.history.trades \(playerTradeCount)").font(.caption).foregroundStyle(.secondary) }
        }
    }
}
