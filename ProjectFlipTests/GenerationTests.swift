import Foundation
import Testing
@testable import ProjectFlip

struct GenerationTests {
    @Test func sameSeedSameSnapshot() throws {
        let definitions = try SeedContent.load().items
        let generator = ListingGenerator()
        let now = Date(timeIntervalSince1970: 12345)
        let first = try generator.generate(definitions: definitions, seed: 42, now: now)
        #expect(try first == generator.generate(definitions: definitions, seed: 42, now: now))
        #expect(try first != generator.generate(definitions: definitions, seed: 43, now: now))
        #expect(first[0].item.hiddenDefects == [.damagedPort])
        #expect(Set(first.map(\.id)).count == definitions.count)
    }

    @Test func starterRevealsOneFairlySignaledFaultAndSupportsBothResaleChoices() throws {
        let definitions = try SeedContent.load().items
        var state = try PurchaseTests.agreedState()
        let listing = state.market[0]
        #expect(listing.descriptionIntent == "listing.description.starter")
        #expect(listing.item.revealedDefects.isEmpty)
        state = try PurchaseEngine().buy(listingID: listing.id, state: state, now: .distantPast)
        state = try InspectionEngine().inspect(itemID: listing.item.id, professionally: false, state: state)
        let item = state.player.inventory[0]
        #expect(item.revealedDefects == [.damagedPort])
        func settle(_ state: GameSnapshot) throws -> TradeRecord {
            let owned = try #require(state.player.inventory.first)
            let estimate = try InspectionEngine().estimatedValue(item: owned, definition: definitions[0])
            let listed = try ResaleEngine().create(itemID: owned.id, askingPrice: estimate, state: state, definitions: definitions, now: .distantPast)
            let offered = try BuyerEngine().generateOffer(listingID: listed.playerListings[0].id, state: listed, definitions: definitions)
            let sold = try BuyerEngine().accept(listingID: listed.playerListings[0].id, state: offered, now: .distantPast)
            return try TradeRecord(listing: sold.playerListings[0])
        }
        let asIs = try settle(state)
        let repaired = try settle(RepairEngine().repair(itemID: item.id, defect: .damagedPort, state: state, definitions: definitions))
        #expect(asIs.netProfit > .zero)
        #expect(repaired.netProfit > asIs.netProfit)
        #expect(repaired.repairCost > .zero)
    }

    @MainActor @Test func existingCleanStarterIsNeverReplacedByTheNewIntro() throws {
        let definitions = try SeedContent.load().items
        var saved = try GameSnapshot.fresh(definitions: definitions)
        let first = saved.market[0]
        let old = MarketplaceListing(id: first.id,
            item: ItemInstance(id: first.item.id, definitionID: first.item.definitionID, condition: 79, hiddenDefects: []),
            seller: first.seller, askingPrice: Money(minorUnits: 237_728), reservationPrice: Money(minorUnits: 200_000),
            claimedCondition: 79, descriptionIntent: "listing.description.uncertain", createdAt: first.createdAt)
        saved.market[0] = old
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let repository = SaveRepository(url: root.appendingPathComponent("save.json"))
        try repository.save(saved)
        let restored = try GameStore(repository: repository, definitions: definitions, timing: .instant)
        #expect(restored.snapshot.market[0] == old)
    }

    @Test func pricesContainRiskAndOpportunity() throws {
        let definitions = try SeedContent.load().items
        var overpriced = 0
        var underpriced = 0
        for seed in 0..<100 {
            for (listing, definition) in zip(try ListingGenerator().generate(definitions: definitions, seed: UInt64(seed), now: .distantPast), definitions) {
                let fair = try PricingEngine.fairValue(of: listing.item, definition: definition)
                if listing.askingPrice > fair { overpriced += 1 } else { underpriced += 1 }
                #expect(listing.askingPrice > .zero)
                #expect(listing.reservationPrice <= listing.askingPrice)
            }
        }
        #expect(overpriced > 100)
        #expect(underpriced > 100)
    }

    @Test func conditionDefectsAndTrendsAffectValue() throws {
        let definition = try SeedContent.load().items[0]
        var item = ItemInstance(id: ItemID("test"), definitionID: definition.id, condition: 80, hiddenDefects: [.drift])
        let before = try PricingEngine.fairValue(of: item, definition: definition)
        item.revealedDefects = [.drift]
        #expect(try before == PricingEngine.fairValue(of: item, definition: definition))
        #expect(try PricingEngine.fairValue(of: item, definition: definition, marketBasisPoints: 11_000) > before)
    }
    @Test func uninformedSellersCanDemandMoreThanFaultyItemIsWorth() throws {
        let definitions = try SeedContent.load().items
        var riskyMinimums = 0
        for seed in 0..<100 {
            let listings = try ListingGenerator().generate(definitions: definitions, seed: UInt64(seed), now: .distantPast)
            for (listing, definition) in zip(listings, definitions) where listing.seller.knowledge < 40 && !listing.item.hiddenDefects.isEmpty {
                if listing.reservationPrice > (try PricingEngine.fairValue(of: listing.item, definition: definition)) { riskyMinimums += 1 }
            }
        }
        #expect(riskyMinimums > 0)
    }

    @Test func liveStockIncludesGenuinelyWornObjectsWithoutChangingTheIntroduction() throws {
        let definition = try SeedContent.load().items[0]
        var scores: [Int] = []
        for seed in 0..<100 {
            scores.append(try ListingGenerator().generate(definitions: [definition], seed: UInt64(seed), now: .distantPast, starterFriendly: false, variedSellers: true)[0].item.condition)
        }
        #expect(scores.contains { $0 < 55 })
        #expect(scores.contains { $0 >= 90 })
        let first = try GameSnapshot.fresh(definitions: SeedContent.load().items).market[0]
        #expect(first.askingPrice == Money(minorUnits: 3_670))
    }

}
