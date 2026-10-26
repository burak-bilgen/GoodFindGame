import SwiftUI

/// Navigation only: badges represent actual waiting buyer offers.
struct GameDock: View {
    private static let rowHeight: CGFloat = 58
    private static let innerPadding: CGFloat = 7
    private static let topPadding: CGFloat = 8
    private static let bottomPadding: CGFloat = 5
    static var scrollClearance: CGFloat { rowHeight + innerPadding * 2 + topPadding + bottomPadding }

    @Binding var selection: Int
    let waitingBuyers: Int
    var onReselect: (Int) -> Void = { _ in }
    @Namespace private var highlight
    @GameReduceMotion private var reduceMotion
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market
    @Environment(\.dynamicTypeSize) private var typeSize
    private let tabs = [("market.title", "square.grid.2x2"), ("messages.title", "bubble.left.and.bubble.right"), ("inventory.title", "shippingbox"), ("selling.title", "tag"), ("profile.title", "person.crop.circle")]
    var body: some View {
        HStack(spacing: 3) {
            ForEach(tabs.indices, id: \.self) { index in
                Button {
                    if selection == index { onReselect(index) }
                    withAnimation(reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.78)) { selection = index }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: tabs[index].1)
                            .font(.system(size: 21, weight: .medium))
                            .symbolEffect(.bounce, options: .nonRepeating, value: reduceMotion ? false : selection == index)
                        if !typeSize.isAccessibilitySize {
                            Text(GameText.string(tabs[index].0, locale: locale))
                                .font(.system(.caption2, design: .default, weight: .semibold))
                                .lineLimit(1).minimumScaleFactor(0.7)
                        }
                    }
                    .foregroundStyle(selection == index ? GameStyle.gain : GameStyle.secondaryText)
                    .frame(maxWidth: .infinity).frame(height: Self.rowHeight)
                    .background {
                        if selection == index {
                            RoundedRectangle(cornerRadius: 14).fill(GameStyle.gain.opacity(0.12))
                                .matchedGeometryEffect(id: "selectedTab", in: highlight)
                        }
                    }
                    .overlay(alignment: .topTrailing) {
                        if index == 3 && waitingBuyers > 0 {
                            Text(waitingBuyers, format: .number).font(.caption2.bold()).foregroundStyle(GameStyle.ink)
                                .padding(4).background(GameStyle.amber, in: Circle()).offset(x: -2, y: -3)
                                .accessibilityHidden(true)
                        }
                    }
                    .contentShape(Rectangle())
                }.buttonStyle(.plain)
                    .accessibilityLabel(Text(GameText.string(tabs[index].0, locale: locale)))
                    .accessibilityValue(index == 3 && waitingBuyers > 0 ? Text("journey.offerWaiting") : Text(verbatim: ""))
                    .accessibilityIdentifier("gameTab.\(index)")
                    .accessibilityAddTraits(selection == index ? .isSelected : [])
            }
        }.padding(Self.innerPadding)
            .background(GameStyle.panel, in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(GameStyle.line.opacity(0.65), lineWidth: 0.75))
            .shadow(color: .black.opacity(0.22), radius: 16, y: 6)
            .padding(.horizontal, 12).padding(.top, Self.topPadding).padding(.bottom, Self.bottomPadding)
            .background(LinearGradient(colors: [GameStyle.ink.opacity(0), GameStyle.ink], startPoint: .top, endPoint: .bottom))
            .accessibilityElement(children: .contain)
    }
}
