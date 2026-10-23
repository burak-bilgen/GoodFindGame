import SwiftUI

struct MarketView: View {
    let store: GameStore
    var competition: CompetitionStore? = nil
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market
    @GameReduceMotion private var reduceMotion
    @FocusState private var priceInputFocused: Bool
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var filtersExpanded = false
    @State private var category: ItemCategory?
    @State private var newestFirst = true
    @State private var watchedOnly = false
    @State private var search = ""
    @State private var minimumPrice = ""
    @State private var maximumPrice = ""

    private var query: MarketQuery? {
        do {
            let minimum = try MarketQuery.priceBound(minimumPrice, locale: locale, market: market)
            let maximum = try MarketQuery.priceBound(maximumPrice, locale: locale, market: market)
            if let minimum, let maximum, minimum > maximum { return nil }
            return MarketQuery(search: search, category: category, minimumPrice: minimum, maximumPrice: maximum,
                               watchedOnly: watchedOnly, newestFirst: newestFirst)
        } catch { return nil }
    }
    private var listings: [MarketplaceListing] {
        query?.results(in: store.snapshot, definitions: store.definitions, locale: locale) ?? []
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").foregroundStyle(GameStyle.gain).accessibilityHidden(true)
                    TextField("market.search", text: $search).textInputAutocapitalization(.never).autocorrectionDisabled()
                        .accessibilityIdentifier("marketSearch")
                }.padding(14).background(GameStyle.ink, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(GameStyle.line, lineWidth: 1))
                TradingDeskHeader(store: store)
                if store.snapshot.economyMigrationNotice || store.snapshot.sharedMarketMigrationNotice {
                    NavigationLink { MarketSettingsView(store: store) } label: {
                        GameMenuRow(titleKey: "region.migrationTitle", symbol: "info.circle.fill")
                    }.buttonStyle(.plain).accessibilityIdentifier("economyMigrationNotice")
                }
                if store.competitionPeriod == nil, let competition,
                   ((try? TradeLedger.records(from: store.snapshot).filter { $0.kind == .market || $0.kind == .client }.count) ?? 0) >= 3,
                   competition.saved.runs.isEmpty {
                    NavigationLink { CompetitionView(career: store, competition: competition) } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("competition.weekly", systemImage: "trophy.fill").font(.headline)
                            Text("competition.invite").font(.subheadline)
                        }.frame(maxWidth: .infinity, alignment: .leading).gameCard(accent: GameStyle.amber)
                    }.buttonStyle(.plain)
                }
                CareerHuntPrompt(store: store)
                if store.competitionPeriod == nil && (store.snapshot.player.cash < RecoveryEngine.capitalFloor || store.snapshot.recovery.itemID != nil) {
                    NavigationLink { RecoveryDeskView(store: store) } label: { GameMenuRow(titleKey: "recovery.title", symbol: "arrow.uturn.up.circle.fill") }.buttonStyle(.plain).accessibilityIdentifier("marketRecovery")
                }
                OpenTradesView(store: store)
                TradeContinuationPrompt(store: store)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Toggle("market.watchedOnly", isOn: $watchedOnly).accessibilityIdentifier("watchedOnly")
                        Button { filtersExpanded.toggle() } label: {
                            Label("market.filters", systemImage: "slider.horizontal.3").labelStyle(.iconOnly).frame(minWidth: 44, minHeight: 44)
                        }.accessibilityIdentifier("marketFilters")
                            .accessibilityValue(Text(filtersExpanded ? "market.expanded" : "market.collapsed"))
                    }
                    if filtersExpanded {
                        Picker("market.category", selection: $category) {
                            Text("market.allCategories").tag(Optional<ItemCategory>.none)
                            ForEach(ItemCategory.allCases.filter { category in MarketCatalog.active(store.definitions).contains { $0.category == category } }, id: \.self) { value in
                                Text(GameText.string("category.\(value.rawValue)", locale: locale)).tag(Optional(value))
                            }
                        }.accessibilityIdentifier("marketCategory")
                        TextField("market.minimumPrice", text: $minimumPrice).textFieldStyle(GamePriceFieldStyle()).keyboardType(.decimalPad).focused($priceInputFocused).accessibilityIdentifier("minimumPrice")
                        TextField("market.maximumPrice", text: $maximumPrice).textFieldStyle(GamePriceFieldStyle()).keyboardType(.decimalPad).focused($priceInputFocused).accessibilityIdentifier("maximumPrice")
                        Toggle("market.newest", isOn: $newestFirst)
                    }
                    if filtersExpanded || listings.isEmpty {
                        Button("market.clearFilters") {
                            category = nil; minimumPrice = ""; maximumPrice = ""; search = ""; newestFirst = true; watchedOnly = false
                        }
                    }
                }.padding(.horizontal, 4)
                if query == nil {
                    Text("market.invalidPriceRange").foregroundStyle(GameStyle.loss)
                } else if listings.isEmpty && !watchedOnly && !store.snapshot.market.contains(where: \.available),
                          let refresh = store.snapshot.events.first(where: { $0.status == .pending && $0.payload == .marketRefresh }) {
                    DeadlineView(store: store, target: refresh.resolveAt, titleKey: "market.nextRefresh")
                } else if listings.isEmpty {
                    ContentUnavailableView(watchedOnly ? "market.watchlistEmpty" : "market.noResults", systemImage: watchedOnly ? "bookmark" : "magnifyingglass")
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12, alignment: .top), count: typeSize.isAccessibilitySize ? 1 : 2), alignment: .leading, spacing: 16) {
                    ForEach(listings) { listing in
                        if let definition = store.definition(for: listing.item) {
                            NavigationLink {
                                ListingDetailView(store: store, listingID: listing.id)
                            } label: {
                                ListingCard(listing: listing, definition: definition, requiredCareer: CareerEngine.canAccess(definition, state: store.snapshot) ? nil : CareerEngine.requiredTier(for: definition), watched: store.snapshot.watchedListingIDs.contains(listing.id), lifecycle: store.snapshot.marketListingStates.first { $0.id == listing.id })
                            }.buttonStyle(.plain).accessibilityIdentifier("listing.\(listing.id.rawValue)")
                        }
                    }
                }
            }.padding(16)
        }
        .gameScreen()
        .navigationTitle("market.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink { MarketTrendsView(store: store) } label: {
                    Label("trend.title", systemImage: "chart.line.uptrend.xyaxis")
                }.accessibilityIdentifier("openMarketTrends")
            }
            ToolbarItem(placement: .topBarTrailing) {
                if priceInputFocused { Button("action.done") { priceInputFocused = false } }
            }
        }
    }
}

struct ListingCard: View {
    let listing: MarketplaceListing
    let definition: ItemDefinition
    var requiredCareer: CareerTier?
    var watched = false
    var lifecycle: MarketListingState?
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market
    @GameReduceMotion private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            DeviceArt(symbol: definition.artSymbol, identity: definition.id, appearance: .advertised(listing))
                .aspectRatio(1, contentMode: .fit)
                .overlay(alignment: .topTrailing) {
                    if watched {
                        Image(systemName: "bookmark.fill").font(.caption).foregroundStyle(GameStyle.ink)
                            .padding(8).background(GameStyle.amber, in: Circle()).padding(8)
                            .accessibilityLabel(Text("market.watched"))
                    }
                }
            VStack(alignment: .leading, spacing: 7) {
                if let requiredCareer { Label(GameText.string(requiredCareer.key, locale: locale), systemImage: "lock.fill").font(.caption2.bold()).foregroundStyle(GameStyle.amber) }
                Text(GameText.string("category.\(definition.category.rawValue)", locale: locale))
                    .font(.caption2.weight(.bold)).foregroundStyle(GameStyle.category(definition.category))
                    .lineLimit(typeSize.isAccessibilitySize ? nil : 1)
                Text(definition.displayName(locale: locale)).font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(.primary).lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: typeSize.isAccessibilitySize ? 0 : 42, alignment: .topLeading)
                Text(listing.askingPrice.formatted(locale: locale, market: market))
                    .font(.system(.title2, design: .rounded, weight: .black)).foregroundStyle(.primary)
                    .lineLimit(1).minimumScaleFactor(0.65)
                    .contentTransition(.numericText()).animation(reduceMotion ? nil : .easeOut(duration: 0.3), value: listing.askingPrice)
                if lifecycle?.priceDroppedAt != nil {
                    Label("listing.priceDrop", systemImage: "arrow.down.right").font(.caption2.bold()).foregroundStyle(GameStyle.gain)
                    if let old = lifecycle?.initialAskingPrice { Text(old.formatted(locale: locale, market: market)).strikethrough().font(.caption2).foregroundStyle(GameStyle.secondaryText) }
                }
                Text(GameText.string(listing.descriptionIntent, locale: locale))
                    .font(.caption).foregroundStyle(GameStyle.secondaryText).lineLimit(typeSize.isAccessibilitySize ? nil : 2)
                    .frame(minHeight: typeSize.isAccessibilitySize ? 0 : 32, alignment: .topLeading)
                Divider()
                HStack(spacing: 6) {
                    TraderPortrait(identity: listing.seller.identityIndex, size: 24)
                    Text(GameText.marketPerson("name", index: listing.seller.identityIndex, market: market, locale: locale)).font(.caption2.weight(.semibold)).foregroundStyle(.primary)
                    Spacer(minLength: 0)
                }
                Text(listing.createdAt, style: .relative).font(.caption2).foregroundStyle(GameStyle.secondaryText)
                if !listing.available {
                    Text(GameText.string(lifecycle?.closureReason?.key ?? "listing.unavailable", locale: locale)).font(.caption.weight(.bold)).foregroundStyle(GameStyle.secondaryText)
                }
            }.padding(.horizontal, 3)
        }
        .padding(10)
        .background(LinearGradient(colors: [GameStyle.panelTop, GameStyle.panel], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(GameStyle.category(definition.category).opacity(0.6), lineWidth: 1))
        .background(RoundedRectangle(cornerRadius: 18).fill(.black.opacity(0.5)).offset(y: 5))
        .gameEntrance()
    }
}

struct TradeContinuationPrompt: View {
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market
    let store: GameStore
    var body: some View {
        if let sale = store.snapshot.playerListings.reversed().first(where: { listing in
            listing.status == .active && !store.snapshot.hasBuyerReply(for: listing.id) && listing.offers.last.map { [.pending, .countered].contains($0.status) } == true
        }), let offer = sale.offers.last {
            NavigationLink { SaleListingView(store: store, listingID: sale.id) } label: {
                HStack(spacing: 12) {
                    TraderPortrait(identity: offer.identityIndex, size: 48)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("journey.offerWaiting").font(.caption.bold()).foregroundStyle(GameStyle.gain)
                        if let item = store.snapshot.player.inventory.first(where: { $0.id == sale.itemID }), let definition = store.definition(for: item) {
                            Text(definition.displayName(locale: locale)).font(.headline).foregroundStyle(.primary)
                        }
                        Text(offer.amount.formatted(locale: locale, market: market)).font(.system(.title2, design: .rounded, weight: .heavy)).foregroundStyle(.primary)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.up.right").foregroundStyle(GameStyle.gain).accessibilityHidden(true)
                }.frame(maxWidth: .infinity, alignment: .leading).gameCard(accent: GameStyle.gain)
            }.buttonStyle(.plain).accessibilityIdentifier("marketBuyerOffer")
        } else if !store.snapshot.playerListings.contains(where: { $0.status == .sold }) {
            if let sale = store.snapshot.playerListings.first(where: { $0.status == .active }) {
                NavigationLink { SaleListingView(store: store, listingID: sale.id) } label: {
                    Label("hunt.followSale", systemImage: "tag.fill")
                }.buttonStyle(GameButton())
            } else if let item = store.snapshot.player.inventory.first {
                NavigationLink { OwnedItemView(store: store, itemID: item.id) } label: {
                    Label(item.inspected ? "hunt.sell" : "hunt.inspect", systemImage: "shippingbox.fill")
                }.buttonStyle(GameButton())
            } else if store.snapshot.shipments.contains(where: { $0.status == .pending }) {
                NavigationLink { InventoryView(store: store) } label: {
                    Label("hunt.delivery", systemImage: "shippingbox")
                }.buttonStyle(GameButton())
            }
        }
    }
}
