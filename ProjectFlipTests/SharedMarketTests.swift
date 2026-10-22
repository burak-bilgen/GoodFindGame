import Foundation
import Testing
@testable import ProjectFlip

struct SharedMarketTests {
    @Test func currencyAndLanguageNeverChangeListingsOrValue() throws {
        let definitions = try SeedContent.load().items
        let now = Date.now
        let usd = try GameSnapshot.fresh(definitions: definitions, now: now, marketConfiguration: .us)
        let lira = try GameSnapshot.fresh(definitions: definitions, now: now, marketConfiguration: .turkey)
        #expect(usd.market == lira.market)
        #expect(usd.player == lira.player)
        #expect(MarketConfiguration.initial(locale: Locale(identifier: "tr_TR")).region == .unitedStates)
        #expect(MarketConfiguration.initial(locale: Locale(identifier: "tr_TR")).currency == .tryLira)
        for index in 0..<10 {
            #expect(GameText.marketPerson("name", index: index, market: .us, locale: Locale(identifier: "tr")) == GameText.marketPerson("name", index: index, market: .turkey, locale: Locale(identifier: "tr")))
            #expect(GameText.marketPerson("city", index: index, market: .us, locale: Locale(identifier: "en")) != "…")
        }
        #expect(GameText.marketPerson("name", index: 0, market: .us, locale: Locale(identifier: "tr")) == "Deniz")
        #expect(GameText.marketPerson("city", index: 0, market: .us, locale: Locale(identifier: "tr")) == "Eski Çarşı")
    }
    @Test func regionalSaveMigrationPreservesEveryFinancialCommitmentAndBacksUpOnce() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let repo = SaveRepository(url: root.appendingPathComponent("career.json"))
        var old = try PurchaseTests.agreedState()
        old.marketConfiguration = MarketConfiguration(version: 1, region: .turkey, currency: .tryLira)
        old.player.cash = Money(minorUnits: 777_777)
        try repo.save(old)
        let original = try Data(contentsOf: repo.url)
        let loaded = try repo.load()
        let migrated = try #require(loaded)
        #expect(migrated.player == old.player)
        #expect(migrated.market == old.market)
        #expect(migrated.conversations == old.conversations)
        #expect(migrated.playerListings == old.playerListings)
        #expect(migrated.marketConfiguration == .turkey) // TRY display, common market.
        #expect(migrated.sharedMarketMigrationNotice)
        let backup = repo.url.appendingPathExtension("pre-shared-market-v3.json")
        #expect(try Data(contentsOf: backup) == original)
        try repo.save(migrated)
        #expect(try repo.load() == migrated)
        #expect(try Data(contentsOf: backup) == original)
    }
}
