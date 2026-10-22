import SwiftUI

/// Navigation only: badges represent actual waiting buyer offers.
struct GameDock: View {
    @Binding var selection: Int
    let waitingBuyers: Int
    var onReselect: (Int) -> Void = { _ in }
    @Namespace private var highlight
    @GameReduceMotion private var reduceMotion
    @Environment(\.locale) private var locale
    @Environment(\.marketConfiguration) private var market
    @Environment(\.dynamicTypeSize) private var typeSize
    private let tabs = [("market.title", "square.grid.2x2.fill"), ("messages.title", "bubble.left.and.bubble.right.fill"), ("inventory.title", "shippingbox.fill"), ("shop.title", "storefront.fill"), ("profile.title", "person.crop.circle.fill")]
    var body: some View {
        HStack(spacing: 3) {
            ForEach(tabs.indices, id: \.self) { index in
                Button {
                    if selection == index { onReselect(index) }
                    withAnimation(reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.78)) { selection = index }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: tabs[index].1)
                            .font(.system(size: 21, weight: .bold))
                            .symbolEffect(.bounce, options: .nonRepeating, value: reduceMotion ? false : selection == index)
                        if !typeSize.isAccessibilitySize {
                            Text(GameText.string(tabs[index].0, locale: locale))
                                .font(.system(.caption2, design: .rounded, weight: .heavy))
                                .lineLimit(1).minimumScaleFactor(0.7)
                        }
                    }
                    .foregroundStyle(selection == index ? GameStyle.ink : Color(red: 0.65, green: 0.74, blue: 0.8))
                    .frame(maxWidth: .infinity).frame(height: 58)
                    .background {
                        if selection == index {
                            RoundedRectangle(cornerRadius: 13).fill(LinearGradient(colors: [GameStyle.gain, Color(red: 0.30, green: 0.75, blue: 0.69)], startPoint: .top, endPoint: .bottom))
                                .matchedGeometryEffect(id: "selectedTab", in: highlight)
                        }
                    }
                    .overlay(alignment: .topTrailing) {
                        if index == 3 && waitingBuyers > 0 {
                            Text(waitingBuyers, format: .number).font(.caption2.bold()).foregroundStyle(GameStyle.ink)
                                .padding(4).background(GameStyle.amber, in: Circle()).offset(x: -2, y: -3)
                        }
                    }
                    .contentShape(Rectangle())
                }.buttonStyle(.plain)
                    .accessibilityLabel(Text(GameText.string(tabs[index].0, locale: locale)))
                    .accessibilityIdentifier("gameTab.\(index)")
                    .accessibilityAddTraits(selection == index ? .isSelected : [])
            }
        }.padding(7)
            .background(GameStyle.ink, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(GameStyle.line, lineWidth: 1))
            .shadow(color: .black.opacity(0.5), radius: 12, y: 5)
            .padding(.horizontal, 12).padding(.top, 8).padding(.bottom, 5)
            .background(LinearGradient(colors: [GameStyle.ink.opacity(0), GameStyle.ink], startPoint: .top, endPoint: .bottom))
            .accessibilityElement(children: .contain)
    }
}
