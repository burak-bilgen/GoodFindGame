import SwiftUI

struct MarketView: View {
    let store: GameStore
    @Environment(\.locale) private var locale
    @State private var gamingOnly = false
    @State private var newestFirst = true

    private var listings: [MarketplaceListing] {
        store.snapshot.market.filter { $0.available && (!gamingOnly || store.definition(for: $0.item)?.category == .gaming) }
            .sorted { newestFirst ? $0.createdAt > $1.createdAt : $0.createdAt < $1.createdAt }
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
                Toggle("category.gaming", isOn: $gamingOnly)
                Toggle("market.newest", isOn: $newestFirst)
            }
            Section {
                ForEach(listings) { listing in
                    if let definition = store.definition(for: listing.item) {
                        NavigationLink {
                            ListingDetailView(store: store, listingID: listing.id)
                        } label: {
                            ListingCard(listing: listing, definition: definition)
                        }
                        .accessibilityIdentifier("listing.\(listing.id.rawValue)")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("market.title")
    }
}

struct ListingCard: View {
    let listing: MarketplaceListing
    let definition: ItemDefinition
    @Environment(\.locale) private var locale
    private var nameKey: String { "npc.name.\(listing.seller.identityIndex % 10)" }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            DeviceArt(symbol: definition.artSymbol).frame(height: 130)
            Text(definition.name).font(.headline)
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
