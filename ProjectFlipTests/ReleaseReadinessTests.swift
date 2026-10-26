import Foundation
import Testing
@testable import ProjectFlip

struct ReleaseReadinessTests {
    @Test func packagedPublisherContactAndOfflineSwitchArePresent() throws {
        #expect(Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String == "Pazlume")
        for language in ["en", "tr", "de", "fr", "es", "it"] {
            #expect(GameText.string("notifications.title", locale: Locale(identifier: language)) == "Pazlume")
        }
        #expect(Bundle.main.object(forInfoDictionaryKey: "SupportEmail") as? String == "bilgenburak@outlook.com")
        #expect(Bundle.main.object(forInfoDictionaryKey: "OnlineCompetitionEnabled") as? Bool == false)
        let contact = try #require(PublisherLinks.email)
        #expect(contact.scheme == "mailto" && contact.path == "bilgenburak@outlook.com")
    }

    @Test func salesQueueShowsOnlyActiveWorkAndPrioritizesActionableOffers() throws {
        var state = try BuyerTests.offeredState()
        var sold = state.playerListings[0]; sold.status = .sold
        var waiting = PlayerListing(id: ListingID("newer-waiting"), itemID: ItemID("waiting-stock"), askingPrice: Money(minorUnits: 5_000), createdAt: .distantFuture, status: .active, views: 0, favorites: 0)
        waiting.offers = []
        state.playerListings.append(waiting)
        #expect(state.activeSales.map(\.id) == [state.playerListings[0].id, waiting.id])
        state.playerListings[0] = sold
        #expect(state.activeSales.map(\.id) == [waiting.id])
    }

    @Test func everyCareerStageUnlocksActualCatalogProducts() throws {
        let active = MarketCatalog.active(try SeedContent.load().items)
        let grouped = Dictionary(grouping: active, by: CareerEngine.requiredTier)
        for tier in CareerTier.allCases { #expect(!(grouped[tier] ?? []).isEmpty) }
        print("CAREER ACCESS: " + CareerTier.allCases.map { "\($0): \(grouped[$0, default: []].count)" }.joined(separator: ", "))
        #expect(grouped[.newcomer, default: []].count < active.count * 3 / 4)
    }

    @Test func oldCareersKeepPreviouslyAccessibleProducts() throws {
        let definitions = try SeedContent.load().items
        var state = try GameSnapshot.fresh(definitions: definitions)
        state.career.creditedItems = Set((0..<8).map { ItemID("old-\($0)") })
        state.inspectionKnowledge.learn(8, in: .cameras)
        let expensive = try #require(definitions.first { $0.id == "cameras-5" })
        #expect(!CareerEngine.canAccess(expensive, state: state))
        var raw = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(state)) as? [String: Any])
        var career = try #require(raw["career"] as? [String: Any]); career.removeValue(forKey: "accessVersion"); raw["career"] = career
        let loaded = try JSONDecoder().decode(GameSnapshot.self, from: JSONSerialization.data(withJSONObject: raw))
        #expect(CareerEngine.canAccess(expensive, state: loaded))
        #expect(loaded.player == state.player)
        #expect(loaded.career.accessVersion == 2)
    }

    @Test func purchaseUsesTheProvidedCatalogInsteadOfReadingAnotherDefinition() throws {
        let definitions = try SeedContent.load().items
        var state = try GameSnapshot.fresh(definitions: definitions)
        let listing = state.market[0]
        var talk = NegotiationState(listingID: listing.id, patience: 100); talk.agreedPrice = listing.askingPrice
        state.conversations = [talk]
        #expect(throws: TradingError.self) { try SimulationActions(timing: .instant, definitions: []).purchase(listingID: listing.id, state: state, now: .now) }
        let bought = try SimulationActions(timing: .instant, definitions: definitions).purchase(listingID: listing.id, state: state, now: .now)
        #expect(bought.shipments.count == 1)
    }
}
