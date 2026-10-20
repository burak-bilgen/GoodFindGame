import SwiftUI

struct ConversationView: View {
    let store: GameStore
    let listingID: ListingID
    @Environment(\.locale) private var locale
    @GameReduceMotion private var reduceMotion
    @State private var amount = ""
    @State private var modifier: OfferModifier = .none
    @FocusState private var editing: Bool

    var body: some View {
        if let listing = store.snapshot.market.first(where: { $0.id == listingID }) {
            let conversation = store.conversation(for: listing)
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                TraderPortrait(identity: listing.seller.identityIndex, size: 54)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(GameText.string("npc.name.\(listing.seller.identityIndex % 10)", locale: locale)).font(.headline)
                                    if let definition = store.definition(for: listing.item) { Text(definition.name).font(.subheadline).foregroundStyle(.secondary) }
                                }
                                Spacer()
                            }
                            Text(GameText.string("seller.voice.\(listing.seller.archetype.rawValue)", locale: locale)).font(.subheadline)
                            if !conversation.closed && conversation.agreedPrice == nil {
                                Label(conversation.patience <= 25 ? "seller.mood.last" : conversation.patience < listing.seller.patience ? "seller.mood.firm" : "seller.mood.open", systemImage: "bubble.left")
                                    .font(.caption.weight(.semibold)).foregroundStyle(conversation.patience <= 25 ? GameStyle.loss : GameStyle.gain)
                            }
                            DisclosureGroup("seller.title") { SellerSummary(seller: listing.seller, playerTradeCount: store.previousTradeCount(with: listing.seller.id)).padding(.top, 8) }
                        }.gameCard()
                        if !listing.available {
                            let reason = store.snapshot.marketListingStates.first { $0.id == listing.id }?.closureReason
                            let acquired = store.snapshot.shipments.contains(where: { $0.item.id == listing.item.id }) || store.snapshot.player.inventory.contains(where: { $0.id == listing.item.id })
                            if !acquired && reason != .purchased {
                                Text(GameText.string(reason?.key ?? "listing.unavailable", locale: locale)).font(.headline)
                            }
                            if acquired {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("game.dealClosed").font(.caption.weight(.black)).tracking(2)
                                        Spacer()
                                        Image(systemName: "checkmark.seal.fill").font(.title).accessibilityHidden(true)
                                    }.foregroundStyle(GameStyle.amber)
                                    if let definition = store.definition(for: listing.item) {
                                        Text(definition.name).font(.title2.bold()).foregroundStyle(.white)
                                    }
                                    Text("game.boughtFor").font(.caption).foregroundStyle(.white.opacity(0.75))
                                    if let price = conversation.agreedPrice {
                                        Text(price.formatted(locale: locale)).font(.system(.largeTitle, design: .rounded, weight: .black)).foregroundStyle(.white)
                                    }
                                    Text("game.purchaseRisk").font(.subheadline).foregroundStyle(.white.opacity(0.8))
                                }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
                                    .background(GameStyle.ink, in: RoundedRectangle(cornerRadius: 22)).id("purchaseCommitment")
                                if store.snapshot.player.inventory.contains(where: { $0.id == listing.item.id }) {
                                    NavigationLink { OwnedItemView(store: store, itemID: listing.item.id) } label: { Text("hunt.inspect") }.buttonStyle(GameButton()).accessibilityIdentifier("continueToItem")
                                } else {
                                    NavigationLink { InventoryView(store: store) } label: { Text("hunt.delivery") }.buttonStyle(GameButton()).accessibilityIdentifier("followDelivery")
                                }
                            }
                        }
                        if conversation.messages.isEmpty { Text("negotiation.intro").font(.subheadline).foregroundStyle(.secondary) }
                        if listing.available {
                            ForEach(conversation.messages) { message in
                                DialogueBubble(message: message).id(message.id)
                                    .transition(reduceMotion ? .opacity : .move(edge: message.fromPlayer ? .trailing : .leading).combined(with: .opacity))
                            }
                        } else {
                            DisclosureGroup("game.conversationHistory") {
                                VStack(spacing: 12) {
                                    ForEach(conversation.messages) { DialogueBubble(message: $0) }
                                }.padding(.top, 12)
                            }.gameCard()
                        }
                        if conversation.pendingReplyEventID != nil {
                            Label("seller.awaitingReply", systemImage: "ellipsis.bubble.fill").font(.subheadline).foregroundStyle(.secondary).padding(12)
                        }
                        if !conversation.closed && conversation.agreedPrice == nil && listing.available {
                            VStack(alignment: .leading, spacing: 14) {
                                Button("question.issues") { store.perform { try store.askIssues(listingID: listing.id) } }
                                    .disabled(conversation.askedAboutIssues || conversation.pendingReplyEventID != nil).accessibilityIdentifier("askIssues")
                                if let counter = conversation.counterPrice {
                                    GameEyebrow(key: "offer.counterHeading")
                                    Text(counter.formatted(locale: locale)).font(.system(.largeTitle, design: .rounded, weight: .bold)).contentTransition(.numericText())
                                    Button("offer.acceptCounter") { store.perform { try store.acceptSellerCounter(listingID: listing.id) } }
                                        .buttonStyle(GameButton()).accessibilityIdentifier("acceptSellerCounter")
                                    Button("offer.halfway") {
                                        store.perform {
                                            let last = conversation.offers.last?.amount ?? .zero
                                            amount = try counter.adding(last).scaled(byBasisPoints: 5_000).inputText(locale: locale)
                                        }
                                    }
                                } else if conversation.offers.isEmpty {
                                    Text("offer.tryLess").font(.caption).foregroundStyle(.secondary)
                                    HStack {
                                        Button("offer.testWaters") { setOffer(listing.askingPrice, factor: 8_500) }
                                        Spacer()
                                        Button("offer.smallDiscount") { setOffer(listing.askingPrice, factor: 9_500) }
                                    }.buttonStyle(.bordered)
                                }
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("offer.amount").font(.caption).foregroundStyle(.secondary)
                                    TextField("offer.amount", text: $amount).keyboardType(.decimalPad).focused($editing)
                                        .font(.title2.bold()).textFieldStyle(.roundedBorder).accessibilityIdentifier("offerAmount")
                                }
                                Picker("offer.modifier", selection: $modifier) {
                                    ForEach(OfferModifier.allCases.filter { $0 != .knownIssues || !conversation.knownDefects.isEmpty }, id: \.self) { value in
                                        Text(GameText.string(value.key, locale: locale)).tag(value)
                                    }
                                }
                                Button("offer.send") {
                                    editing = false
                                    store.perform {
                                        try store.sendOffer(listingID: listing.id, amount: Money.parse(amount, locale: locale), modifier: modifier)
                                        GameFeel.play(.submitted)
                                    }
                                }.buttonStyle(GameButton()).disabled(conversation.pendingReplyEventID != nil).accessibilityIdentifier("sendOffer")
                                Button("offer.walkAway", role: .destructive) { store.perform { try store.walkAway(listingID: listing.id) } }.font(.subheadline)
                            }.gameCard().id("composer")
                        } else if let price = conversation.agreedPrice, listing.available && !conversation.closed {
                            VStack(alignment: .leading, spacing: 12) {
                                GameStamp(key: "offer.agreed", symbol: "checkmark.seal.fill")
                                Text(price.formatted(locale: locale)).font(.system(.largeTitle, design: .rounded, weight: .heavy))
                                Text("journey.commit").font(.subheadline).foregroundStyle(.secondary)
                                Button("purchase.confirm") {
                                    store.perform { try store.purchase(listingID: listing.id); GameFeel.play(.purchase) }
                                }.buttonStyle(GameButton()).accessibilityIdentifier("confirmPurchase")
                            }.gameCard()
                        }
                        if let expiry = conversation.counterExpiresAt, !conversation.closed {
                            DeadlineView(store: store, target: expiry, titleKey: "offer.expires")
                        }
                    }.padding(16)
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.22), value: conversation.messages.count)
                }.gameScreen()
                .onChange(of: conversation.messages.last?.id) { _, _ in
                    if let last = conversation.messages.last, !last.fromPlayer {
                        GameFeel.play(conversation.agreedPrice == nil ? .reply : .accepted)
                        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                            if last.intent == "purchase.completed" { proxy.scrollTo("purchaseCommitment", anchor: .top) }
                            else { proxy.scrollTo(last.id, anchor: .center) }
                        }
                    }
                }
            }
            .navigationTitle("messages.title").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("action.done") { editing = false } } }
            .onAppear { if amount.isEmpty { amount = listing.askingPrice.inputText(locale: locale) } }
        }
    }
    private func setOffer(_ asking: Money, factor: Int64) {
        store.perform { amount = try asking.scaled(byBasisPoints: factor).inputText(locale: locale) }
    }
}

struct DialogueBubble: View {
    let message: DialogueMessage
    @Environment(\.locale) private var locale
    var body: some View {
        HStack {
            if message.fromPlayer { Spacer(minLength: 32) }
            VStack(alignment: .leading, spacing: 8) {
                Text(GameText.string(message.intent, locale: locale))
                if let amount = message.amount { Text(amount.formatted(locale: locale)).font(.title3.bold()).monospacedDigit() }
                if let defect = message.defect { Label(GameText.string(defect.key, locale: locale), systemImage: "exclamationmark.triangle.fill").font(.subheadline.bold()).foregroundStyle(GameStyle.loss) }
            }.padding(16)
                .background(message.fromPlayer ? GameStyle.gain.opacity(0.16) : Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
                .overlay(alignment: message.fromPlayer ? .trailing : .leading) {
                    Capsule().fill(message.fromPlayer ? GameStyle.gain : GameStyle.amber).frame(width: 3).padding(.vertical, 14)
                }
            if !message.fromPlayer { Spacer(minLength: 32) }
        }.accessibilityElement(children: .combine)
    }
}
