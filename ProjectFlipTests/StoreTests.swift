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
        #expect(store.snapshot.market.filter(\.available).count == 10)
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
    #endif
}
