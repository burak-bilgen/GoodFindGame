import SwiftUI

struct MarketView: View {
    let store: GameStore
    @Environment(\.locale) private var locale
    @GameReduceMotion private var reduceMotion
    @FocusState private var priceInputFocused: Bool
    @State private var filtersExpanded = false
    @State private var category: ItemCategory?
    @State private var newestFirst = true
    @State private var watchedOnly = false
    @State private var search = ""
    @State private var minimumPrice = ""
    @State private var maximumPrice = ""

    private var query: MarketQuery? {
        do {
            let minimum = try MarketQuery.priceBound(minimumPrice, locale: locale)
            let maximum = try MarketQuery.priceBound(maximumPrice, locale: locale)
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
                VStack(alignment: .leading, spacing: 12) {
                    GameEyebrow(key: "hunt.eyebrow")
                    Text("market.heading").font(.system(.title2, design: .rounded, weight: .heavy))
                    Text("market.subtitle").font(.subheadline).foregroundStyle(.secondary)
                    HStack {
                        Text("wallet.cash").font(.caption)
                        Spacer()
                        Text(store.snapshot.player.cash.formatted(locale: locale)).monospacedDigit().bold().contentTransition(.numericText()).animation(reduceMotion ? nil : .easeOut(duration: 0.3), value: store.snapshot.player.cash)
                    }
                }.gameCard()
                FirstTradePrompt(store: store)
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
                            ForEach(ItemCategory.allCases, id: \.self) { value in
                                Text(GameText.string("category.\(value.rawValue)", locale: locale)).tag(Optional(value))
                            }
                        }.accessibilityIdentifier("marketCategory")
                        TextField("market.minimumPrice", text: $minimumPrice).keyboardType(.decimalPad).focused($priceInputFocused).accessibilityIdentifier("minimumPrice")
                        TextField("market.maximumPrice", text: $maximumPrice).keyboardType(.decimalPad).focused($priceInputFocused).accessibilityIdentifier("maximumPrice")
                        Toggle("market.newest", isOn: $newestFirst)
                    }
                    if filtersExpanded || listings.isEmpty {
                        Button("market.clearFilters") {
                            category = nil; minimumPrice = ""; maximumPrice = ""; search = ""; newestFirst = true; watchedOnly = false
                        }
                    }
                }.gameCard()
                if query == nil {
                    Text("market.invalidPriceRange").foregroundStyle(GameStyle.loss)
                } else if listings.isEmpty && !watchedOnly && !store.snapshot.market.contains(where: \.available),
                          let refresh = store.snapshot.events.first(where: { $0.status == .pending && $0.payload == .marketRefresh }) {
                    DeadlineView(store: store, target: refresh.resolveAt, titleKey: "market.nextRefresh")
                } else if listings.isEmpty {
                    ContentUnavailableView(watchedOnly ? "market.watchlistEmpty" : "market.noResults", systemImage: watchedOnly ? "bookmark" : "magnifyingglass")
                }
                ForEach(listings) { listing in
                    if let definition = store.definition(for: listing.item) {
                        NavigationLink {
                            ListingDetailView(store: store, listingID: listing.id)
                        } label: {
                            ListingCard(listing: listing, definition: definition, watched: store.snapshot.watchedListingIDs.contains(listing.id), lifecycle: store.snapshot.marketListingStates.first { $0.id == listing.id })
                        }.buttonStyle(.plain).accessibilityIdentifier("listing.\(listing.id.rawValue)")
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
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("action.done") { priceInputFocused = false }
            }
        }
        .searchable(text: $search, prompt: "market.search")
    }
}

struct ListingCard: View {
    let listing: MarketplaceListing
    let definition: ItemDefinition
    var watched = false
    var lifecycle: MarketListingState?
    @Environment(\.locale) private var locale
    @GameReduceMotion private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 12) {
                    DeviceArt(symbol: definition.artSymbol, identity: definition.id).frame(height: 140)
                    summary
                }
            } else {
                HStack(alignment: .center, spacing: 14) {
                    DeviceArt(symbol: definition.artSymbol, identity: definition.id).frame(width: 112, height: 112)
                    summary
                }
            }
            HStack(alignment: .firstTextBaseline) {
                Text(GameText.string("npc.name.\(listing.seller.identityIndex % 10)", locale: locale)).font(.caption.weight(.semibold))
                Spacer()
                Text(listing.createdAt, style: .relative).font(.caption).foregroundStyle(.secondary)
                if watched { Image(systemName: "bookmark.fill").accessibilityLabel(Text("market.watched")) }
            }
            Text(GameText.string(listing.descriptionIntent, locale: locale))
                .font(.caption).foregroundStyle(.secondary).lineLimit(typeSize.isAccessibilitySize ? nil : 2)
        }.gameCard()
    }
    private var summary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(GameText.string("category.\(definition.category.rawValue)", locale: locale))
                .font(.caption2.weight(.bold)).foregroundStyle(GameStyle.category(definition.category))
            Text(definition.name).font(.headline).foregroundStyle(.primary).fixedSize(horizontal: false, vertical: true)
            if lifecycle?.priceDroppedAt != nil {
                Label("listing.priceDrop", systemImage: "arrow.down.right").font(.caption.weight(.bold)).foregroundStyle(GameStyle.gain)
                if let old = lifecycle?.initialAskingPrice { Text(old.formatted(locale: locale)).strikethrough().font(.caption).foregroundStyle(.secondary) }
            }
            Text(listing.askingPrice.formatted(locale: locale)).font(.system(.title2, design: .rounded, weight: .heavy)).foregroundStyle(.primary)
                .contentTransition(.numericText()).animation(reduceMotion ? nil : .easeOut(duration: 0.3), value: listing.askingPrice)
            Text(GameText.string(listing.claimedCondition >= 85 ? "listing.claim.excellent" : listing.claimedCondition >= 70 ? "listing.claim.good" : "listing.claim.worn", locale: locale))
                .font(.caption2).foregroundStyle(.secondary)
            if !listing.available {
                Text(GameText.string(lifecycle?.closureReason?.key ?? "listing.unavailable", locale: locale)).font(.caption.weight(.bold)).foregroundStyle(.secondary)
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct FirstTradePrompt: View {
    let store: GameStore
    var body: some View {
        if !store.snapshot.playerListings.contains(where: { $0.status == .sold }) {
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
