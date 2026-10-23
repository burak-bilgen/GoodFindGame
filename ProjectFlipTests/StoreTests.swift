import Foundation
import Testing
@testable import ProjectFlip

struct StoreTests {
    @MainActor @Test func writeFailureDoesNotPublishUnsavedState() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = try GameStore(repository: SaveRepository(url: root.appendingPathComponent("save.json")), definitions: SeedContent.load().items)
        let original = store.snapshot
        try FileManager.default.removeItem(at: root)
        try Data("blocked directory".utf8).write(to: root)
        var changed = original
        changed.player.cash = .zero
        #expect(throws: (any Error).self) { try store.commit(changed) }
        #expect(store.snapshot == original)
    }

    #if DEBUG
    @MainActor @Test func debugToolsPersistAndRetireStaleNegotiations() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let repository = SaveRepository(url: root.appendingPathComponent("save.json"))
        let store = try GameStore(repository: repository, definitions: SeedContent.load().items)
        let listing = store.snapshot.market[0]
        try store.debugForceSellerResponse(listingID: listing.id)
        #expect(store.snapshot.conversations[0].counterPrice != nil)
        try store.debugAddCash()
        #expect(store.snapshot.player.cash > GameBalanceConfig.current.startingCash)
        try store.debugRegenerateMarket()
        #expect(store.snapshot.conversations[0].closed)
        #expect(store.snapshot.market.filter(\.available).count == MarketCatalog.starterFeed(from: store.definitions).count)
        #expect(try repository.load() == store.snapshot)
        try store.commit(BuyerTests.offeredState())
        #expect(store.previousTradeCount(with: store.snapshot.market[0].seller.id) == 1)
        try store.debugForceBuyerOffer()
        #expect(store.snapshot.playerListings[0].offers.count == 2)
        #expect(store.snapshot.playerListings[0].offers.last?.status == .pending)
        try store.commit(BuyerEngine().accept(listingID: store.snapshot.playerListings[0].id, state: store.snapshot, now: .now))
        #expect(store.previousTradeCount(with: store.snapshot.market[0].seller.id) == 1)
        try store.debugReset()
        #expect(store.snapshot.player.cash == GameBalanceConfig.current.startingCash)
        #expect(store.snapshot.conversations.isEmpty)
    }
    @MainActor @Test func debugTimeTravelCompletesWorkAndRealClockKeepsAdvancing() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let definitions = try SeedContent.load().items
        let now = Date.now
        var state = try GameSnapshot.fresh(definitions: definitions)
        state.lastKnownWallClock = now
        state.lastSimulationAt = now
        state.shipments = [Shipment(id: "debug-delivery", item: state.market[0].item, arrivesAt: now.addingTimeInterval(60))]
        try state.enqueue(.shipmentArrived(shipmentID: "debug-delivery"), createdAt: now, resolveAt: now.addingTimeInterval(60))
        let repository = SaveRepository(url: root.appendingPathComponent("save.json"))
        try repository.save(state)
        let store = try GameStore(repository: repository, definitions: definitions, now: now)
        try store.debugAdvanceTime(by: 30 * 60)
        #expect(store.snapshot.player.inventory.count == 1)
        #expect(store.snapshot.awayReport.map(\.kind) == [.shipment])
        let advanced = try #require(store.snapshot.lastSimulationAt)
        try store.processDueEvents(now: now.addingTimeInterval(2))
        #expect(store.snapshot.lastSimulationAt == advanced)
        try store.catchUp(now: now.addingTimeInterval(3))
        #expect(store.snapshot.lastSimulationAt == advanced.addingTimeInterval(1))
        #expect(throws: EventQueueError.self) { try store.debugAdvanceTime(by: -1) }
    }
    #endif
}
