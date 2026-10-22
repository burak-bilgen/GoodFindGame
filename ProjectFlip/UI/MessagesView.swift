import SwiftUI

struct MessagesView: View {
    let store: GameStore
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market
    @State private var archived = false
    private var waiting: [PlayerListing] {
        store.snapshot.playerListings.filter {
            $0.status == .active && !store.snapshot.hasBuyerReply(for: $0.id) &&
            $0.offers.last.map { [.pending, .countered].contains($0.status) } == true
        }.sorted { ($0.lastActivityAt ?? $0.createdAt) > ($1.lastActivityAt ?? $1.createdAt) }
    }
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                if !waiting.isEmpty {
                    Text("messages.buyersWaiting").font(.headline)
                    ForEach(waiting) { listing in
                        NavigationLink { SaleListingView(store: store, listingID: listing.id) } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                if let item = store.snapshot.player.inventory.first(where: { $0.id == listing.itemID }), let definition = store.definition(for: item) {
                                    Text(definition.displayName(locale: locale)).font(.headline)
                                }
                                Label("journey.offerWaiting", systemImage: "bubble.left.fill").font(.subheadline).foregroundStyle(GameStyle.gain)
                                if let offer = listing.offers.last { Text(offer.amount.formatted(locale: locale, market: market)).bold() }
                            }.frame(maxWidth: .infinity, alignment: .leading).gameCard(accent: GameStyle.gain)
                        }.buttonStyle(.plain)
                    }
                }
                NavigationLink { ClientBookView(store: store) } label: { GameMenuRow(titleKey: "clients.title", symbol: "person.2.fill") }.buttonStyle(.plain).accessibilityIdentifier("openClients")
                Picker("messages.filter", selection: $archived) {
                    Text("messages.active").tag(false)
                    Text("messages.archive").tag(true)
                }.pickerStyle(.segmented)
                let conversations = InboxOrder.sorted(store.snapshot, archived: archived)
                if conversations.isEmpty {
                    Text(archived ? "messages.archiveEmpty" : "messages.empty").foregroundStyle(.secondary).padding(.vertical)
                    if !archived { HuntButton() }
                }
                ForEach(conversations) { conversation in
                    if let listing = store.snapshot.market.first(where: { $0.id == conversation.listingID }), let definition = store.definition(for: listing.item) {
                        NavigationLink { ConversationView(store: store, listingID: conversation.listingID) } label: {
                            HStack(alignment: .top, spacing: 12) {
                                DeviceArt(symbol: definition.artSymbol, identity: definition.id, appearance: .advertised(listing)).frame(width: 64, height: 64)
                                VStack(alignment: .leading, spacing: 5) {
                                    HStack {
                                        Text(definition.displayName(locale: locale)).font(.headline)
                                        if InboxOrder.isUnread(conversation) { Image(systemName: "circle.fill").font(.caption2).foregroundStyle(GameStyle.gain).accessibilityLabel(Text("messages.unread")) }
                                    }
                                    Text(GameText.marketPerson("name", index: listing.seller.identityIndex, market: market, locale: locale)).font(.subheadline)
                                    if conversation.pendingReplyEventID != nil {
                                        Label("seller.awaitingReply", systemImage: "clock").font(.caption).foregroundStyle(.secondary)
                                    } else if InboxOrder.needsAction(conversation, state: store.snapshot) {
                                        Label("messages.yourTurn", systemImage: "arrow.turn.down.right").font(.caption).foregroundStyle(GameStyle.gain)
                                    }
                                    if let last = conversation.messages.last { Text(GameText.string(last.intent, locale: locale)).font(.caption).foregroundStyle(.secondary).lineLimit(2) }
                                    if let date = conversation.lastActivityAt { Text(date, style: .relative).font(.caption2).foregroundStyle(.secondary) }
                                }
                            }.frame(maxWidth: .infinity, alignment: .leading).gameCard()
                        }.buttonStyle(.plain).accessibilityIdentifier("conversation.\(conversation.listingID.rawValue)")
                    }
                }
            }.padding(16)
        }.gameScreen().navigationTitle("messages.title")
    }
}
