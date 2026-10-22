import SwiftUI

struct ProfileView: View {
    let store: GameStore
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market
    @AppStorage("gameSoundEnabled") private var sounds = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    TraderPortrait(identity: 0, size: 64)
                    Text("profile.intro").font(.system(.title3, design: .rounded, weight: .heavy))
                }.frame(maxWidth: .infinity, alignment: .leading).gameCard(accent: GameStyle.amber)
                VStack(alignment: .leading, spacing: 14) {
                    Text("wallet.cash").font(.caption.bold()).foregroundStyle(.secondary)
                    Text(store.snapshot.player.cash.formatted(locale: locale, market: market)).font(.system(.largeTitle, design: .rounded, weight: .black)).lineLimit(1).minimumScaleFactor(0.45).monospacedDigit()
                    Divider().overlay(GameStyle.line)
                    LabeledContent("profile.inventoryCapacity") { Text(store.snapshot.player.inventoryCapacity, format: .number).bold() }
                }.gameCard()
                NavigationLink { TraderCareerView(store: store) } label: { GameMenuRow(titleKey: "career.title", symbol: "seal.fill") }.buttonStyle(.plain).accessibilityIdentifier("openCareer")
                NavigationLink { ClientBookView(store: store) } label: { GameMenuRow(titleKey: "clients.title", symbol: "person.2.fill") }.buttonStyle(.plain).accessibilityIdentifier("profileClients")
                NavigationLink { CollectionGalleryView(store: store) } label: { GameMenuRow(titleKey: "collections.title", symbol: "square.grid.3x1.below.line.grid.1x2") }.buttonStyle(.plain).accessibilityIdentifier("openCollections")
                NavigationLink { KnowledgeView(store: store) } label: { GameMenuRow(titleKey: "knowledge.title", symbol: "wrench.and.screwdriver.fill") }.buttonStyle(.plain).accessibilityIdentifier("openKnowledge")
                NavigationLink { TradeHistoryView(store: store) } label: { GameMenuRow(titleKey: "trade.history", symbol: "chart.bar.doc.horizontal.fill") }.buttonStyle(.plain).accessibilityIdentifier("openTradeHistory")
                NavigationLink { RecoveryDeskView(store: store) } label: { GameMenuRow(titleKey: "recovery.title", symbol: "arrow.uturn.up.circle.fill") }.buttonStyle(.plain).accessibilityIdentifier("openRecovery")
                NavigationLink { MarketSettingsView(store: store) } label: { GameMenuRow(titleKey: "region.title", symbol: "globe") }.buttonStyle(.plain).accessibilityIdentifier("marketSettings")
                NavigationLink { NotificationSettingsView(store: store) } label: { GameMenuRow(titleKey: "notifications.settings", symbol: "bell.badge.fill") }.buttonStyle(.plain).accessibilityIdentifier("notificationSettings")
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("feel.sounds", isOn: $sounds)
                    Text("feel.soundsHint").font(.caption).foregroundStyle(.secondary)
                }.gameCard()
                #if DEBUG
                NavigationLink { DeveloperToolsView(store: store) } label: { GameMenuRow(titleKey: "debug.title", symbol: "hammer.fill") }.buttonStyle(.plain).accessibilityIdentifier("developerTools")
                #endif
            }.padding(16)
        }.gameScreen().navigationTitle("profile.title")
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
        Label(amount.formatted(locale: locale, market: market, signed: true), systemImage: amount >= .zero ? "arrow.up.right" : "arrow.down.right")
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
                        LabeledContent("purchase.cost") { Text(record.acquiredFor.formatted(locale: locale, market: market)) }
                        LabeledContent("trade.inspectionCost") { Text(record.inspectionCost.formatted(locale: locale, market: market)) }
                        LabeledContent("trade.repairCost") { Text(record.repairCost.formatted(locale: locale, market: market)) }
                        LabeledContent("trade.totalCost") { Text(record.totalCost.formatted(locale: locale, market: market)) }
                        Text("trade.explanation").font(.caption).foregroundStyle(.secondary)
                    }.padding(.top, 12)
                }.gameCard()
                HuntButton()
            }.padding(16)
        }.gameScreen().navigationTitle("trade.receipt").navigationBarTitleDisplayMode(.inline)
    }
}
