import SwiftUI

struct MarketView: View {
    let store: GameStore
    @Environment(\.locale) private var locale
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
                HStack(alignment: .center, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("hunt.eyebrow").font(.caption2.weight(.heavy)).tracking(2).foregroundStyle(GameStyle.amber)
                        Text("market.heading").font(.system(.title2, design: .rounded, weight: .black)).foregroundStyle(.white)
                        Text("market.subtitle").font(.caption).foregroundStyle(.white.opacity(0.76))
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "viewfinder").font(.system(size: 38, weight: .light)).foregroundStyle(GameStyle.amber).accessibilityHidden(true)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LinearGradient(colors: [Color(red: 0.16, green: 0.26, blue: 0.32), GameStyle.ink], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 22))
                HStack(spacing: 8) {
                    Image(systemName: "banknote.fill").foregroundStyle(GameStyle.gain)
                    Text("wallet.cash").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text(store.snapshot.player.cash.formatted(locale: locale)).font(.system(.headline, design: .rounded, weight: .heavy)).monospacedDigit().accessibilityIdentifier("marketCash")
                        .contentTransition(.numericText()).animation(reduceMotion ? nil : .easeOut(duration: 0.3), value: store.snapshot.player.cash)
                }.padding(.horizontal, 4)
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
                                ListingCard(listing: listing, definition: definition, watched: store.snapshot.watchedListingIDs.contains(listing.id), lifecycle: store.snapshot.marketListingStates.first { $0.id == listing.id })
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
                Text(GameText.string("category.\(definition.category.rawValue)", locale: locale))
                    .font(.caption2.weight(.bold)).foregroundStyle(GameStyle.category(definition.category))
                    .lineLimit(typeSize.isAccessibilitySize ? nil : 1)
                Text(definition.displayName(locale: locale)).font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(.primary).lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: typeSize.isAccessibilitySize ? 0 : 42, alignment: .topLeading)
                Text(listing.askingPrice.formatted(locale: locale))
                    .font(.system(.title2, design: .rounded, weight: .black)).foregroundStyle(.primary)
                    .lineLimit(1).minimumScaleFactor(0.65)
                    .contentTransition(.numericText()).animation(reduceMotion ? nil : .easeOut(duration: 0.3), value: listing.askingPrice)
                if lifecycle?.priceDroppedAt != nil {
                    Label("listing.priceDrop", systemImage: "arrow.down.right").font(.caption2.bold()).foregroundStyle(GameStyle.gain)
                    if let old = lifecycle?.initialAskingPrice { Text(old.formatted(locale: locale)).strikethrough().font(.caption2).foregroundStyle(.secondary) }
                }
                Text(GameText.string(listing.descriptionIntent, locale: locale))
                    .font(.caption).foregroundStyle(.secondary).lineLimit(typeSize.isAccessibilitySize ? nil : 2)
                    .frame(minHeight: typeSize.isAccessibilitySize ? 0 : 32, alignment: .topLeading)
                Divider()
                HStack(spacing: 6) {
                    TraderPortrait(identity: listing.seller.identityIndex, size: 24)
                    Text(GameText.string("npc.name.\(listing.seller.identityIndex % 10)", locale: locale)).font(.caption2.weight(.semibold)).foregroundStyle(.primary)
                    Spacer(minLength: 0)
                }
                Text(listing.createdAt, style: .relative).font(.caption2).foregroundStyle(.secondary)
                if !listing.available {
                    Text(GameText.string(lifecycle?.closureReason?.key ?? "listing.unavailable", locale: locale)).font(.caption.weight(.bold)).foregroundStyle(.secondary)
                }
            }.padding(.horizontal, 3)
        }
        .padding(10)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(.primary.opacity(0.10), lineWidth: 1))
        .background(RoundedRectangle(cornerRadius: 24).fill(GameStyle.ink.opacity(0.15)).offset(y: 4))
    }
}

struct TradeContinuationPrompt: View {
    @Environment(\.locale) private var locale
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
                        Text(offer.amount.formatted(locale: locale)).font(.system(.title2, design: .rounded, weight: .heavy)).foregroundStyle(.primary)
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
