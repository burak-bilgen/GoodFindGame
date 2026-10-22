import Foundation
import Testing
@testable import ProjectFlip

struct InboxOrderTests {
    @Test func legacyThreadsStayReadAndUrgentRepliesSortFirst() throws {
        var state = try GameSnapshot.fresh(definitions: SeedContent.load().items)
        var first = NegotiationState(listingID: state.market[0].id, patience: 50)
        first.append("seller.clean.0")
        let decoded = try JSONDecoder().decode(NegotiationState.self, from: JSONEncoder().encode(first))
        #expect(decoded.lastActivityAt == nil)
        #expect(!InboxOrder.isUnread(decoded))
        var second = NegotiationState(listingID: state.market[1].id, patience: 50)
        second.append("seller.counter.0")
        second.counterPrice = Money(minorUnits: 100)
        second.lastActivityAt = Date(timeIntervalSince1970: 10)
        first.lastActivityAt = Date(timeIntervalSince1970: 20)
        first.lastReadMessageID = first.messages.last?.id
        state.conversations = [first, second]
        #expect(InboxOrder.sorted(state, archived: false).first?.id == second.id)
        #expect(InboxOrder.isUnread(second))
        state.conversations[1].closed = true
        #expect(InboxOrder.sorted(state, archived: true).map(\.id) == [second.id])
    }
    @Test @MainActor func readStateAndActivitySurviveRelaunchWithoutReadChangingTime() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let repository = SaveRepository(url: folder.appendingPathComponent("save.json"))
        let definitions = try SeedContent.load().items
        let store = try GameStore(repository: repository, definitions: definitions)
        let listing = try #require(store.snapshot.market.first)
        var conversation = store.conversation(for: listing)
        conversation.append("seller.clean.0")
        try store.updateConversation(conversation)
        let activity = store.snapshot.conversations[0].lastActivityAt
        #expect(activity != nil)
        try store.markConversationRead(listing.id)
        let reopened = try #require(repository.load())
        #expect(!InboxOrder.isUnread(reopened.conversations[0]))
        #expect(reopened.conversations[0].lastActivityAt == activity)
    }
}
