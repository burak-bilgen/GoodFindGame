import Foundation
import Testing
@testable import ProjectFlip

struct EverydayCatalogTests {
    @Test func householdStockIsVisibleAndMeasurementsNeverInventBodyElectronics() throws {
        let definitions = try SeedContent.load().items
        let state = try GameSnapshot.fresh(definitions: definitions)
        #expect(definitions.count == 80)
        #expect(ItemCategory.allCases.count == 6)
        #expect(state.market.contains { $0.item.definitionID == "furniture-0" })
        for definition in definitions where [.home, .furniture, .everyday].contains(definition.category) {
            let item = ItemInstance(id: ItemID("test-\(definition.id)"), definitionID: definition.id, condition: 65, hiddenDefects: definition.possibleDefects)
            let facts = ItemFacts.generate(for: item, definition: definition)
            try facts.validate()
            #expect(!facts.values.contains { [.batteryHealth, .shutterCount, .sensor, .region].contains($0.key) })
            for language in ["en", "tr"] {
                #expect(definition.displayName(locale: Locale(identifier: language)) != "…")
                for defect in definition.possibleDefects { #expect(GameText.string(defect.key, locale: Locale(identifier: language)) != "…") }
            }
        }
    }
    @Test func sellerWordingVariesWithoutRerollingItemOrPrice() throws {
        let definitions = try SeedContent.load().items
        let now = Date.now
        let first = try ListingGenerator().generate(definitions: definitions, seed: 232, now: now, starterFriendly: false, variedSellers: true)
        let second = try ListingGenerator().generate(definitions: definitions, seed: 232, now: now, starterFriendly: false, variedSellers: true)
        #expect(first == second)
        #expect(Set(first.map(\.descriptionIntent)).count >= 12)
        for language in ["en", "tr"] {
            for listing in first { #expect(GameText.string(listing.descriptionIntent, locale: Locale(identifier: language)) != "…") }
        }
    }
}
