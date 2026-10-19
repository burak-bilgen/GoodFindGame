import SwiftUI

struct ConversationView: View {
    let store: GameStore
    let listingID: ListingID
    @Environment(\.locale) private var locale
    @State private var amount = ""
    @State private var modifier: OfferModifier = .none

    var body: some View {
        if let listing = store.snapshot.market.first(where: { $0.id == listingID }) {
            let conversation = store.conversation(for: listing)
            List {
                Section { SellerSummary(seller: listing.seller, playerTradeCount: store.previousTradeCount(with: listing.seller.id)) }
                Section("messages.title") {
                    Text("negotiation.intro").font(.caption).foregroundStyle(.secondary)
                    ForEach(conversation.messages) { message in
                        VStack(alignment: message.fromPlayer ? .trailing : .leading, spacing: 6) {
                            Text(GameText.string(message.intent, locale: locale))
                            if let amount = message.amount { Text(amount.formatted(locale: locale)).bold().monospacedDigit() }
                            if let defect = message.defect { Text(GameText.string(defect.key, locale: locale)).bold() }
                        }.frame(maxWidth: .infinity, alignment: message.fromPlayer ? .trailing : .leading)
                            .padding(8).listRowBackground(message.fromPlayer ? Color.teal.opacity(0.1) : Color.clear)
                    }
                }
                if !conversation.closed && conversation.agreedPrice == nil && listing.available {
                    Section {
                        Button("question.issues") {
                            store.perform { try store.askIssues(listingID: listing.id) }
                        }.disabled(conversation.askedAboutIssues || conversation.pendingReplyEventID != nil).accessibilityIdentifier("askIssues")
                        if conversation.pendingReplyEventID != nil {
                            Label("seller.awaitingReply", systemImage: "clock")
                        }
                        TextField("offer.amount", text: $amount).keyboardType(.decimalPad).accessibilityIdentifier("offerAmount")
                        Picker("offer.modifier", selection: $modifier) {
                            ForEach(OfferModifier.allCases.filter { $0 != .knownIssues || !conversation.knownDefects.isEmpty }, id: \.self) { modifier in
                                Text(GameText.string(modifier.key, locale: locale)).tag(modifier)
                            }
                        }
                        Button("offer.send") { send(listing: listing, conversation: conversation) }.disabled(conversation.pendingReplyEventID != nil).accessibilityIdentifier("sendOffer")
                        if let counter = conversation.counterPrice {
                            Button("offer.acceptCounter") {
                                store.perform {
                                    try store.acceptSellerCounter(listingID: listing.id)
                                }
                            }
                            Button("offer.halfway") {
                                store.perform {
                                    let last = conversation.offers.last?.amount ?? .zero
                                    amount = try counter.adding(last).scaled(byBasisPoints: 5_000).inputText(locale: locale)
                                }
                            }
                        }
                        Button("offer.walkAway", role: .destructive) {
                            store.perform {
                                try store.walkAway(listingID: listing.id)
                            }
                        }
                    }
                } else if let price = conversation.agreedPrice {
                    Section {
                        Text("offer.agreed")
                        Text(price.formatted(locale: locale)).font(.title2.bold())
                        if listing.available && !conversation.closed {
                            Button("purchase.confirm") {
                                store.perform { try store.purchase(listingID: listing.id) }
                            }.accessibilityIdentifier("confirmPurchase")
                        }
                    }
                }
                if let expiry = conversation.counterExpiresAt, !conversation.closed {
                    DeadlineView(store: store, target: expiry, titleKey: "offer.expires")
                }
            }
            .navigationTitle("messages.title")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { if amount.isEmpty { amount = listing.askingPrice.inputText(locale: locale) } }
        }
    }

    private func send(listing: MarketplaceListing, conversation: NegotiationState) {
        store.perform {
            let price = try Money.parse(amount, locale: locale)
            try store.sendOffer(listingID: listing.id, amount: price, modifier: modifier)
        }
    }
}
