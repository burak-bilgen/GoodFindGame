import Foundation
import Testing
@testable import ProjectFlip

struct EconomyCredibilityTests {
    @Test func ordinaryMonitorCannotHaveLuxuryCameraValue() throws {
        let monitor = try #require(SeedContent.load().items.first { $0.id == "gaming-3" })
        let item = ItemInstance(id: ItemID("monitor-regression"), definitionID: monitor.id, condition: 100, hiddenDefects: [])
        let value = try PricingEngine.fairValue(of: item, definition: monitor)
        #expect(value <= Money(minorUnits: 30_000), "An ordinary used monitor must remain below $300 canonical, not $5,200.")
    }
}

extension EconomyCredibilityTests {
    @Test func displayCurrencyAndLanguageCannotRepriceSharedMarket() throws {
        let value = Money(minorUnits: 30_000)
        #expect(try MarketConfiguration.turkey.display(value) == Money(minorUnits: 1_200_000))
        #expect(try Money.parse("12000", locale: Locale(identifier: "en_US"), market: .turkey) == value)
        #expect(value.formatted(locale: Locale(identifier: "en_US"), market: .turkey).contains("12,000"))
        #expect(value.formatted(locale: Locale(identifier: "tr_TR"), market: .us).contains("300"))
        #expect(ItemCategory.allCases.allSatisfy { MarketConfiguration.turkey.multiplier(for: $0) == MarketConfiguration.us.multiplier(for: $0) })
        #expect(throws: MoneyError.self) { try MarketConfiguration.turkey.display(Money(minorUnits: .max)) }
        #expect(throws: TradingError.self) { try Money.parse("0.01", locale: Locale(identifier: "en_US"), market: .turkey) }
    }

    @Test func sharedEconomyStaysPlausibleAcrossTenThousandListingsInBothCurrencies() throws {
        let definitions = try SeedContent.load().items
        var checked = 0
        for config in [MarketConfiguration.us, .turkey] {
            for seed in 0..<100 {
                let state = try GameSnapshot.fresh(definitions: definitions, marketConfiguration: config)
                let listings = try ListingGenerator().generate(definitions: definitions, seed: UInt64(seed), now: .distantPast, market: state, starterFriendly: false)
                for (listing, definition) in zip(listings, definitions) {
                    #expect(definition.valueTier?.contains(definition.baseValue) == true)
                    let ceiling = try definition.baseValue.scaled(byBasisPoints: state.marketMultiplier(for: definition)).scaled(byBasisPoints: 17_000)
                    #expect(listing.askingPrice > .zero && listing.askingPrice <= ceiling)
                    #expect(listing.reservationPrice > .zero && listing.reservationPrice <= listing.askingPrice)
                    let displayed = try config.display(listing.askingPrice)
                    #expect(try config.canonical(displayed) == listing.askingPrice)
                    var owned = listing.item; owned.inspected = true
                    var saleState = state; saleState.player.inventory = [owned]
                    let fair = try PricingEngine.fairValue(of: owned, definition: definition, marketBasisPoints: state.marketMultiplier(for: definition))
                    saleState = try ResaleEngine().create(itemID: owned.id, askingPrice: fair, state: saleState, definitions: definitions, now: .distantPast)
                    saleState = try BuyerEngine().generateOffer(listingID: saleState.playerListings[0].id, state: saleState, definitions: definitions)
                    let offer = try #require(saleState.playerListings[0].offers.last)
                    #expect(offer.amount > .zero && offer.amount <= offer.willingness)
                    #expect(try offer.willingness <= fair.scaled(byBasisPoints: 15_000))
                    checked += 1
                }
            }
        }
        #expect(checked == 10_000)
        print("ECONOMY: 10,000 listings and buyer budgets checked across US/USD and Turkey/TRY")
    }

    @Test func legacyMigrationBacksUpAndRebasesEveryMoneyFieldOnce() throws {
        var state = try GameSnapshot.fresh(definitions: SeedContent.load().items)
        state.player.cash = Money(minorUnits: 2_000_000)
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let repo = SaveRepository(url: root.appendingPathComponent("save.json"))
        try repo.save(state)
        var raw = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: repo.url)) as? [String: Any])
        raw.removeValue(forKey: "marketConfiguration")
        let original = try JSONSerialization.data(withJSONObject: raw)
        try original.write(to: repo.url)
        let result = try repo.load()
        let loaded = try #require(result)
        #expect(loaded.player.cash == Money(minorUnits: 100_000))
        #expect(loaded.economyMigrationNotice)
        #expect(try Data(contentsOf: repo.url.appendingPathExtension("pre-economy-v2.json")) == original)
        try repo.save(loaded)
        #expect(try repo.load() == loaded)
        #expect(try JSONDecoder().decode(GameSnapshot.self, from: JSONEncoder().encode(loaded)).marketConfiguration == .us)
    }

    @Test func conditionCannotEscapeBoundsAndRepairCannotRepeat() throws {
        let definition = try SeedContent.load().items[3]
        for condition in [0, 25, 50, 75, 100] {
            let item = ItemInstance(id: ItemID("condition"), definitionID: definition.id, condition: condition, hiddenDefects: definition.possibleDefects)
            let value = try PricingEngine.fairValue(of: item, definition: definition)
            #expect(value > .zero && value <= definition.baseValue)
        }
        let invalid = ItemInstance(id: ItemID("invalid"), definitionID: definition.id, condition: -100, hiddenDefects: [])
        #expect(throws: TradingError.self) { try PricingEngine.fairValue(of: invalid, definition: definition) }
    }
}
