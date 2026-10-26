import Foundation
import Testing
@testable import ProjectFlip

struct ClientDiscoveryTests {
    let now = Date(timeIntervalSince1970: 800_000)
    @Test func activeRequestReservesOneModelSlotWithoutDuplicatesOrExtraStock() throws {
        let definitions = try SeedContent.load().items
        let wanted: Set<String> = ["everyday-4", "everyday-5", "everyday-9"]
        for seed: UInt64 in 0..<60 where seed % 3 == 0 {
            for count in [1, 10] {
                let selected = MarketCatalog.liveFeed(from: definitions, count: count, seed: seed, requestedModels: wanted)
                #expect(selected.count == count && Set(selected.map(\.id)).count == count)
                #expect(wanted.contains(try #require(selected.first).id))
            }
        }
        #expect(MarketCatalog.liveFeed(from: definitions, count: 0, seed: 3, requestedModels: wanted).isEmpty)
    }

    @Test func requestLeadsDoNotStarveOrdinaryCategoriesOrBypassLockedModels() throws {
        let definitions = try SeedContent.load().items
        let wanted: Set<String> = ["everyday-4", "everyday-5", "everyday-9"]
        var seen = Set<String>()
        for seed: UInt64 in 0..<6000 {
            seen.formUnion(MarketCatalog.liveFeed(from: definitions, count: 1, seed: seed, requestedModels: wanted).map(\.id))
        }
        #expect(seen == Set(MarketCatalog.active(definitions).map(\.id)))
        let state = try GameSnapshot.fresh(definitions: definitions, now: now)
        let accessible = definitions.filter { CareerEngine.canAccess($0, state: state) }
        let locked = Set(definitions.filter { !CareerEngine.canAccess($0, state: state) }.map(\.id))
        #expect(!locked.isEmpty)
        for seed: UInt64 in 0..<30 {
            let ordinary = MarketCatalog.liveFeed(from: accessible, count: 10, seed: seed)
            let requested = MarketCatalog.liveFeed(from: accessible, count: 10, seed: seed, requestedModels: locked)
            #expect(requested.map(\.id) == ordinary.map(\.id))
        }
    }

    @Test func leadUsesNormalConditionPricingAndSellerGenerationWithoutCompletingTheRequest() throws {
        let definitions = try SeedContent.load().items
        let offered = try BuyerTests.offeredState()
        var state = try BuyerEngine().accept(listingID: offered.playerListings[0].id, state: offered, now: now)
        state.clients.active = "mira"
        state.market = []; state.marketListingStates = []; state.events = []
        state.generation = 2; state.marketFeedStartedAt = now.addingTimeInterval(-90)
        let cash = state.player.cash
        let client = try #require(ClientEngine.activeBrief(in: state))
        let accessible = definitions.filter { CareerEngine.canAccess($0, state: state) }
        #expect(accessible.contains { client.request.models.contains($0.id) })
        try MarketFeedEngine(timing: .production).replenish(&state, now: now, definitions: definitions)
        #expect(state.market.count == MarketFeedEngine.targetCount)
        #expect(client.request.models.contains(state.market[0].item.definitionID))
        let selected = state.market.compactMap { listing in definitions.first { $0.id == listing.item.definitionID } }
        let normal = try ListingGenerator().generate(definitions: selected, seed: state.generation, now: now,
                                                     market: state, starterFriendly: false, variedSellers: true)
        #expect(state.market == normal)
        #expect(state.market.allSatisfy { !$0.item.inspected && !$0.item.professionallyInspected })
        #expect(state.player.cash == cash && state.player.inventory.isEmpty)
        #expect(state.clients.completed["mira", default: 0] == 0)
    }

    @Test func fullMarketKeepsItsStockAndTheRequestCannotForceAReroll() throws {
        let definitions = try SeedContent.load().items
        var state = try GameSnapshot.fresh(definitions: definitions, now: now)
        state.clients.active = "mira"
        state.marketFeedStartedAt = now.addingTimeInterval(-90)
        state.generation = 2
        let stock = state.market
        let cash = state.player.cash
        #expect(stock.filter(\.available).count == MarketFeedEngine.maximumBrowsingCount)
        try MarketFeedEngine(timing: .production).replenish(&state, now: now, definitions: definitions)
        #expect(state.market == stock && state.generation == 2 && state.player.cash == cash)
    }

    @Test func everyClientRequestReferencesExistingModelsAndHasAnOptionAtItsAdvertisedCareerTier() throws {
        let definitions = try SeedContent.load().items
        let ids = Set(definitions.map(\.id))
        for client in ClientDefinition.all {
            for request in client.requests {
                #expect(request.models.isSubset(of: ids))
                #expect(definitions.contains { request.models.contains($0.id) && CareerEngine.requiredTier(for: $0).rawValue <= request.career.rawValue })
            }
        }
    }

}
