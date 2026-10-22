import SwiftUI

struct ClientBookView: View {
    let store: GameStore
    @Environment(\.locale) private var locale
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                GameStageBanner(titleKey: "clients.title", eyebrowKey: "clients.eyebrow", symbol: "person.2.fill", color: GameStyle.amber)
                Text("clients.principle").font(.subheadline).foregroundStyle(.secondary)
                ForEach(ClientDefinition.all) { client in ClientChapterView(store: store, client: client) }
            }.padding(16)
        }.gameScreen().navigationTitle("clients.title")
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
                Text("\(step)/3").font(.title2.bold()).monospacedDigit()
            }
            if let request = ClientEngine.request(client.id, state: store.snapshot) {
                Text(GameText.string("client.\(client.id).story.\(step)", locale: locale)).font(.headline)
                Text(GameText.format("clients.condition", locale: locale, request.minimumCondition)).font(.caption)
                Text("clients.reportRequired").font(.caption).foregroundStyle(.secondary)
                if request.originalBox { Label("clients.originalBox", systemImage: "shippingbox").font(.caption) }
                if request.originalParts { Label("clients.originalParts", systemImage: "checkmark.seal").font(.caption) }
                if store.snapshot.clients.active == client.id {
                    Label("clients.accepted", systemImage: "bookmark.fill").font(.subheadline.bold()).foregroundStyle(GameStyle.gain)
                    let matches = store.snapshot.player.inventory.filter { ClientEngine.qualifies($0, request: request) && ItemTransfer.available($0.id, state: store.snapshot) }
                    ForEach(matches) { item in
                        if let definition = store.definition(for: item), let payout = try? ClientEngine.quote(item, definition: definition, state: store.snapshot) {
                            VStack(alignment: .leading, spacing: 8) {
                                DeviceArt(symbol: definition.artSymbol, identity: definition.id, appearance: .owned(item)).frame(height: 140)
                                Text(definition.displayName(locale: locale)).font(.headline)
                                Button { store.perform { try store.fulfillClient(client.id, itemID: item.id); GameFeel.play(.accepted) } } label: {
                                    Text(GameText.format("clients.supplyFor", locale: locale, payout.formatted(locale: locale, market: market)))
                                }.buttonStyle(GameButton()).accessibilityIdentifier("supplyClient.\(client.id).\(item.id.rawValue)")
                            }
                        }
                    }
                    if matches.isEmpty { Text("clients.noMatch").font(.subheadline).foregroundStyle(.secondary) }
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
                        if let definition = store.definition(for: listing.item) { Label(definition.displayName(locale: locale), systemImage: "magnifyingglass").font(.subheadline.bold()) }
                    }.accessibilityIdentifier("clientLead.\(listing.id.rawValue)")
                }
            } else {
                Label("clients.complete", systemImage: "seal.fill").font(.headline).foregroundStyle(GameStyle.amber)
                Text(GameText.string("client.\(client.id).ending", locale: locale)).font(.subheadline)
            }
        }.frame(maxWidth: .infinity, alignment: .leading).gameCard(accent: GameStyle.amber)
    }
}
