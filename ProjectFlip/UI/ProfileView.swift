import SwiftUI

struct ProfileView: View {
    @AppStorage("playerDisplayName") private var displayName = ""
    @AppStorage("playerAvatar") private var avatar = 0
    @AppStorage("playerTitle") private var title = -1
    @State private var editingProfile = false
    let store: GameStore
    var competition: CompetitionStore? = nil
    var retryCompetition: () -> Void = {}
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    TraderPortrait(identity: avatar, size: 64)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(displayName.isEmpty ? GameText.string("profile.defaultName", locale: locale) : displayName).font(.title2.bold())
                        if let tier = CareerTier(rawValue: title), tier.rawValue <= store.snapshot.career.tier(knowledge: store.snapshot.inspectionKnowledge).rawValue {
                            Text(GameText.string(tier.key, locale: locale)).font(.subheadline).foregroundStyle(.secondary)
                        }
                        Button("profile.edit") { editingProfile = true }.font(.subheadline).accessibilityIdentifier("editProfile")
                    }
                }.frame(maxWidth: .infinity, alignment: .leading).gameCard(accent: GameStyle.amber)
                if !store.snapshot.collections.completedBefore.isEmpty {
                    Label("collections.curator", systemImage: "seal.fill").font(.headline).foregroundStyle(GameStyle.amber).gameCard(accent: GameStyle.amber)
                }
                if store.snapshot.clients.completed["rowan", default: 0] == 3 {
                    Label("clients.confidant", systemImage: "person.crop.circle.badge.checkmark").font(.subheadline.bold()).foregroundStyle(GameStyle.amber)
                }
                if store.snapshot.clients.completed["jules", default: 0] == 3 {
                    Label("clients.preferred", systemImage: "camera.badge.ellipsis").font(.subheadline.bold()).foregroundStyle(GameStyle.amber)
                }
                VStack(alignment: .leading, spacing: 14) {
                    Text("wallet.cash").font(.caption.bold()).foregroundStyle(.secondary)
                    Text(store.snapshot.player.cash.formatted(locale: locale, market: market, precise: true)).font(.system(.largeTitle, design: .rounded, weight: .black)).lineLimit(1).minimumScaleFactor(0.45).monospacedDigit()
                    Divider().overlay(GameStyle.line)
                    LabeledContent("profile.inventoryCapacity") { Text(store.snapshot.player.inventoryCapacity, format: .number).bold() }
                }.gameCard()
                if let competition {
                    NavigationLink { CompetitionView(career: store, competition: competition) } label: { GameMenuRow(titleKey: "competition.title", symbol: "trophy.fill") }.buttonStyle(.plain).accessibilityIdentifier("openCompetition")
                } else {
                    Button(action: retryCompetition) { GameMenuRow(titleKey: "competition.title", symbol: "arrow.clockwise") }.buttonStyle(.plain)
                    Text("competition.error").font(.caption)
                }
                NavigationLink { TraderCareerView(store: store) } label: { GameMenuRow(titleKey: "career.title", symbol: "seal.fill") }.buttonStyle(.plain).accessibilityIdentifier("openCareer")
                NavigationLink { ClientBookView(store: store) } label: { GameMenuRow(titleKey: "clients.title", symbol: "person.2.fill") }.buttonStyle(.plain).accessibilityIdentifier("profileClients")
                NavigationLink { CollectionGalleryView(store: store) } label: { GameMenuRow(titleKey: "collections.title", symbol: "square.grid.3x1.below.line.grid.1x2") }.buttonStyle(.plain).accessibilityIdentifier("openCollections")
                NavigationLink { KnowledgeView(store: store) } label: { GameMenuRow(titleKey: "knowledge.title", symbol: "wrench.and.screwdriver.fill") }.buttonStyle(.plain).accessibilityIdentifier("openKnowledge")
                NavigationLink { TradeHistoryView(store: store) } label: { GameMenuRow(titleKey: "trade.history", symbol: "chart.bar.doc.horizontal.fill") }.buttonStyle(.plain).accessibilityIdentifier("openTradeHistory")
                NavigationLink { RecoveryDeskView(store: store) } label: { GameMenuRow(titleKey: "recovery.title", symbol: "arrow.uturn.up.circle.fill") }.buttonStyle(.plain).accessibilityIdentifier("openRecovery")
                NavigationLink { SettingsView(store: store) } label: { GameMenuRow(titleKey: "settings.title", symbol: "gearshape.fill") }.buttonStyle(.plain).accessibilityIdentifier("openSettings")
            }.padding(16)
        }.gameScreen().navigationTitle("profile.title")
            .sheet(isPresented: $editingProfile) { NavigationStack { EditProfileView(store: store) } }
    }
}

struct TradeHistoryView: View {
    let store: GameStore
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market
    var body: some View {
        GameList {
            switch Result(catching: { try TradeLedger.records(from: store.snapshot) }) {
            case .success(let records):
                Section {
                    Text("trade.count \(records.count)")
                    switch Result(catching: { try TradeLedger.totalProfit(records) }) {
                    case .success(let total):
                        LabeledContent("trade.totalRealized") { ProfitAmount(amount: total) }
                    case .failure: Text("trade.unavailable")
                    }
                }
                ForEach(records) { record in
                    NavigationLink { TradeReceiptView(record: record, item: store.snapshot.playerListings.first(where: { $0.id == record.id })?.itemSnapshot) } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            if let definition = store.definitions.first(where: { $0.id == record.definitionID }) { Text(definition.displayName(locale: locale)).font(.headline) }
                            ProfitAmount(amount: record.netProfit)
                            Text(record.soldAt, format: .dateTime.day().month().year().locale(locale)).font(.caption).foregroundStyle(.secondary)
                        }
                    }.accessibilityIdentifier("trade.\(record.id.rawValue)")
                }
            case .failure:
                Text("trade.unavailable")
            }
        }.gameScreen().navigationTitle("trade.history")
    }
}

struct ProfitAmount: View {
    let amount: Money
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market
    var body: some View {
        Label(amount.formatted(locale: locale, market: market, signed: true, precise: true), systemImage: amount >= .zero ? "arrow.up.right" : "arrow.down.right")
            .foregroundStyle(amount >= .zero ? Color("AccentColor") : Color("LossColor")).monospacedDigit()
    }
}

struct TradeReceiptView: View {
    let record: TradeRecord
    var item: ItemInstance?
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                TradePayoff(record: record, item: item)
                DisclosureGroup("result.costs") {
                    VStack(spacing: 12) {
                        LabeledContent("purchase.cost") { Text(record.acquiredFor.formatted(locale: locale, market: market, precise: true)) }
                        LabeledContent("trade.inspectionCost") { Text(record.inspectionCost.formatted(locale: locale, market: market, precise: true)) }
                        LabeledContent("trade.repairCost") { Text(record.repairCost.formatted(locale: locale, market: market, precise: true)) }
                        LabeledContent("trade.totalCost") { Text(record.totalCost.formatted(locale: locale, market: market, precise: true)) }
                        Text("trade.explanation").font(.caption).foregroundStyle(.secondary)
                    }.padding(.top, 12)
                }.gameCard()
                HuntButton()
            }.padding(16)
        }.gameScreen().navigationTitle("trade.receipt").navigationBarTitleDisplayMode(.inline)
    }
}
