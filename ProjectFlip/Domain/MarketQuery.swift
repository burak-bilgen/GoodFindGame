import Foundation

/// Public listing facts only: search and filters never inspect hidden condition or defects.
struct MarketQuery {
    var search = ""
    var category: ItemCategory?
    var minimumPrice: Money?
    var maximumPrice: Money?
    var watchedOnly = false
    var newestFirst = true

    func results(in state: GameSnapshot, definitions: [ItemDefinition], locale: Locale) -> [MarketplaceListing] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        let byID = Dictionary(uniqueKeysWithValues: definitions.map { ($0.id, $0) })
        return state.market.filter { listing in
            guard let definition = byID[listing.item.definitionID],
                  watchedOnly ? state.watchedListingIDs.contains(listing.id) : listing.available,
                  category == nil || definition.category == category,
                  minimumPrice.map({ listing.askingPrice >= $0 }) ?? true,
                  maximumPrice.map({ listing.askingPrice <= $0 }) ?? true else { return false }
            return query.isEmpty || definition.name.range(of: query, options: [.caseInsensitive, .diacriticInsensitive], locale: locale) != nil
        }.sorted {
            if $0.createdAt == $1.createdAt { return $0.id.rawValue < $1.id.rawValue }
            return newestFirst ? $0.createdAt > $1.createdAt : $0.createdAt < $1.createdAt
        }
    }

    static func priceBound(_ text: String, locale: Locale) throws -> Money? {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty { return nil }
        // A filter can include zero; transaction amounts deliberately cannot.
        if ["0", "0\(locale.decimalSeparator ?? ".")0", "0\(locale.decimalSeparator ?? ".")00"].contains(value) { return .zero }
        return try Money.parse(value, locale: locale)
    }
}
