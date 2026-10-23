import Foundation

/// A career business, separate from collections and from the weekly competition.
enum ShopStyle: String, Codable, CaseIterable {
    case bargains, tested, collector
    var key: String { "shop.style.\(rawValue)" }
    var detailKey: String { "shop.style.\(rawValue).detail" }
    var symbol: String {
        switch self { case .bargains: "tag.fill"; case .tested: "checkmark.shield.fill"; case .collector: "sparkles" }
    }
}
struct TraderShop: Codable, Equatable {
    var name: String?
    var style: ShopStyle = .bargains
    var windowLevel = 0
    var featured: Set<ListingID> = []
    var completedSales: Set<ListingID> = []
    var invested = Money.zero
    var isOpen: Bool { name != nil }
    var capacity: Int { isOpen ? 1 + windowLevel : 0 }
}

enum ShopEngine {
    static let openingCost = Money(minorUnits: 15_000)
    static func eligible(_ state: GameSnapshot) -> Bool {
        state.playerListings.filter { $0.status == .sold && ($0.saleKind == nil || $0.saleKind == .market || $0.saleKind == .client) }.count >= 3
    }
    static func open(name: String, style: ShopStyle, state: GameSnapshot) throws -> GameSnapshot {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !state.shop.isOpen, eligible(state), (1...24).contains(name.count),
              !name.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) else { throw TradingError.unavailable }
        guard state.player.cash >= openingCost else { throw TradingError.insufficientCash }
        var next = state
        next.player.cash = try state.player.cash.subtracting(openingCost)
        next.shop.name = name; next.shop.style = style; next.shop.invested = openingCost
        return next
    }
    static func expansionCost(_ shop: TraderShop) -> Money? {
        guard shop.isOpen, (0..<4).contains(shop.windowLevel) else { return nil }
        return Money(minorUnits: Int64(shop.windowLevel + 1) * 20_000)
    }
    static func expand(state: GameSnapshot) throws -> GameSnapshot {
        guard let cost = expansionCost(state.shop), state.shop.completedSales.count >= (state.shop.windowLevel + 1) * 2 else { throw TradingError.unavailable }
        guard state.player.cash >= cost else { throw TradingError.insufficientCash }
        var next = state
        next.player.cash = try state.player.cash.subtracting(cost)
        next.shop.invested = try state.shop.invested.adding(cost)
        next.shop.windowLevel += 1
        return next
    }
    static func changeStyle(_ style: ShopStyle, state: GameSnapshot) throws -> GameSnapshot {
        guard state.shop.isOpen, state.shop.featured.isEmpty else { throw TradingError.unavailable }
        var next = state; next.shop.style = style; return next
    }
    /// Eligibility reads only earned inspection facts, never unrevealed faults.
    static func fits(_ listing: PlayerListing, state: GameSnapshot, definitions: [ItemDefinition]) -> Bool {
        guard listing.status == .active, let item = state.player.inventory.first(where: { $0.id == listing.itemID }),
              let definition = definitions.first(where: { $0.id == item.definitionID }) else { return false }
        switch state.shop.style {
        case .bargains:
            guard let estimate = try? InspectionEngine().estimatedValue(item: item, definition: definition, marketBasisPoints: state.marketMultiplier(for: definition)) else { return false }
            return listing.askingPrice <= estimate
        case .tested: return item.professionallyInspected && item.knownActiveDefects.isEmpty
        case .collector: return definition.category == .retro
        }
    }
    static func toggle(_ id: ListingID, state: GameSnapshot, definitions: [ItemDefinition]) throws -> GameSnapshot {
        guard state.shop.isOpen else { throw TradingError.unavailable }
        var next = state
        if next.shop.featured.remove(id) != nil { return next }
        guard next.shop.featured.count < next.shop.capacity,
              let listing = state.playerListings.first(where: { $0.id == id }), fits(listing, state: state, definitions: definitions) else { throw TradingError.unavailable }
        next.shop.featured.insert(id)
        return next
    }
    static func audience(for listing: PlayerListing, state: GameSnapshot, definitions: [ItemDefinition]) -> [BuyerArchetype]? {
        guard state.shop.featured.contains(listing.id), fits(listing, state: state, definitions: definitions) else { return nil }
        return switch state.shop.style {
        case .bargains: [.bargainHunter, .impatient, .impatient, .cautious]
        case .tested: [.cautious, .cautious, .impatient]
        case .collector: [.collector, .collector, .cautious]
        }
    }
    static func delayFactor(for listing: PlayerListing, state: GameSnapshot, definitions: [ItemDefinition]) -> Double {
        guard audience(for: listing, state: state, definitions: definitions) != nil else { return 1 }
        return switch state.shop.style { case .bargains: 0.7; case .tested: 1; case .collector: 1.3 }
    }
    static func recordSale(_ id: ListingID, state: inout GameSnapshot) {
        guard state.shop.featured.remove(id) != nil else { return }
        state.shop.completedSales.insert(id)
    }
    static func refresh(_ state: inout GameSnapshot) {
        let active = Set(state.playerListings.filter { $0.status == .active }.map(\.id))
        state.shop.featured.formIntersection(active)
    }
    static func validate(_ state: GameSnapshot) throws {
        let shop = state.shop
        guard (0...4).contains(shop.windowLevel), shop.invested >= .zero,
              shop.name.map({ (1...24).contains($0.count) && !$0.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) }) ?? true,
              shop.featured.count <= shop.capacity,
              shop.featured.isSubset(of: Set(state.playerListings.filter { $0.status == .active }.map(\.id))),
              shop.completedSales.isSubset(of: Set(state.playerListings.filter { $0.status == .sold }.map(\.id))),
              shop.isOpen || shop == TraderShop() else { throw SaveError.invalidSave }
        if shop.isOpen {
            let expected = openingCost.minorUnits + Int64(shop.windowLevel * (shop.windowLevel + 1) / 2) * 20_000
            guard shop.invested.minorUnits == expected else { throw SaveError.invalidSave }
        }
    }
}

extension GameStore {
    func openShop(name: String, style: ShopStyle) throws { try commit(ShopEngine.open(name: name, style: style, state: snapshot)) }
    func expandShop() throws { try commit(ShopEngine.expand(state: snapshot)) }
    func changeShopStyle(_ style: ShopStyle) throws { try commit(ShopEngine.changeStyle(style, state: snapshot)) }
    func toggleShopWindow(_ id: ListingID) throws { try commit(ShopEngine.toggle(id, state: snapshot, definitions: definitions)) }
}
