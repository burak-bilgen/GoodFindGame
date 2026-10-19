import Foundation
import Testing
@testable import ProjectFlip

struct ContentTests {
    @Test func launchCatalogCoversThreeCategoriesAndEveryLocalizedDefect() throws {
        let content = try SeedContent.load()
        #expect(content.items.count == 50)
        #expect(content.items.filter { $0.category == .gaming }.count == 20)
        #expect(content.items.filter { $0.category == .cameras }.count == 15)
        #expect(content.items.filter { $0.category == .retro }.count == 15)
        #expect(Defect.allCases.count == 24)
        #expect(Set(content.items.flatMap(\.possibleDefects)) == Set(Defect.allCases))
        for language in ["tr_TR", "en_US"] {
            let locale = Locale(identifier: language)
            for defect in Defect.allCases { #expect(GameText.string(defect.key, locale: locale) != "…") }
            for category in ItemCategory.allCases { #expect(GameText.string("category.\(category.rawValue)", locale: locale) != "…") }
        }
        let duplicate = SeedContent(items: content.items + [content.items[0]])
        #expect(throws: ContentError.self) { try duplicate.validate() }
        var mixed = content.items
        let original = mixed[0]
        mixed[0] = ItemDefinition(id: original.id, brand: original.brand, model: original.model, category: .gaming,
                                  baseValue: original.baseValue, possibleDefects: [.sensorDamage], artSymbol: original.artSymbol)
        #expect(throws: ContentError.self) { try SeedContent(items: mixed).validate() }
    }

    @Test func feedStaysSmallAndDiverseWhileLiveRotationReachesTheWholeCatalog() throws {
        let definitions = try SeedContent.load().items
        let fresh = try GameSnapshot.fresh(definitions: definitions)
        #expect(fresh.market.count == 10)
        #expect(fresh.market.prefix(5).map { $0.item.definitionID } == (0..<5).map { "gaming-\($0)" })
        #expect(fresh.market[0].askingPrice == Money(minorUnits: 237_728))
        let categories = Set(fresh.market.compactMap { listing in definitions.first { $0.id == listing.item.definitionID }?.category })
        #expect(categories == Set(ItemCategory.allCases))
        var encountered = Set<String>()
        for seed in 0..<60 {
            let selected = MarketCatalog.liveFeed(from: definitions, count: 10, seed: UInt64(seed))
            #expect(selected.count == 10 && Set(selected.map(\.id)).count == 10)
            #expect(Set(selected.map(\.category)) == Set(ItemCategory.allCases))
            encountered.formUnion(selected.map(\.id))
            let generated = try ListingGenerator().generate(definitions: selected, seed: UInt64(seed), now: .distantPast, starterFriendly: false)
            for listing in generated {
                let definition = try #require(selected.first { $0.id == listing.item.definitionID })
                #expect(listing.item.hiddenDefects.allSatisfy { $0.category == definition.category })
            }
        }
        #expect(encountered == Set(definitions.map(\.id)))
        #expect(MarketCatalog.liveFeed(from: [], count: 10, seed: 0).isEmpty)
    }

    @MainActor @Test func expandingCatalogNeverRemapsLegacyMarketSlotsOrHiddenTruth() throws {
        let definitions = try SeedContent.load().items
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        var legacy = try GameSnapshot.fresh(definitions: Array(definitions.prefix(10)))
        legacy.player.inventory = [ItemInstance(id: ItemID("legacy-headset"), definitionID: "gaming-4", condition: 65, hiddenDefects: [.noisyFan])]
        let repository = SaveRepository(url: root.appendingPathComponent("save.json"))
        try repository.save(legacy)
        let store = try GameStore(repository: repository, definitions: definitions, timing: .instant)
        #expect(store.snapshot.market == legacy.market)
        #expect(store.snapshot.market[5].item.definitionID == "gaming-5")
        #expect(store.snapshot.player.inventory == legacy.player.inventory)
        #expect(store.definition(for: store.snapshot.player.inventory[0])?.id == "gaming-4")
    }

    @Test func categoryDefectsHaveDifferentEconomicImpactWithoutLeakingIntoAnEstimate() throws {
        let definition = try #require(SeedContent.load().items.first { $0.id == "cameras-5" })
        let minor = ItemInstance(id: ItemID("minor"), definitionID: definition.id, condition: 100, hiddenDefects: [.cameraBatteryWear])
        let severe = ItemInstance(id: ItemID("severe"), definitionID: definition.id, condition: 100, hiddenDefects: [.sensorDamage])
        #expect(try PricingEngine.fairValue(of: severe, definition: definition) < PricingEngine.fairValue(of: minor, definition: definition))
        #expect(try InspectionEngine().estimatedValue(item: severe, definition: definition) == definition.baseValue)
        let damaged = ItemInstance(id: ItemID("damaged"), definitionID: definition.id, condition: 100,
                                   hiddenDefects: [.sensorDamage, .apertureStuck, .stabilizationFault])
        #expect(try PricingEngine.fairValue(of: damaged, definition: definition) == definition.baseValue.scaled(byBasisPoints: 2_000))
    }

    @Test func oldCalendarsGainNewScopesWithoutRerollingPastOrAlreadyPlannedMovements() throws {
        let definitions = try SeedContent.load().items
        let anchor = Date(timeIntervalSince1970: 100_000)
        let old = MarketCalendar(anchor: anchor, seed: 42, definitions: Array(definitions.prefix(10)))
        var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(old)) as? [String: Any])
        json.removeValue(forKey: "scopeEpochs")
        var migrated = try JSONDecoder().decode(MarketCalendar.self, from: JSONSerialization.data(withJSONObject: json))
        try migrated.includeNewContent(definitions, after: 2)
        try migrated.validate()
        #expect(migrated.scopeEpochs.count == 1 && migrated.scopeEpochs[0].firstCycle == 4)
        for index in 0...3 { #expect(try migrated.trend(at: index) == old.trend(at: index)) }
        #expect(migrated.scopeEpochs[0].models.count == 50)
        #expect(Set(migrated.scopeEpochs[0].categories) == Set(ItemCategory.allCases))
        var newCategories = Set<ItemCategory>()
        for index in 4..<104 {
            if case .category(let category) = try migrated.trend(at: index).scope { newCategories.insert(category) }
        }
        #expect(newCategories == Set(ItemCategory.allCases))
        let unchanged = migrated
        try migrated.includeNewContent(definitions, after: 2)
        #expect(migrated == unchanged)
        #expect(try JSONDecoder().decode(MarketCalendar.self, from: JSONEncoder().encode(migrated)) == migrated)
        var state = try GameSnapshot.fresh(definitions: definitions, now: anchor)
        state.marketCalendar = old; state.lastMarketCycle = 2
        let caughtUp = try EventResolver(timing: .instant).resolve(state, now: old.trend(at: 2).startsAt, definitions: definitions).state
        #expect(caughtUp.marketCalendar?.scopeEpochs == migrated.scopeEpochs)
    }

}
