import Foundation

/// Selects a small, diverse feed from the full catalog. Item definitions remain independent
/// of feed slots: existing saved item IDs and hidden truth never change when content expands.
enum MarketCatalog {
    static func starterFeed(from definitions: [ItemDefinition]) -> [ItemDefinition] {
        let selected = Array(definitions.filter { $0.category == .gaming }.prefix(5))
            + Array(definitions.filter { $0.category == .cameras }.prefix(3))
            + Array(definitions.filter { $0.category == .retro }.prefix(2))
        let used = Set(selected.map(\.id))
        return selected + definitions.filter { !used.contains($0.id) }.prefix(max(0, 10 - selected.count))
    }

    static func liveFeed(from definitions: [ItemDefinition], count: Int, seed: UInt64) -> [ItemDefinition] {
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
