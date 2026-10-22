import Foundation

/// Selects a small, diverse feed from the full catalog. Item definitions remain independent
/// of feed slots: existing saved item IDs and hidden truth never change when content expands.
enum MarketCatalog {
    // Photo-less products stay defined for old saves but are paused for new listings.
    // Deferred: furniture-3...9 (bookshelf, desk, armchair, office chair, cabinet, table, stool)
    // and everyday-0...9 (bags, suitcase, bicycle, pushchair, tools, skates, trolley).
    static func active(_ definitions: [ItemDefinition]) -> [ItemDefinition] {
        definitions.filter { ProductPhoto.asset(identity: $0.id, symbol: $0.artSymbol) != nil }
    }
    static func starterFeed(from definitions: [ItemDefinition]) -> [ItemDefinition] {
        let definitions = active(definitions)
        let selected = Array(definitions.filter { $0.category == .gaming }.prefix(5))
            + Array(definitions.filter { $0.category == .cameras }.prefix(3))
            + Array(definitions.filter { $0.category == .retro }.prefix(2))
        let used = Set(selected.map(\.id))
        let familiar = selected + definitions.filter { !used.contains($0.id) }.prefix(max(0, 10 - selected.count))
        // Keep the established introductory slots stable, while showing ordinary
        // household stock on a new save rather than hiding it behind a refill.
        return familiar + [ItemCategory.home, .furniture, .everyday].flatMap { category in
            Array(definitions.filter { $0.category == category }.prefix(2))
        }
    }

    static func liveFeed(from definitions: [ItemDefinition], count: Int, seed: UInt64) -> [ItemDefinition] {
        let definitions = active(definitions)
        let categories = ItemCategory.allCases.filter { category in definitions.contains { $0.category == category } }
        guard count > 0, !categories.isEmpty else { return [] }
        let categoryOffset = Int(seed % UInt64(categories.count))
        let ordered = Array(categories[categoryOffset...]) + Array(categories[..<categoryOffset])
        var pools = ordered.map { category in
            let items = definitions.filter { $0.category == category }
            let offset = Int(seed % UInt64(items.count))
            return Array(items[offset...]) + Array(items[..<offset])
        }
        var selected: [ItemDefinition] = []
        while selected.count < min(count, definitions.count) {
            var added = false
            for index in pools.indices where selected.count < count && !pools[index].isEmpty {
                selected.append(pools[index].removeFirst())
                added = true
            }
            if !added { break }
        }
        return selected
    }
}
