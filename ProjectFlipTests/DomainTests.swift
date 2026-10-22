import Foundation
import Testing
@testable import ProjectFlip

struct DomainTests {
    @Test func exactMoneyAndOverflow() throws {
        let price = Money(minorUnits: 10_001)
        #expect(try price.scaled(byBasisPoints: 9_500) == Money(minorUnits: 9_500))
        #expect(try price.subtracting(Money(minorUnits: 1)) == Money(minorUnits: 10_000))
        #expect(throws: MoneyError.self) { try Money(minorUnits: .max).adding(Money(minorUnits: 1)) }
        #expect(throws: MoneyError.self) { try Money(minorUnits: .min).subtracting(Money(minorUnits: 1)) }
        #expect(throws: MoneyError.self) { try Money(minorUnits: .max).scaled(byBasisPoints: 10_000) }
    }

    @Test func seedAndHiddenTruthRoundTrip() throws {
        let seed = try SeedContent.load()
        #expect(seed.items.count == 80)
        let item = ItemInstance(id: ItemID("sample"), definitionID: seed.items[0].id, condition: 63, hiddenDefects: [.drift])
        let state = PlayerState(cash: Money(minorUnits: 2_000_000), inventory: [item])
        #expect(try JSONDecoder().decode(PlayerState.self, from: JSONEncoder().encode(state)) == state)
        #expect(state.inventory[0].revealedDefects.isEmpty)
        #expect(state.inventory[0].hiddenDefects == [.drift])
    }

    @Test func moneyFormatting() {
        let value = Money(minorUnits: 123_450)
        #expect(value.formatted(locale: Locale(identifier: "tr_TR")).contains("1.235"))
        #expect(value.formatted(locale: Locale(identifier: "en_US")).contains("1,235"))
        #expect(value.formatted(locale: Locale(identifier: "en_US")).contains("$"))
        #expect(value.formatted(locale: Locale(identifier: "en_GB")).contains("$"))
        #expect(value.formatted(locale: Locale(identifier: "tr_TR"), market: .turkey).contains("₺"))
        #expect(value.formatted(locale: Locale(identifier: "en_US"), signed: true).contains("+$"))
    }
}
