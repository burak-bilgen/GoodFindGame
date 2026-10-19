import Foundation
import Testing
@testable import ProjectFlip

struct TimedActionTests {
    let now = Date(timeIntervalSince1970: 50_000)

    @Test func sellerReplyAndDeliveryAreActuallyDeferredAndReserveCapacity() throws {
        let definitions = try SeedContent.load().items
        let actions = SimulationActions(timing: .debug)
        let resolver = EventResolver(timing: .debug)
        var state = try GameSnapshot.fresh(definitions: definitions)
        state.player.inventoryCapacity = 1
        let listing = state.market[0]
        state = try actions.offer(listingID: listing.id, amount: listing.askingPrice, modifier: .none, state: state, now: now)
        #expect(state.conversations[0].agreedPrice == nil)
        #expect(state.conversations[0].pendingReplyEventID != nil)
        #expect(state.conversations[0].offers[0].status == .pending)
        #expect(throws: TradingError.self) { try actions.offer(listingID: listing.id, amount: listing.askingPrice, modifier: .none, state: state, now: now) }
        state = try resolver.resolve(state, now: now.addingTimeInterval(5), definitions: definitions).state
        #expect(state.conversations[0].agreedPrice == listing.askingPrice)
        let cash = state.player.cash
        state = try actions.purchase(listingID: listing.id, state: state, now: now.addingTimeInterval(5))
        #expect(state.player.inventory.isEmpty)
        #expect(state.shipments.count == 1)
        #expect(try state.player.cash == cash.subtracting(listing.askingPrice))
        let second = state.market[1]
        state.conversations.append(NegotiationState(listingID: second.id, patience: second.seller.patience, agreedPrice: second.askingPrice))
        #expect(throws: TradingError.self) { try actions.purchase(listingID: second.id, state: state, now: now.addingTimeInterval(5)) }
        state = try resolver.resolve(state, now: now.addingTimeInterval(10), definitions: definitions).state
        #expect(state.player.inventory.map(\.id) == [listing.item.id])
        #expect(state.shipments[0].status == .completed)
    }

    @Test func professionalInspectionBooksCostOnceAndRevealsOnlyAtCompletion() throws {
        let definitions = try SeedContent.load().items
        let original = try ResaleTests.inspectedState()
        let item = original.player.inventory[0]
        let state = try SimulationActions(timing: .debug).inspect(itemID: item.id, professionally: true, state: original, now: now, definitions: definitions)
        #expect(!state.player.inventory[0].professionallyInspected)
        #expect(state.player.inventory[0].revealedDefects == item.revealedDefects)
        #expect(state.inspectionJobs[0].status == .pending)
        #expect(throws: TradingError.self) { try SimulationActions(timing: .debug).inspect(itemID: item.id, professionally: true, state: state, now: now, definitions: definitions) }
        let completed = try EventResolver(timing: .debug).resolve(state, now: now.addingTimeInterval(10), definitions: definitions).state
        #expect(completed.player.inventory[0].professionallyInspected)
        #expect(completed.player.cash == state.player.cash)
        #expect(try completed.player.cash == original.player.cash.subtracting(InspectionEngine().professionalCost))
    }

    @Test func buyerArrivalIsPersistedAndPriceChangesCancelItsOldOutcome() throws {
        let definitions = try SeedContent.load().items
        let original = try ResaleTests.inspectedState()
        let actions = SimulationActions(timing: .debug)
        var listed = try actions.publish(itemID: original.player.inventory[0].id, askingPrice: Money(minorUnits: 280_000), state: original, definitions: definitions, now: now)
        let listing = try #require(listed.playerListings.first)
        #expect(listing.offers.isEmpty)
        let eventID = try #require(listed.events.first?.id)
        listed = try actions.changePrice(listingID: listing.id, amount: Money(minorUnits: 200_000), state: listed, definitions: definitions, now: now)
        #expect(listed.events.first(where: { $0.id == eventID })?.status == .cancelled)
        #expect(listed.events.filter { $0.status == .pending && $0.payload.generatesBuyerInterest }.count == 1)
        let delivered = try EventResolver(timing: .debug).resolve(listed, now: now.addingTimeInterval(10), definitions: definitions).state
        #expect(delivered.playerListings[0].offers.count == 1)
        #expect(try #require(delivered.playerListings[0].offers.first).amount <= Money(minorUnits: 200_000))
    }

    @MainActor @Test func launchCatchesUpAndRetainsReturnReportUntilAcknowledged() throws {
        let definitions = try SeedContent.load().items
        var state = try GameSnapshot.fresh(definitions: definitions)
        let item = state.market[0].item
        state.lastKnownWallClock = now
        state.lastSimulationAt = now
        state.shipments = [Shipment(id: "delivery", item: item, arrivesAt: now.addingTimeInterval(10))]
        try state.enqueue(.shipmentArrived(shipmentID: "delivery"), createdAt: now, resolveAt: now.addingTimeInterval(10))
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let repository = SaveRepository(url: root.appendingPathComponent("save.json"))
        try repository.save(state)
        let waiting = try GameStore(repository: repository, definitions: definitions, timing: .debug, now: now)
        #expect(waiting.previousTradeCount(with: state.market[0].seller.id) == 1)
        let store = try GameStore(repository: repository, definitions: definitions, timing: .debug, now: now.addingTimeInterval(90))
        #expect(store.snapshot.player.inventory.map(\.id) == [item.id])
        #expect(store.snapshot.awayReport.map(\.kind) == [.shipment])
        let reopened = try GameStore(repository: repository, definitions: definitions, timing: .debug, now: now.addingTimeInterval(91))
        #expect(reopened.snapshot.awayReport.count == 1)
        try reopened.acknowledgeAwayReport()
        #expect(try repository.load()?.awayReport.isEmpty == true)
    }

    @MainActor @Test func idlePollingAvoidsWritesAndDeadlineProjectionHandlesClockOffset() throws {
        let definitions = try SeedContent.load().items
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = try GameStore(repository: SaveRepository(url: root.appendingPathComponent("save.json")), definitions: definitions, now: now)
        let original = store.snapshot
        try store.processDueEvents(now: now.addingTimeInterval(1))
        #expect(store.snapshot == original)
        var shifted = original
        shifted.lastSimulationAt = now.addingTimeInterval(86_400)
        try store.commit(shifted)
        #expect(store.projectedDeadline(now.addingTimeInterval(86_410), now: now) == now.addingTimeInterval(10))
    }
}
