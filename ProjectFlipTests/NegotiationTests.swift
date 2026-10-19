import Foundation
import Testing
@testable import ProjectFlip

struct NegotiationTests {
    @Test func deterministicAcceptanceAndFatigue() throws {
        let listing = try ListingGenerator().generate(definitions: SeedContent.load().items, seed: 42, now: .distantPast)[0]
        let current = NegotiationState(listingID: listing.id, patience: listing.seller.patience)
        let accepted = try NegotiationEngine().offer(listing.askingPrice, modifier: .none, listing: listing, current: current, reputation: 50)
        #expect(accepted.agreedPrice == listing.askingPrice)
        #expect(try accepted == NegotiationEngine().offer(listing.askingPrice, modifier: .none, listing: listing, current: current, reputation: 50))
        var lowball = current
        for _ in 0..<4 where !lowball.closed {
            lowball = try NegotiationEngine().offer(Money(minorUnits: 1), modifier: .none, listing: listing, current: lowball, reputation: 50)
        }
        #expect(lowball.closed)
        #expect(throws: TradingError.self) { try NegotiationEngine().offer(.zero, modifier: .none, listing: listing, current: current, reputation: 50) }
    }

    @Test func decimalInputDoesNotAcceptJunkOrOverflow() throws {
        #expect(try Money.parse("120,25", locale: Locale(identifier: "tr_TR")) == Money(minorUnits: 12025))
        #expect(try Money.parse("120.25", locale: Locale(identifier: "en_US")) == Money(minorUnits: 12025))
        for input in ["12junk", "0", "-2", "1.234", "9223372036854775807", "1,2.3"] {
            #expect(throws: TradingError.self) { try Money.parse(input, locale: Locale(identifier: "en_US")) }
        }
    }

    @Test func additiveSaveMigration() throws {
        let state = try GameSnapshot.fresh(definitions: SeedContent.load().items)
        var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(state)) as? [String: Any])
        json.removeValue(forKey: "conversations")
        let restored = try JSONDecoder().decode(GameSnapshot.self, from: JSONSerialization.data(withJSONObject: json))
        #expect(restored.conversations.isEmpty)
        #expect(restored.market == state.market)
    }
}
