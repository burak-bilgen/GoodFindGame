import Foundation
import Testing
@testable import ProjectFlip

struct MarketQueryTests {
    @Test func publicFiltersCombineAndWatchedUnavailableItemsRemainVisible() throws {
        let definitions = try SeedContent.load().items
        var state = try GameSnapshot.fresh(definitions: definitions)
        let first = state.market[0]
        let locale = Locale(identifier: "tr_TR")
        state.watchedListingIDs = [first.id]
        let exact = MarketQuery(search: "  \(definitions[0].model.lowercased())  ", category: .gaming,
                                minimumPrice: first.askingPrice, maximumPrice: first.askingPrice, watchedOnly: true)
        #expect(exact.results(in: state, definitions: definitions, locale: locale).map(\.id) == [first.id])
        state.market[0].available = false
        #expect(exact.results(in: state, definitions: definitions, locale: locale).map(\.id) == [first.id])
        #expect(!MarketQuery().results(in: state, definitions: definitions, locale: locale).contains { $0.id == first.id })
        #expect(MarketQuery(search: "no-such-model").results(in: state, definitions: definitions, locale: locale).isEmpty)
        let tooLow = try first.askingPrice.subtracting(Money(minorUnits: 1))
        #expect(MarketQuery(maximumPrice: tooLow, watchedOnly: true).results(in: state, definitions: definitions, locale: locale).isEmpty)
        #expect(try MarketQuery.priceBound("12,50", locale: locale) == Money(minorUnits: 1250))
        #expect(try MarketQuery.priceBound("0,00", locale: locale) == .zero)
        #expect(try MarketQuery.priceBound(" ", locale: locale) == nil)
        #expect(throws: TradingError.self) { try MarketQuery.priceBound("12.50", locale: locale) }
    }

    @MainActor @Test func watchChangesPersistAndLegacySavesDefaultToEmpty() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let repository = SaveRepository(url: root.appendingPathComponent("save.json"))
        let store = try GameStore(repository: repository, definitions: SeedContent.load().items, timing: .instant)
        let id = store.snapshot.market[0].id
        try store.toggleWatch(listingID: id)
        #expect(try repository.load()?.watchedListingIDs == [id])
        let restored = try GameStore(repository: repository, definitions: store.definitions, timing: .instant)
        #expect(restored.snapshot.watchedListingIDs == [id])
        try restored.toggleWatch(listingID: id)
        #expect(try repository.load()?.watchedListingIDs.isEmpty == true)
        #expect(throws: TradingError.self) { try restored.toggleWatch(listingID: ListingID("missing")) }
        var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(store.snapshot)) as? [String: Any])
        json.removeValue(forKey: "watchedListingIDs")
        let legacy = try JSONDecoder().decode(GameSnapshot.self, from: JSONSerialization.data(withJSONObject: json))
        #expect(legacy.watchedListingIDs.isEmpty)
    }
}
