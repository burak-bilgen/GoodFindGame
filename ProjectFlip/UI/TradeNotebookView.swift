import SwiftUI

struct TradeNotebookView: View {
    let store: GameStore
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    Label("notebook.title", systemImage: "book.closed").font(.title2.bold()).foregroundStyle(GameStyle.gain)
                    Text("notebook.intro").font(.subheadline)
                    Text("notebook.scope").font(.caption).foregroundStyle(GameStyle.secondaryText)
                }.gameCard()
                switch Result(catching: { try TradeNotebook(records: TradeLedger.records(from: store.snapshot), definitions: store.definitions) }) {
                case .success(let notebook):
                    if notebook.pages.isEmpty {
                        Text("notebook.empty").foregroundStyle(GameStyle.secondaryText).accessibilityIdentifier("notebookEmpty")
                        HuntButton()
                    }
                    ForEach(notebook.pages) { page in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(GameText.string(page.category.map { "category.\($0.rawValue)" } ?? "notebook.other", locale: locale))
                                .font(.headline).accessibilityAddTraits(.isHeader)
                            Text(GameText.format("notebook.counts", locale: locale, Int64(page.profitable), Int64(page.losses), Int64(page.even)))
                                .font(.subheadline).foregroundStyle(GameStyle.secondaryText)
                            NotebookMetric("trade.totalCost") { Text(page.invested.formatted(locale: locale, market: market, precise: true)).monospacedDigit() }
                            NotebookMetric("notebook.proceeds") { Text(page.proceeds.formatted(locale: locale, market: market, precise: true)).monospacedDigit() }
                            NotebookMetric("trade.totalRealized") { ProfitAmount(amount: page.net) }
                            DisclosureGroup {
                                VStack(alignment: .leading, spacing: 14) {
                                    ForEach(Array(page.records.prefix(3))) { record in
                                        NavigationLink {
                                            TradeReceiptView(record: record, item: store.snapshot.playerListings.first { $0.id == record.id }?.itemSnapshot)
                                        } label: {
                                            VStack(alignment: .leading, spacing: 6) {
                                                if let definition = store.definitions.first(where: { $0.id == record.definitionID }) {
                                                    Text(definition.displayName(locale: locale)).font(.subheadline.bold())
                                                } else { Text("notebook.other") }
                                                ProfitAmount(amount: record.netProfit)
                                                Text(record.soldAt, format: .dateTime.day().month().year().locale(locale)).font(.caption).foregroundStyle(GameStyle.secondaryText)
                                            }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 6)
                                        }.accessibilityIdentifier("notebookReceipt.\(record.id.rawValue)")
                                    }
                                }.padding(.top, 10)
                            } label: {
                                Text("notebook.latest").accessibilityIdentifier("notebookLatest.\(page.id)")
                            }
                        }.gameCard()
                    }
                case .failure: Text("trade.unavailable")
                }
            }.padding(16)
        }.gameScreen().navigationTitle("notebook.title").navigationBarTitleDisplayMode(.inline)
    }
}

struct PreviousMarketSaleView: View {
    let store: GameStore
    let definitionID: String
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market
    var body: some View {
        switch Result(catching: { try TradeLedger.records(from: store.snapshot) }) {
        case .success(let records):
            if let record = TradeLedger.latestMarketSale(for: definitionID, in: records) {
                VStack(alignment: .leading, spacing: 6) {
                    NavigationLink {
                        TradeReceiptView(record: record, item: store.snapshot.playerListings.first { $0.id == record.id }?.itemSnapshot)
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("notebook.lastMarketSale").font(.caption)
                                Text(record.soldFor.formatted(locale: locale, market: market, precise: true)).font(.headline).monospacedDigit()
                                Text(record.soldAt, format: .dateTime.day().month().year().locale(locale)).font(.caption).foregroundStyle(GameStyle.secondaryText)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right").font(.caption)
                        }.foregroundStyle(GameStyle.gain).frame(minHeight: 44)
                    }.buttonStyle(.plain).accessibilityIdentifier("previousMarketSale")
                    Text("notebook.sameModel").font(.caption).foregroundStyle(GameStyle.secondaryText)
                }.padding(.top, 6)
            }
        case .failure: Text("trade.unavailable").font(.caption)
        }
    }
}

private struct NotebookMetric<Value: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let value: () -> Value
    @Environment(\.dynamicTypeSize) private var typeSize

    init(_ title: LocalizedStringKey, @ViewBuilder value: @escaping () -> Value) {
        self.title = title
        self.value = value
    }

    var body: some View {
        if typeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.subheadline).foregroundStyle(GameStyle.secondaryText)
                value().lineLimit(1).minimumScaleFactor(0.4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        } else {
            LabeledContent(title) { value() }
        }
    }
}
