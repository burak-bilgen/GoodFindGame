import SwiftUI

/// An instrument at the edge of the hunt, not a bank balance dashboard.
struct TradingDeskHeader: View {
    let store: GameStore
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market
    @Environment(\.dynamicTypeSize) private var typeSize
    @GameReduceMotion private var reduceMotion
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("region.shared", systemImage: "location.fill")
                    .font(.caption2.bold()).foregroundStyle(GameStyle.amber)
                Spacer(minLength: 4)
                Text(store.snapshot.player.cash.formatted(locale: locale, market: market, precise: true))
                    .font(.system(.headline, design: .rounded, weight: .black)).monospacedDigit()
                    .lineLimit(1).minimumScaleFactor(0.6).accessibilityIdentifier("marketCash")
                    .accessibilityHint(Text("wallet.cash"))
                    .accessibilityValue(store.snapshot.player.cash.formatted(locale: locale, market: market, precise: true))
                    .contentTransition(.numericText())
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.3), value: store.snapshot.player.cash)
            }
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("desk.headline").font(.system(.title3, design: .rounded, weight: .black))
                }
                Spacer(minLength: 0)
                if !typeSize.isAccessibilitySize { GameScanner(size: 36) }
            }
        }.gameCard(accent: GameStyle.amber)
    }
}

/// A brief finite state acknowledgement, never a fake progress indicator.
struct DealSeal: View {
    var successful: Bool
    @GameReduceMotion private var reduceMotion
    @State private var visible = false
    var body: some View {
        Image(systemName: successful ? "checkmark.seal.fill" : "exclamationmark.seal.fill")
            .font(.system(size: 38, weight: .bold)).foregroundStyle(successful ? GameStyle.gain : GameStyle.loss)
            .scaleEffect(visible || reduceMotion ? 1 : 0.85)
            .rotationEffect(.degrees(visible || reduceMotion ? -8 : -18))
            .onAppear { withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.75)) { visible = true } }
            .accessibilityHidden(true)
    }
}
