import SwiftUI

struct ProfileView: View {
    let store: GameStore
    @Environment(\.locale) private var locale
    @AppStorage("gameSoundEnabled") private var sounds = false
    var body: some View {
        List {
            Text("profile.intro").font(.headline)
            LabeledContent("wallet.cash") { Text(store.snapshot.player.cash.formatted(locale: locale)).monospacedDigit() }
            LabeledContent("profile.inventoryCapacity") { Text(store.snapshot.player.inventoryCapacity, format: .number) }
            NavigationLink("knowledge.title") { KnowledgeView(store: store) }.accessibilityIdentifier("openKnowledge")
            NavigationLink("trade.history") { TradeHistoryView(store: store) }.accessibilityIdentifier("openTradeHistory")
            NavigationLink("notifications.settings") { NotificationSettingsView(store: store) }.accessibilityIdentifier("notificationSettings")
            Toggle("feel.sounds", isOn: $sounds)
            Text("feel.soundsHint").font(.caption).foregroundStyle(.secondary)
            #if DEBUG
            NavigationLink("debug.title") { DeveloperToolsView(store: store) }.accessibilityIdentifier("developerTools")
            #endif
        }.gameScreen().navigationTitle("profile.title")
    }
}

struct TradeHistoryView: View {
    let store: GameStore
    @Environment(\.locale) private var locale
    var body: some View {
        List {
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
                    NavigationLink { TradeReceiptView(record: record) } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            if let definition = store.definitions.first(where: { $0.id == record.definitionID }) { Text(definition.name).font(.headline) }
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
    var body: some View {
        Label(amount.formatted(locale: locale, signed: true), systemImage: amount >= .zero ? "arrow.up.right" : "arrow.down.right")
            .foregroundStyle(amount >= .zero ? Color("AccentColor") : Color("LossColor")).monospacedDigit()
    }
}

struct TradeReceiptView: View {
    let record: TradeRecord
    @Environment(\.locale) private var locale
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                TradePayoff(record: record)
                DisclosureGroup("result.costs") {
                    VStack(spacing: 12) {
                        LabeledContent("purchase.cost") { Text(record.acquiredFor.formatted(locale: locale)) }
                        LabeledContent("trade.inspectionCost") { Text(record.inspectionCost.formatted(locale: locale)) }
                        LabeledContent("trade.repairCost") { Text(record.repairCost.formatted(locale: locale)) }
                        LabeledContent("trade.totalCost") { Text(record.totalCost.formatted(locale: locale)) }
                        Text("trade.explanation").font(.caption).foregroundStyle(.secondary)
                    }.padding(.top, 12)
                }.gameCard()
                HuntButton()
            }.padding(16)
        }.gameScreen().navigationTitle("trade.receipt").navigationBarTitleDisplayMode(.inline)
    }
}
