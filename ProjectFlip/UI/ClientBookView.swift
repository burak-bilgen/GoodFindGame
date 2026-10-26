import SwiftUI

struct ClientBookView: View {
    let store: GameStore
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                Text("clients.principle").font(.subheadline).foregroundStyle(GameStyle.secondaryText)
                if let brief = ClientEngine.activeBrief(in: store.snapshot) {
                    ClientChapterView(store: store, client: brief.client)
                }
                ForEach(ClientDefinition.all.filter { $0.id != store.snapshot.clients.active }) { client in
                    NavigationLink {
                        ScrollView { ClientChapterView(store: store, client: client).padding(16) }
                            .gameScreen().navigationTitle(GameText.string("client.\(client.id).name.\(market.region.rawValue)", locale: locale))
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        HStack(spacing: 14) {
                            TraderPortrait(identity: client.portrait, size: 48)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(GameText.string("client.\(client.id).name.\(market.region.rawValue)", locale: locale)).font(.headline)
                                Text(GameText.string("client.\(client.id).role", locale: locale)).font(.caption).foregroundStyle(GameStyle.secondaryText)
                                Text(GameText.format("clients.progress", locale: locale, store.snapshot.clients.completed[client.id, default: 0], client.requests.count)).font(.caption).foregroundStyle(GameStyle.amber)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right").font(.caption)
                        }.frame(maxWidth: .infinity, alignment: .leading).gameCard()
                    }.buttonStyle(.plain).accessibilityIdentifier("client.\(client.id)")
                }
            }.padding(16)
        }.gameScreen().navigationTitle("clients.title").navigationBarTitleDisplayMode(.inline)
    }
}

private struct ClientChapterView: View {
    let store: GameStore
    let client: ClientDefinition
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market
    var body: some View {
        let step = store.snapshot.clients.completed[client.id, default: 0]
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                TraderPortrait(identity: client.portrait, size: 64)
                VStack(alignment: .leading, spacing: 6) {
                    Text(GameText.string("client.\(client.id).name.\(market.region.rawValue)", locale: locale)).font(.title2.bold())
                    Text(GameText.string("client.\(client.id).role", locale: locale)).font(.caption).foregroundStyle(GameStyle.amber)
                }
                Spacer(minLength: 0)
                Text(verbatim: "\(step)/3").font(.title2.bold()).monospacedDigit()
            }
            if let request = ClientEngine.request(client.id, state: store.snapshot) {
                Label(GameText.format("clients.unlocksTitle", locale: locale, GameText.string(client.honorKey, locale: locale)), systemImage: "seal")
                    .font(.caption).foregroundStyle(GameStyle.amber)
                Text(GameText.string("client.\(client.id).story.\(step)", locale: locale)).font(.headline)
                Text(GameText.format("clients.condition", locale: locale, request.minimumCondition)).font(.caption)
                if let cap = request.maximumPayment {
                    Text(GameText.format("clients.budget", locale: locale, cap.formatted(locale: locale, market: market))).font(.subheadline.bold()).foregroundStyle(GameStyle.gain)
                }
                Text("clients.reportRequired").font(.caption).foregroundStyle(GameStyle.secondaryText)
                if request.originalBox { Label("clients.originalBox", systemImage: "shippingbox").font(.caption) }
                if request.originalParts { Label("clients.originalParts", systemImage: "checkmark.seal").font(.caption) }
                if store.snapshot.clients.active == client.id {
                    Label("clients.accepted", systemImage: "bookmark.fill").font(.subheadline.bold()).foregroundStyle(GameStyle.gain)
                    Text(store.snapshot.playerListings.contains { $0.status == .sold } ? "clients.arrivalHint" : "clients.firstSaleHint").font(.caption).foregroundStyle(GameStyle.secondaryText)
                    let matches = store.snapshot.player.inventory.filter { ClientEngine.qualifies($0, request: request) && ItemTransfer.available($0.id, state: store.snapshot) }
                    ForEach(matches) { item in
                        if let definition = store.definition(for: item), let payout = try? ClientEngine.quote(item, definition: definition, state: store.snapshot) {
                            VStack(alignment: .leading, spacing: 8) {
                                DeviceArt(symbol: definition.artSymbol, identity: definition.id, appearance: .owned(item)).frame(height: 140)
                                Text(definition.displayName(locale: locale)).font(.headline)
                                if let invested = try? item.purchasePrice.adding(item.inspectionCost).adding(item.repairCost),
                                   let net = try? payout.subtracting(invested) {
                                    LabeledContent("selling.invested") { Text(invested.formatted(locale: locale, market: market)).bold() }
                                    LabeledContent("buyer.net") { ProfitAmount(amount: net).bold() }
                                }
                                Button { store.perform { try store.fulfillClient(client.id, itemID: item.id, expectedQuote: payout); GameFeel.play(.accepted) } } label: {
                                    Text(GameText.format("clients.supplyFor", locale: locale, payout.formatted(locale: locale, market: market)))
                                }.buttonStyle(GameButton()).accessibilityIdentifier("supplyClient.\(client.id).\(item.id.rawValue)")
                            }
                        }
                    }
                    if matches.isEmpty { Text("clients.noMatch").font(.subheadline).foregroundStyle(GameStyle.secondaryText) }
                    Button("clients.pause") { store.perform { try store.pauseClient() } }.buttonStyle(GameButton(secondary: true))
                } else if store.snapshot.clients.active == nil {
                    if store.snapshot.career.tier(knowledge: store.snapshot.inspectionKnowledge).rawValue >= request.career.rawValue {
                        Button("clients.accept") { store.perform { try store.acceptClient(client.id); GameFeel.play(.submitted) } }.buttonStyle(GameButton()).accessibilityIdentifier("acceptClient.\(client.id)")
                    } else { Label(GameText.string(request.career.key, locale: locale), systemImage: "lock.fill").foregroundStyle(GameStyle.amber) }
                }
                DisclosureGroup("clients.models") {
                    ForEach(store.definitions.filter { request.models.contains($0.id) }) { definition in Text(definition.displayName(locale: locale)).font(.caption) }
                }
                // Leads reference actual saved stock, never a fabricated matching spawn.
                ForEach(Array(store.snapshot.market.filter { $0.available && request.models.contains($0.item.definitionID) }.prefix(2))) { listing in
                    NavigationLink { ListingDetailView(store: store, listingID: listing.id) } label: {
                        if let definition = store.definition(for: listing.item) {
                            Label(definition.displayName(locale: locale), systemImage: "magnifyingglass").font(.subheadline.bold())
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading).contentShape(Rectangle())
                        }
                    }.accessibilityIdentifier("clientLead.\(listing.id.rawValue)")
                }
            } else {
                Label("clients.complete", systemImage: "seal.fill").font(.headline).foregroundStyle(GameStyle.amber)
                Text(GameText.string("client.\(client.id).ending", locale: locale)).font(.subheadline)
                Text("clients.honorHint").font(.caption).foregroundStyle(GameStyle.secondaryText)
            }
        }.frame(maxWidth: .infinity, alignment: .leading).gameCard(accent: GameStyle.amber)
    }
}
