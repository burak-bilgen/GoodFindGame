import SwiftUI

struct MarketView: View {
    let store: GameStore
    @Environment(\.locale) private var locale
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
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("market.heading").font(.largeTitle.bold())
                    Text("market.subtitle").font(.subheadline).foregroundStyle(.secondary)
                    HStack {
                        Text("wallet.cash")
                        Spacer()
                        Text(store.snapshot.player.cash.formatted(locale: locale)).monospacedDigit().bold().contentTransition(.numericText())
                    }.padding(.top, 8)
                }.padding(.vertical, 10)
            }
            Section {
                Toggle("market.watchedOnly", isOn: $watchedOnly).accessibilityIdentifier("watchedOnly")
                Button { filtersExpanded.toggle() } label: {
                    HStack {
                        Text("market.filters")
                        Spacer()
                        Image(systemName: filtersExpanded ? "chevron.up" : "chevron.down").accessibilityHidden(true)
                    }
                }
                .accessibilityIdentifier("marketFilters")
                .accessibilityValue(Text(filtersExpanded ? "market.expanded" : "market.collapsed"))
                if filtersExpanded {
                    Picker("market.category", selection: $category) {
                        Text("market.allCategories").tag(Optional<ItemCategory>.none)
                        ForEach(ItemCategory.allCases, id: \.self) { value in
                            Text(GameText.string("category.\(value.rawValue)", locale: locale)).tag(Optional(value))
                        }
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("market.minimumPrice").font(.caption).foregroundStyle(.secondary)
                        TextField("market.minimumPrice", text: $minimumPrice).keyboardType(.decimalPad).focused($priceInputFocused)
                            .accessibilityIdentifier("minimumPrice")
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("market.maximumPrice").font(.caption).foregroundStyle(.secondary)
                        TextField("market.maximumPrice", text: $maximumPrice).keyboardType(.decimalPad).focused($priceInputFocused)
                            .accessibilityIdentifier("maximumPrice")
                    }
                    Toggle("market.newest", isOn: $newestFirst)
                    Button("market.clearFilters") {
                        category = nil; minimumPrice = ""; maximumPrice = ""; search = ""; newestFirst = true; watchedOnly = false
                    }
                }
            }
            Section {
                if query == nil {
                    Text("market.invalidPriceRange").foregroundStyle(Color("LossColor"))
                } else if listings.isEmpty {
                    ContentUnavailableView(watchedOnly ? "market.watchlistEmpty" : "market.noResults", systemImage: watchedOnly ? "bookmark" : "magnifyingglass")
                }
                ForEach(listings) { listing in
                    if let definition = store.definition(for: listing.item) {
                        NavigationLink {
                            ListingDetailView(store: store, listingID: listing.id)
                        } label: {
                            ListingCard(listing: listing, definition: definition, watched: store.snapshot.watchedListingIDs.contains(listing.id))
                        }
                        .accessibilityIdentifier("listing.\(listing.id.rawValue)")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("market.title")
        .toolbar {
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
    @Environment(\.locale) private var locale
    private var nameKey: String { "npc.name.\(listing.seller.identityIndex % 10)" }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            DeviceArt(symbol: definition.artSymbol).frame(height: 130)
            HStack(alignment: .top) {
                Text(definition.name).font(.headline)
                Spacer()
                if watched { Image(systemName: "bookmark.fill").accessibilityLabel(Text("market.watched")) }
            }
            if !listing.available { Text("listing.unavailable").font(.subheadline.bold()).foregroundStyle(.secondary) }
            Text(listing.askingPrice.formatted(locale: locale)).font(.title2.bold()).foregroundStyle(.primary)
            HStack {
                Text(GameText.string(nameKey, locale: locale))
                Spacer()
                Text(listing.createdAt, style: .relative)
            }.font(.caption).foregroundStyle(.secondary)
            Text("seller.rating \((Decimal(listing.seller.ratingTenths) / 10).formatted(.number.locale(locale)))").font(.caption)
            Text("seller.trades \(listing.seller.tradeCount)").font(.caption)
            Text(GameText.string("npc.city.\(listing.seller.identityIndex % 10)", locale: locale)).font(.caption).foregroundStyle(.secondary)
            Text("listing.hint.inspect").font(.caption).foregroundStyle(.secondary)
        }.padding(.vertical, 8)
    }
}

/// Original geometric placeholder device art; no third-party product silhouettes or photos.
struct DeviceArt: View {
    let symbol: String
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20).fill(Color(red: 0.85, green: 0.91, blue: 0.90))
            RoundedRectangle(cornerRadius: 24).fill(Color(red: 0.16, green: 0.26, blue: 0.32))
                .frame(width: 160, height: 90).rotationEffect(.degrees(-7))
            Image(systemName: symbol).font(.system(size: 42)).foregroundStyle(.white)
        }.accessibilityHidden(true)
    }
}
