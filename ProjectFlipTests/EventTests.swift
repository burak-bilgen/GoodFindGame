import Foundation
import Testing
@testable import ProjectFlip

struct EventTests {
    let now = Date(timeIntervalSince1970: 10_000)

    @Test func ordersEventsByTimestampThenSequenceAndResolvesOnce() throws {
        let definitions = try SeedContent.load().items
        var state = try GameSnapshot.fresh(definitions: definitions)
        let first = state.market[0].item, second = state.market[1].item
        state.shipments = [Shipment(id: "a", item: first, arrivesAt: now.addingTimeInterval(20)), Shipment(id: "b", item: second, arrivesAt: now.addingTimeInterval(10))]
        try state.enqueue(.shipmentArrived(shipmentID: "a"), createdAt: now, resolveAt: now.addingTimeInterval(20))
        try state.enqueue(.shipmentArrived(shipmentID: "b"), createdAt: now, resolveAt: now.addingTimeInterval(10))
        let result = try EventResolver().resolve(state, now: now.addingTimeInterval(30), definitions: definitions)
        #expect(result.state.player.inventory.map(\.id) == [second.id, first.id])
        #expect(result.outcomes.map(\.targetID) == ["b", "a"])
        let again = try EventResolver().resolve(result.state, now: now.addingTimeInterval(30), definitions: definitions)
        #expect(again.state == result.state)
        #expect(again.outcomes.isEmpty)
    }

    @Test func pastClockNeverReversesProgressOrChangesHiddenTruth() throws {
        let definitions = try SeedContent.load().items
        var state = try GameSnapshot.fresh(definitions: definitions)
        state.lastKnownWallClock = now; state.lastSimulationAt = now
        let result = try EventResolver().resolve(state, now: now.addingTimeInterval(-3600), definitions: definitions)
        #expect(result.clock.movedBackwards)
        #expect(result.clock.elapsed == 0)
        #expect(result.state.lastSimulationAt == now)
        #expect(result.state.market == state.market)
    }

    @Test func sellerReplyAndItsExpiryResolveInOneCatchUp() throws {
        let definitions = try SeedContent.load().items
        var state = try GameSnapshot.fresh(definitions: definitions)
        let listing = state.market[0]
        var pending = NegotiationState(listingID: listing.id, patience: listing.seller.patience)
        let reply = try NegotiationEngine().offer(listing.askingPrice, modifier: .none, listing: listing, current: pending, reputation: 50)
        let event = try state.enqueue(.sellerReply(listingID: listing.id, reply: reply, expiresAt: now.addingTimeInterval(30)), createdAt: now, resolveAt: now.addingTimeInterval(10))
        pending.pendingReplyEventID = event.id
        state.conversations = [pending]
        let result = try EventResolver().resolve(state, now: now.addingTimeInterval(90), definitions: definitions)
        #expect(result.outcomes.map(\.kind) == [.sellerReply, .offerExpired])
        #expect(result.state.conversations[0].closed)
        #expect(result.state.conversations[0].agreedPrice == nil)
    }

    @Test func longAbsenceBoundsGeneratedOffersWithoutCreatingCash() throws {
        let definitions = try SeedContent.load().items
        var state = try ResaleTests.inspectedState()
        state = try ResaleEngine().create(itemID: state.player.inventory[0].id, askingPrice: Money(minorUnits: 280_000), state: state, definitions: definitions, now: now)
        let cash = state.player.cash
        state.lastKnownWallClock = now
        state.lastSimulationAt = now
        let resolver = EventResolver(timing: .debug)
        try resolver.scheduleBuyer(listingID: state.playerListings[0].id, state: &state, definitions: definitions, now: now)
        let result = try resolver.resolve(state, now: now.addingTimeInterval(365 * 86_400), definitions: definitions)
        #expect(result.state.playerListings[0].offers.count <= SimulationTiming.debug.buyerArrivalsPerCatchUp)
        #expect(result.state.player.cash == cash)
        #expect(result.state.playerListings[0].status == .expired)
        #expect(!result.state.events.contains { $0.status == .pending && $0.payload.generatesBuyerInterest })
        #expect(result.clock.largeForwardJump)
    }

    @Test func pendingQueueRoundTripAndOldSaveMigration() throws {
        let definitions = try SeedContent.load().items
        var state = try GameSnapshot.fresh(definitions: definitions)
        let item = state.market[0].item
        state.shipments = [Shipment(id: "a", item: item, arrivesAt: now.addingTimeInterval(20))]
        try state.enqueue(.shipmentArrived(shipmentID: "a"), createdAt: now, resolveAt: now.addingTimeInterval(20))
        let data = try JSONEncoder().encode(state)
        #expect(try JSONDecoder().decode(GameSnapshot.self, from: data) == state)
        var old = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        for key in ["simulationID", "nextEventSequence", "events", "shipments", "inspectionJobs", "lastKnownWallClock", "lastSimulationAt"] { old.removeValue(forKey: key) }
        let migrated = try JSONDecoder().decode(GameSnapshot.self, from: JSONSerialization.data(withJSONObject: old))
        #expect(migrated.events.isEmpty)
        #expect(migrated.market == state.market)
        #expect(migrated.simulationID == "legacy-42")
    }
    @Test func inspectionCompletionNeverChargesTwiceAndCancellationIsCoherent() throws {
        let definitions = try SeedContent.load().items
        var state = try ResaleTests.inspectedState()
        let item = state.player.inventory[0]
        state.player.inventory[0].inspectionCost = Money(minorUnits: 15_000)
        state.inspectionJobs = [InspectionJob(id: "inspection", itemID: item.id, completesAt: now.addingTimeInterval(10), cost: Money(minorUnits: 15_000))]
        try state.enqueue(.inspectionCompleted(jobID: "inspection"), createdAt: now, resolveAt: now.addingTimeInterval(10))
        let result = try EventResolver().resolve(state, now: now.addingTimeInterval(20), definitions: definitions)
        #expect(result.state.player.cash == state.player.cash)
        #expect(result.state.player.inventory[0].inspectionCost == Money(minorUnits: 15_000))
        #expect(result.state.player.inventory[0].professionallyInspected)
        #expect(result.state.inspectionJobs[0].status == .completed)
        state.player.inventory = []
        let cancelled = try EventResolver().resolve(state, now: now.addingTimeInterval(20), definitions: definitions)
        #expect(cancelled.state.inspectionJobs[0].status == .cancelled)
        #expect(cancelled.outcomes.isEmpty)
    }

    @Test func clockResumesAfterCorrectionInsteadOfFreezingForOldDate() throws {
        let definitions = try SeedContent.load().items
        var state = try GameSnapshot.fresh(definitions: definitions)
        state.lastKnownWallClock = now
        state.lastSimulationAt = now
        let backward = now.addingTimeInterval(-86_400)
        let corrected = try EventResolver().resolve(state, now: backward, definitions: definitions)
        #expect(corrected.state.lastKnownWallClock == backward)
        #expect(corrected.state.lastSimulationAt == now)
        let resumed = try EventResolver().resolve(corrected.state, now: backward.addingTimeInterval(10), definitions: definitions)
        #expect(resumed.clock.elapsed == 10)
        #expect(resumed.state.lastSimulationAt == now.addingTimeInterval(10))
    }

    @Test func historyPruningKeepsEveryPendingEventAndNeverReusesSequence() throws {
        let definitions = try SeedContent.load().items
        var state = try GameSnapshot.fresh(definitions: definitions)
        for index in 0..<220 {
            try state.enqueue(.shipmentArrived(shipmentID: "obsolete-\(index)"), createdAt: now, resolveAt: now)
        }
        state.shipments = [Shipment(id: "future", item: state.market[0].item, arrivesAt: now.addingTimeInterval(100))]
        let future = try state.enqueue(.shipmentArrived(shipmentID: "future"), createdAt: now, resolveAt: now.addingTimeInterval(100))
        var result = try EventResolver().resolve(state, now: now.addingTimeInterval(1), definitions: definitions).state
        #expect(result.events.filter { $0.status != .pending }.count == 200)
        #expect(result.events.contains { $0.id == future.id && $0.status == .pending })
        let appended = try result.enqueue(.shipmentArrived(shipmentID: "another"), createdAt: now, resolveAt: now.addingTimeInterval(200))
        #expect(appended.sequence == 222)
    }

    @Test func unavailableListingCannotLeaveAConversationWaitingForever() throws {
        let definitions = try SeedContent.load().items
        var state = try GameSnapshot.fresh(definitions: definitions)
        let listing = state.market[0]
        var conversation = NegotiationState(listingID: listing.id, patience: listing.seller.patience)
        let reply = try NegotiationEngine().offer(listing.askingPrice, modifier: .none, listing: listing, current: conversation, reputation: 50)
        let event = try state.enqueue(.sellerReply(listingID: listing.id, reply: reply, expiresAt: now.addingTimeInterval(100)), createdAt: now, resolveAt: now.addingTimeInterval(10))
        conversation.pendingReplyEventID = event.id
        state.conversations = [conversation]
        state.market[0].available = false
        let result = try EventResolver().resolve(state, now: now.addingTimeInterval(20), definitions: definitions)
        #expect(result.outcomes.isEmpty)
        #expect(result.state.conversations[0].closed)
        #expect(result.state.conversations[0].pendingReplyEventID == nil)
        #expect(result.state.events[0].status == .cancelled)
    }

}
