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
        #expect(first[0].item.hiddenDefects.isEmpty)
        #expect(Set(first.map(\.id)).count == definitions.count)
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

}
