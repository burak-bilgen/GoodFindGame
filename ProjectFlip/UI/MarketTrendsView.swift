import SwiftUI

struct MarketTrendsView: View {
    let store: GameStore
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market
    private var now: Date { store.snapshot.lastSimulationAt ?? .now }
    var body: some View {
        GameList {
            Section {
                Label("trend.heading", systemImage: "chart.line.uptrend.xyaxis").font(.title2.bold())
                Text("trend.explanation").foregroundStyle(.secondary)
            }
            if store.snapshot.marketCalendar == nil {
                Text("trend.unlock").accessibilityIdentifier("marketTrendsLocked")
            } else {
                if !store.snapshot.marketTrends.contains(where: { $0.isActive(at: now) }) {
                    Text("trend.stable")
                }
                ForEach(store.snapshot.marketTrends.reversed()) { trend in
                    NavigationLink {
                        MarketTrendDetailView(store: store, trend: trend)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(trend.scope.displayName(definitions: store.definitions, locale: locale)).font(.headline)
                            Text(trend.formattedChange(locale: locale)).font(.title2.bold())
                            Text(GameText.string(trend.reason.key, locale: locale)).font(.subheadline)
                            Text(trend.isActive(at: now) ? "trend.active" : "trend.ended").font(.caption).foregroundStyle(.secondary)
                        }.padding(.vertical, 8)
                    }.accessibilityIdentifier("marketTrend.\(trend.id)")
                }
            }
        }.gameScreen().navigationTitle("trend.title")
    }
}

struct MarketTrendDetailView: View {
    let store: GameStore
    let trend: MarketTrend
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market
    var body: some View {
        GameList {
            Section {
                Text(trend.scope.displayName(definitions: store.definitions, locale: locale)).font(.title2.bold())
                Text(trend.formattedChange(locale: locale)).font(.largeTitle.bold())
                Text(GameText.string(trend.reason.key, locale: locale))
                Text(trend.isActive(at: store.snapshot.lastSimulationAt ?? .now) ? "trend.active" : "trend.ended")
            }
            Section {
                LabeledContent("trend.starts") { Text(trend.startsAt, format: .dateTime.day().month().hour().minute().locale(locale)) }
                LabeledContent("trend.ends") { Text(trend.endsAt, format: .dateTime.day().month().hour().minute().locale(locale)) }
                if trend.isActive(at: store.snapshot.lastSimulationAt ?? .now) {
                    DeadlineView(store: store, target: trend.endsAt, titleKey: "trend.remaining")
                }
            }
            Text("trend.explanation").foregroundStyle(.secondary)
        }.gameScreen().navigationTitle("trend.title")
    }
}
