import SwiftUI

struct ShopView: View {
    let store: GameStore
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market
    @State private var name = ""
    @FocusState private var editingName: Bool
    @State private var style = ShopStyle.bargains
    @State private var showStyle = false
    private var shop: TraderShop { store.snapshot.shop }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if shop.isOpen {
                    storefront
                    VStack(alignment: .leading, spacing: 10) {
                        Text(GameText.string(shop.style.key, locale: locale)).font(.title2.bold())
                        Text(GameText.string(shop.style.detailKey, locale: locale)).font(.subheadline)
                        Button("shop.changeStyle") { showStyle.toggle() }.buttonStyle(GameButton(secondary: true)).disabled(!shop.featured.isEmpty)
                        if !shop.featured.isEmpty { Text("shop.clearWindow").font(.caption).foregroundStyle(GameStyle.secondaryText) }
                        if showStyle && shop.featured.isEmpty {
                            ForEach(ShopStyle.allCases, id: \.self) { option in
                                Button { store.perform { try store.changeShopStyle(option) }; showStyle = false } label: {
                                    Label(GameText.string(option.key, locale: locale), systemImage: option.symbol)
                                }.buttonStyle(GameButton(secondary: true))
                            }
                        }
                    }.gameCard()
                    stock
                    expansion
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("shop.intro").font(.title3.bold())
                        Text("shop.openingStory").font(.subheadline)
                        if ShopEngine.eligible(store.snapshot) {
                            TextField("shop.name", text: $name).focused($editingName).onSubmit { editingName = false }.textFieldStyle(GamePriceFieldStyle()).submitLabel(.done).accessibilityIdentifier("shopName")
                                .onChange(of: name) { _, value in if value.count > 24 { name = String(value.prefix(24)) } }
                            ForEach(ShopStyle.allCases, id: \.self) { option in
                                Button { style = option } label: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Label(GameText.string(option.key, locale: locale), systemImage: style == option ? "checkmark.circle.fill" : option.symbol).font(.headline)
                                        Text(GameText.string(option.detailKey, locale: locale)).font(.caption)
                                    }.frame(maxWidth: .infinity, alignment: .leading).padding(12)
                                        .background(style == option ? GameStyle.amber.opacity(0.15) : GameStyle.ink, in: RoundedRectangle(cornerRadius: 12))
                                }.buttonStyle(.plain).accessibilityAddTraits(style == option ? .isSelected : [])
                            }
                            LabeledContent("shop.openingCost") { Text(ShopEngine.openingCost.formatted(locale: locale, market: market)) }
                            Button("shop.open") { store.perform { try store.openShop(name: name, style: style) } }.buttonStyle(GameButton())
                                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.snapshot.player.cash < ShopEngine.openingCost).accessibilityIdentifier("openShop")
                        } else { Text("shop.unlock").font(.subheadline).foregroundStyle(GameStyle.secondaryText) }
                    }.gameCard(accent: GameStyle.amber)
                }
                NavigationLink { SellingView(store: store) } label: { GameMenuRow(titleKey: "shop.onlineSales", symbol: "tag.fill") }.buttonStyle(.plain).accessibilityIdentifier("shopSales")
                NavigationLink { ClientBookView(store: store) } label: { GameMenuRow(titleKey: "clients.title", symbol: "person.2.fill") }.buttonStyle(.plain)
                Text("shop.offline").font(.caption).foregroundStyle(GameStyle.secondaryText)
            }.padding(16)
        }.gameScreen().navigationTitle("shop.title").navigationBarTitleDisplayMode(.inline)
    }
    private var storefront: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                Image(systemName: "storefront.fill").font(.largeTitle).foregroundStyle(GameStyle.amber).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 5) {
                    Text(shop.name ?? "").font(.system(.largeTitle, design: .rounded, weight: .black)).fixedSize(horizontal: false, vertical: true)
                    Text(GameText.format("shop.windowCount", locale: locale, shop.featured.count, shop.capacity)).font(.subheadline)
                }
            }
            ForEach(store.snapshot.playerListings.filter { shop.featured.contains($0.id) }) { listing in
                NavigationLink { SaleListingView(store: store, listingID: listing.id) } label: { saleRow(listing) }.buttonStyle(.plain)
            }
            if shop.featured.isEmpty { Text("shop.windowEmpty").foregroundStyle(GameStyle.secondaryText) }
            Text(GameText.format("shop.salesCount", locale: locale, shop.completedSales.count)).font(.headline).foregroundStyle(GameStyle.gain)
        }.gameCard(accent: GameStyle.amber)
    }
    private var stock: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("shop.chooseStock").font(.title2.bold())
            Text("shop.stockHint").font(.caption).foregroundStyle(GameStyle.secondaryText)
            let listings = store.snapshot.playerListings.filter { $0.status == .active }
            if listings.isEmpty {
                Text("shop.noStock")
                NavigationLink { InventoryView(store: store) } label: { Text("inventory.title") }.buttonStyle(GameButton(secondary: true))
            }
            ForEach(listings) { listing in
                VStack(alignment: .leading, spacing: 10) {
                    NavigationLink { SaleListingView(store: store, listingID: listing.id) } label: { saleRow(listing) }.buttonStyle(.plain)
                    let featured = shop.featured.contains(listing.id)
                    Button(featured ? "shop.remove" : "shop.feature") { store.perform { try store.toggleShopWindow(listing.id) } }
                        .buttonStyle(GameButton(secondary: true))
                        .disabled(!featured && (shop.featured.count >= shop.capacity || !ShopEngine.fits(listing, state: store.snapshot, definitions: store.definitions)))
                    if !ShopEngine.fits(listing, state: store.snapshot, definitions: store.definitions) { Text("shop.notFit").font(.caption).foregroundStyle(GameStyle.amber) }
                }.padding(.vertical, 8)
            }
        }.gameCard()
    }
    private func saleRow(_ listing: PlayerListing) -> some View {
        HStack(spacing: 12) {
            if let item = store.snapshot.player.inventory.first(where: { $0.id == listing.itemID }), let definition = store.definition(for: item) {
                DeviceArt(symbol: definition.artSymbol, identity: definition.id, appearance: .owned(item)).frame(width: 72, height: 72)
                VStack(alignment: .leading, spacing: 5) {
                    Text(definition.displayName(locale: locale)).font(.headline)
                    Text(listing.askingPrice.formatted(locale: locale, market: market)).bold()
                    if listing.offers.last?.status == .pending { Label("journey.offerWaiting", systemImage: "person.crop.circle.badge.clock").font(.caption) }
                }
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
    private var expansion: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("shop.growth").font(.title2.bold())
            LabeledContent("shop.invested") { Text(shop.invested.formatted(locale: locale, market: market)) }
            if let cost = ShopEngine.expansionCost(shop) {
                Text(GameText.format("shop.expandHint", locale: locale, (shop.windowLevel + 1) * 2)).font(.subheadline)
                Text(cost.formatted(locale: locale, market: market)).font(.title2.bold())
                Button("shop.expand") { store.perform { try store.expandShop() } }.buttonStyle(GameButton())
                    .disabled(shop.completedSales.count < (shop.windowLevel + 1) * 2 || store.snapshot.player.cash < cost).accessibilityIdentifier("expandShop")
            } else { Label("shop.fullyExpanded", systemImage: "checkmark.seal.fill") }
            Text("shop.capitalChoice").font(.caption).foregroundStyle(GameStyle.secondaryText)
        }.gameCard(accent: GameStyle.amber)
    }
}
