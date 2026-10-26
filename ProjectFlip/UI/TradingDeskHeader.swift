import SwiftUI

/// An instrument at the edge of the hunt, not a bank balance dashboard.
struct TradingDeskHeader: View {
    let store: GameStore
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market
    @Environment(\.dynamicTypeSize) private var typeSize
    @GameReduceMotion private var reduceMotion
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) { career; Spacer(minLength: 8); cash }
            VStack(alignment: .leading, spacing: 8) { cash; career }
        }.padding(.vertical, 4)
    }
    private var cash: some View {
        Text(store.snapshot.player.cash.formatted(locale: locale, market: market, precise: true))
            .font(.system(.title3, design: .default, weight: .semibold)).monospacedDigit()
            .lineLimit(1).minimumScaleFactor(0.6).accessibilityIdentifier("marketCash")
            .accessibilityHint(Text("wallet.cash"))
            .accessibilityValue(store.snapshot.player.cash.formatted(locale: locale, market: market, precise: true))
            .contentTransition(.numericText())
            .animation(reduceMotion ? nil : .easeOut(duration: 0.3), value: store.snapshot.player.cash)
    }
    private var career: some View {
        NavigationLink { TraderCareerView(store: store) } label: {
            let tier = store.snapshot.career.tier(knowledge: store.snapshot.inspectionKnowledge)
            HStack(spacing: 6) {
                Image(systemName: "seal").foregroundStyle(GameStyle.amber)
                Text(GameText.string(tier.key, locale: locale)).lineLimit(1)
                if let next = CareerTier(rawValue: tier.rawValue + 1) {
                    Text(verbatim: "\(min(store.snapshot.career.creditedItems.count, next.requiredSales))/\(next.requiredSales)")
                        .monospacedDigit().foregroundStyle(GameStyle.secondaryText)
                }
                Image(systemName: "chevron.right").font(.caption2)
            }.font(.caption.weight(.medium)).frame(minHeight: 44).contentShape(Rectangle())
        }.buttonStyle(.plain).frame(minHeight: 44).contentShape(Rectangle())
            .accessibilityElement(children: .combine).accessibilityIdentifier("careerHunt")
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
