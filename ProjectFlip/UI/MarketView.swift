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
    @State private var clientOnly = false
    private var clientBrief: ClientEngine.Brief? { ClientEngine.activeBrief(in: store.snapshot) }

    private var query: MarketQuery? {
        do {
            let minimum = try MarketQuery.priceBound(minimumPrice, locale: locale, market: market)
            let maximum = try MarketQuery.priceBound(maximumPrice, locale: locale, market: market)
            if let minimum, let maximum, minimum > maximum { return nil }
            return MarketQuery(search: search, category: category, minimumPrice: minimum, maximumPrice: maximum,
                               watchedOnly: watchedOnly, newestFirst: newestFirst,
                               modelIDs: clientOnly ? clientBrief?.request.models : nil)
        } catch { return nil }
    }
    private var listings: [MarketplaceListing] {
        query?.results(in: store.snapshot, definitions: store.definitions, locale: locale) ?? []
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                TradingDeskHeader(store: store)
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").foregroundStyle(GameStyle.gain).accessibilityHidden(true)
                    TextField("market.search", text: $search, prompt: Text("market.search").foregroundStyle(GameStyle.secondaryText)).textInputAutocapitalization(.never).autocorrectionDisabled()
                        .accessibilityIdentifier("marketSearch")
                }.padding(14).background(GameStyle.panel, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(GameStyle.line.opacity(0.55), lineWidth: 0.75))
                if store.snapshot.economyMigrationNotice || store.snapshot.sharedMarketMigrationNotice {
                    NavigationLink { MarketSettingsView(store: store) } label: {
                        GameMenuRow(titleKey: "region.migrationTitle", symbol: "info.circle.fill")
                    }.buttonStyle(.plain).accessibilityIdentifier("economyMigrationNotice")
                }
                if store.competitionPeriod == nil && (store.snapshot.player.cash < RecoveryEngine.capitalFloor || store.snapshot.recovery.itemID != nil) {
                    NavigationLink { RecoveryDeskView(store: store) } label: { GameMenuRow(titleKey: "recovery.title", symbol: "arrow.uturn.up.circle.fill") }.buttonStyle(.plain).accessibilityIdentifier("marketRecovery")
                }
                OpenTradesView(store: store)
                if let brief = clientBrief {
                    let name = GameText.string("client.\(brief.client.id).name.\(market.region.rawValue)", locale: locale)
                    Button { clientOnly.toggle() } label: {
                        Label(GameText.format(clientOnly ? "clients.filterActive" : "clients.filter", locale: locale, name), systemImage: "scope")
                            .font(.subheadline.bold()).frame(minHeight: 44)
                    }.buttonStyle(.bordered).tint(clientOnly ? GameStyle.amber : GameStyle.gain)
                        .accessibilityIdentifier("clientHuntFilter").accessibilityAddTraits(clientOnly ? .isSelected : [])
                    if clientOnly {
                        if let cap = brief.request.maximumPayment {
                            Text(GameText.format("clients.budget", locale: locale, cap.formatted(locale: locale, market: market))).font(.caption.bold()).foregroundStyle(GameStyle.amber)
                        }
                        Text("clients.filterCaution").font(.caption).foregroundStyle(GameStyle.secondaryText)
                    }
                }
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
                            category = nil; minimumPrice = ""; maximumPrice = ""; search = ""; newestFirst = true; watchedOnly = false; clientOnly = false
                        }
                    }
                }.padding(.horizontal, 4)
                if query == nil {
                    Text("market.invalidPriceRange").foregroundStyle(GameStyle.loss)
                } else if listings.isEmpty && !watchedOnly && !store.snapshot.market.contains(where: \.available),
                          let refresh = store.snapshot.events.first(where: { $0.status == .pending && $0.payload == .marketRefresh }) {
                    DeadlineView(store: store, target: refresh.resolveAt, titleKey: "market.nextRefresh")
                } else if listings.isEmpty {
                    ContentUnavailableView {
                        Label(clientOnly ? "clients.noModels" : watchedOnly ? "market.watchlistEmpty" : "market.noResults", systemImage: clientOnly ? "scope" : watchedOnly ? "bookmark" : "magnifyingglass")
                    } description: {
                        if clientOnly { Text(store.snapshot.playerListings.contains { $0.status == .sold } ? "clients.noModelsHint" : "clients.firstSaleHint").accessibilityIdentifier("clientNoModelsHint") }
                    }.accessibilityElement(children: .contain).accessibilityIdentifier("marketEmptyState")
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
        .onChange(of: store.snapshot.clients.active) { _, _ in clientOnly = false }
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
        VStack(alignment: .leading, spacing: 0) {
            if typeSize.isAccessibilitySize {
                HStack(alignment: .top, spacing: 14) {
                    productPhoto.frame(width: 88, height: 88)
                    headline
                }.padding(16)
                details.padding(.horizontal, 16).padding(.bottom, 16)
            } else {
                productPhoto
                VStack(alignment: .leading, spacing: 10) {
                    headline
                    details
                }.padding(14)
            }
        }
        .background(GameStyle.panel, in: RoundedRectangle(cornerRadius: 22))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(GameStyle.line.opacity(0.4), lineWidth: 0.75))
        .gameEntrance()
    }

    private var productPhoto: some View {
        DeviceArt(symbol: definition.artSymbol, identity: definition.id, appearance: .advertised(listing))
            .aspectRatio(1, contentMode: .fit)
            .overlay(alignment: .topTrailing) {
                if watched {
                    Image(systemName: "bookmark.fill").font(.caption).foregroundStyle(GameStyle.ink)
                        .padding(8).background(GameStyle.amber, in: Circle()).padding(8)
                        .accessibilityLabel(Text("market.watched"))
                }
            }
    }

    private var headline: some View {
        VStack(alignment: .leading, spacing: 7) {
            if let requiredCareer { Label(GameText.string(requiredCareer.key, locale: locale), systemImage: "lock.fill").font(.caption2.bold()).foregroundStyle(GameStyle.amber) }
            Text(GameText.string("category.\(definition.category.rawValue)", locale: locale))
                .font(.caption2.weight(.bold)).foregroundStyle(GameStyle.category(definition.category))
                .lineLimit(typeSize.isAccessibilitySize ? nil : 1)
            Text(definition.displayName(locale: locale)).font(.system(.headline, design: .default, weight: .semibold))
                .foregroundStyle(.primary).lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: typeSize.isAccessibilitySize ? 0 : 42, alignment: .topLeading)
            Text(listing.askingPrice.formatted(locale: locale, market: market))
                .font(.system(.title3, design: .default, weight: .semibold)).monospacedDigit().foregroundStyle(GameStyle.paper)
                .lineLimit(1).minimumScaleFactor(0.65)
                .contentTransition(.numericText()).animation(reduceMotion ? nil : .easeOut(duration: 0.3), value: listing.askingPrice)
            if lifecycle?.priceDroppedAt != nil {
                Label("listing.priceDrop", systemImage: "arrow.down.right").font(.caption2.bold()).foregroundStyle(GameStyle.gain)
                if let old = lifecycle?.initialAskingPrice { Text(old.formatted(locale: locale, market: market)).strikethrough().font(.caption2).foregroundStyle(GameStyle.secondaryText) }
            }
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(GameText.string(listing.descriptionIntent, locale: locale))
                .font(.caption).foregroundStyle(GameStyle.secondaryText).lineLimit(typeSize.isAccessibilitySize ? 3 : 2)
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
        }
    }
}
