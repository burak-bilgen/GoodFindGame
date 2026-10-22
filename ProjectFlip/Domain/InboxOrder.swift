import Foundation

/// Old saves have no fabricated timestamps or unread flags; their original order is the tie-break.
enum InboxOrder {
    static func isUnread(_ conversation: NegotiationState) -> Bool {
        guard conversation.lastActivityAt != nil, let last = conversation.messages.last, !last.fromPlayer else { return false }
        return last.id != conversation.lastReadMessageID
    }
    static func isArchived(_ conversation: NegotiationState, state: GameSnapshot) -> Bool {
        conversation.closed || !state.market.contains { $0.id == conversation.listingID && $0.available }
    }
    static func needsAction(_ conversation: NegotiationState, state: GameSnapshot) -> Bool {
        !isArchived(conversation, state: state) && conversation.pendingReplyEventID == nil &&
        (conversation.counterPrice != nil || conversation.agreedPrice != nil || isUnread(conversation))
    }
    static func sorted(_ state: GameSnapshot, archived: Bool) -> [NegotiationState] {
        state.conversations.enumerated().filter { isArchived($0.element, state: state) == archived }.sorted { a, b in
            let left = a.element, right = b.element
            let lp = needsAction(left, state: state), rp = needsAction(right, state: state)
            if lp != rp { return lp }
            if isUnread(left) != isUnread(right) { return isUnread(left) }
            let ld = left.lastActivityAt ?? .distantPast, rd = right.lastActivityAt ?? .distantPast
            return ld == rd ? a.offset < b.offset : ld > rd
        }.map(\.element)
    }
    static func recordChanges(from old: GameSnapshot, in next: inout GameSnapshot, now: Date) {
        for index in next.playerListings.indices {
            let listing = next.playerListings[index]
            let previous = old.playerListings.first { $0.id == listing.id }
            if listing.messages != previous?.messages {
                let resolved = next.events.filter { event in event.payload.targetID == listing.id.rawValue && event.status == .completed && old.events.first(where: { $0.id == event.id })?.status == .pending }
                next.playerListings[index].lastActivityAt = resolved.map(\.resolveAt).max() ?? now
            }
        }
        for index in next.conversations.indices {
            let current = next.conversations[index]
            let previous = old.conversations.first { $0.id == current.id }
            guard current.messages != previous?.messages else { continue }
            // Deferred replies carry the event's actual resolution time; user actions use commit time.
            let changedEvents = next.events.filter { event in
                event.payload.targetID == current.id.rawValue && event.status == .completed &&
                old.events.first(where: { $0.id == event.id })?.status == .pending
            }
            next.conversations[index].lastActivityAt = changedEvents.map(\.resolveAt).max() ?? now
        }
    }
}

extension GameStore {
    func markConversationRead(_ id: ListingID) throws {
        guard let index = snapshot.conversations.firstIndex(where: { $0.id == id }),
              let last = snapshot.conversations[index].messages.last,
              snapshot.conversations[index].lastReadMessageID != last.id else { return }
        var next = snapshot
        next.conversations[index].lastReadMessageID = last.id
        try commit(next)
    }
}
