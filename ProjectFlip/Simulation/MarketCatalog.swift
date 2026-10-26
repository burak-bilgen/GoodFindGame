import Foundation

/// Selects a small, diverse feed from the full catalog. Item definitions remain independent
/// of feed slots: existing saved item IDs and hidden truth never change when content expands.
enum MarketCatalog {
    // New stock requires a packaged photograph; all current catalog products are covered.
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

    static func liveFeed(from definitions: [ItemDefinition], count: Int, seed: UInt64, requestedModels: Set<String> = []) -> [ItemDefinition] {
        let definitions = active(definitions)
        let categories = ItemCategory.allCases.filter { category in definitions.contains { $0.category == category } }
        guard count > 0, !categories.isEmpty else { return [] }
        let requested = definitions.filter { requestedModels.contains($0.id) }
        if !requested.isEmpty {
            // Reserve at most one ordinary arrival slot every third batch. Advance
            // the ordinary stream contiguously on other batches, so client leads
            // cannot permanently replace the same categories in the rotation.
            let ordinarySeed = seed - seed / 3
            if seed % 3 == 0 {
                var random = SeededRandom(seed: SeededRandom.seed(for: "client-lead-\(seed)"))
                let lead = requested[random.integer(in: 0...(requested.count - 1))]
                return [lead] + liveFeed(from: definitions.filter { $0.id != lead.id }, count: count - 1, seed: ordinarySeed)
            }
            return liveFeed(from: definitions, count: count, seed: ordinarySeed)
        }
        let categoryOffset = Int(seed % UInt64(categories.count))
        let ordered = Array(categories[categoryOffset...]) + Array(categories[..<categoryOffset])
        var pools = ordered.map { category in
            let items = definitions.filter { $0.category == category }
            // Split phase from cycle. A coprime stride reaches every model even
            // when this category appears only once per category rotation; phase
            // changes also preserve diversity in multi-item refills.
            let stride = coprimeStride(after: categories.count, count: items.count)
            let cycle = (seed / UInt64(categories.count)) % UInt64(items.count)
            let salt = SeededRandom.seed(for: category.rawValue) % UInt64(items.count)
            let offset = Int((seed % UInt64(categories.count) + cycle * UInt64(stride) + salt) % UInt64(items.count))
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

    private static func coprimeStride(after categoryCount: Int, count: Int) -> Int {
        func gcd(_ a: Int, _ b: Int) -> Int {
            var a = a, b = b
            while b != 0 { (a, b) = (b, a % b) }
            return a
        }
        var stride = categoryCount + 1
        while gcd(stride, count) != 1 { stride += 1 }
        return stride
    }

}
