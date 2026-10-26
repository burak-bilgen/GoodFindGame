import Foundation
import Testing
@testable import ProjectFlip

struct PurchaseTests {
    static func agreedState() throws -> GameSnapshot {
        var state = try GameSnapshot.fresh(definitions: SeedContent.load().items)
        let listing = state.market[0]
        state.conversations = [try NegotiationEngine().offer(listing.askingPrice, modifier: .none, listing: listing, current: NegotiationState(listingID: listing.id, patience: listing.seller.patience))]
        return state
    }

    @Test func purchasePreservesTruthAndCannotRepeat() throws {
        let state = try Self.agreedState()
        let next = try PurchaseEngine().buy(listingID: state.market[0].id, state: state, now: .distantPast)
        #expect(next.player.inventory.count == 1)
        #expect(next.player.inventory[0].hiddenDefects == state.market[0].item.hiddenDefects)
        #expect(try next.player.cash == state.player.cash.subtracting(state.market[0].askingPrice))
        #expect(throws: TradingError.self) { try PurchaseEngine().buy(listingID: state.market[0].id, state: next, now: .now) }
    }

    @Test func insufficientFundsAndCapacityCannotMutateState() throws {
        var state = try Self.agreedState()
        state.player.cash = .zero
        #expect(throws: TradingError.self) { try PurchaseEngine().buy(listingID: state.market[0].id, state: state, now: .now) }
        #expect(state.player.inventory.isEmpty)
        state.player.cash = Money(minorUnits: 2_000_000)
        state.player.inventoryCapacity = 0
        #expect(throws: TradingError.self) { try PurchaseEngine().buy(listingID: state.market[0].id, state: state, now: .now) }
    }
}

extension PurchaseTests {
    @Test func publicTradeReadCannotSeeHiddenTruthOrPrivateSellerFloor() throws {
        let state = try Self.agreedState()
        let original = state.market[0]
        let definition = try #require(SeedContent.load().items.first { $0.id == original.item.definitionID })
        let differentTruth = ItemInstance(id: original.item.id, definitionID: definition.id, condition: 10, hiddenDefects: [.drift, .storageFailure])
        let deceptive = MarketplaceListing(id: original.id, item: differentTruth, seller: original.seller, askingPrice: original.askingPrice,
                                           reservationPrice: Money(minorUnits: 1), claimedCondition: original.claimedCondition,
                                           descriptionIntent: original.descriptionIntent, createdAt: original.createdAt)
        let appraisal = try PublicTradeAppraisal(listing: original, disclosedDefects: [], price: original.askingPrice, definition: definition, knowledge: state.inspectionKnowledge)
        #expect(try appraisal == PublicTradeAppraisal(listing: deceptive, disclosedDefects: [], price: original.askingPrice, definition: definition, knowledge: state.inspectionKnowledge))
        let disclosed = try PublicTradeAppraisal(listing: deceptive, disclosedDefects: [.drift], price: original.askingPrice, definition: definition, knowledge: state.inspectionKnowledge)
        #expect(disclosed.estimate.upper < appraisal.estimate.upper)
        #expect(try disclosed.lowerMargin == disclosed.estimate.lower.subtracting(original.askingPrice))
        let lowerPrice = try original.askingPrice.scaled(byBasisPoints: 8_000)
        let negotiated = try PublicTradeAppraisal(listing: original, disclosedDefects: [], price: lowerPrice, definition: definition, knowledge: state.inspectionKnowledge)
        #expect(negotiated.estimate == appraisal.estimate)
        #expect(negotiated.lowerMargin > appraisal.lowerMargin)
    }
}
