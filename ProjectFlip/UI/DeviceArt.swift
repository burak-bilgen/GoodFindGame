import SwiftUI

/// Original vector toy-like still lifes. Identity controls palette, never hidden condition.
struct DeviceArt: View {
    let symbol: String
    var identity: String = "gaming-0"
    private var category: ItemCategory {
        identity.hasPrefix("cameras") ? .cameras : identity.hasPrefix("retro") ? .retro : .gaming
    }
    var body: some View {
        let accent = GameStyle.category(category)
        Canvas { context, size in
            let scale = min(size.width / 240, size.height / 155)
            context.translateBy(x: size.width / 2, y: size.height / 2)
            context.scaleBy(x: scale, y: scale)
            let variation = Int(SeededRandom.seed(for: identity) % 4)
            let shell = [Color(red: 0.90, green: 0.80, blue: 0.60), Color(red: 0.65, green: 0.77, blue: 0.77), Color(red: 0.82, green: 0.65, blue: 0.60), Color(red: 0.72, green: 0.68, blue: 0.82)][variation]
            func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ radius: CGFloat, _ color: Color) {
                context.fill(Path(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: radius), with: .color(color))
            }
            func circle(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ color: Color) {
                context.fill(Path(ellipseIn: CGRect(x: x-r, y: y-r, width: r*2, height: r*2)), with: .color(color))
            }
            context.fill(Path(ellipseIn: CGRect(x: -83, y: 43, width: 166, height: 18)), with: .color(.black.opacity(0.12)))
            context.rotate(by: .degrees(-8))
            if category == .cameras {
                if symbol.contains("camera") {
                    rect(-76, -38, 152, 90, 15, GameStyle.ink)
                    rect(-58, -55, 42, 20, 6, GameStyle.ink)
                    rect(-75, -13, 150, 45, 3, shell)
                    rect(48, -34, 18, 9, 3, .white.opacity(0.7))
                    circle(4, 6, 43, GameStyle.ink); circle(4, 6, 33, accent)
                    circle(4, 6, 24, GameStyle.ink); circle(-3, -2, 9, .white.opacity(0.25))
                    rect(-66, -31, 19, 12, 3, .white.opacity(0.65))
                } else {
                    rect(-51, -53, 102, 111, 15, GameStyle.ink)
                    for line in 0..<7 { rect(-48, CGFloat(line*12)-37, 96, 3, 1, shell.opacity(0.6)) }
                    circle(0, -38, 47, shell); circle(0, -38, 37, GameStyle.ink)
                    circle(0, -38, 27, accent); circle(-6, -43, 11, .white.opacity(0.25))
                }
            } else if category == .retro {
                rect(-65, -54, 130, 112, 10, GameStyle.ink)
                rect(-58, -47, 116, 77, 5, shell)
                rect(-41, -30, 82, 44, 3, accent)
                circle(0, -8, 14, .white.opacity(0.4))
                for line in 0..<5 { rect(CGFloat(line*18)-41, 39, 10, 14, 2, shell) }
                rect(-21, -58, 42, 8, 2, GameStyle.ink)
            } else if symbol.contains("headphone") {
                let arc = Path { p in p.addArc(center: CGPoint(x: 0, y: 3), radius: 49, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false) }
                context.stroke(arc, with: .color(GameStyle.ink), style: StrokeStyle(lineWidth: 18, lineCap: .round))
                rect(-63, -3, 32, 63, 14, shell); rect(31, -3, 32, 63, 14, shell)
                rect(-35, 3, 9, 50, 4, GameStyle.ink); rect(26, 3, 9, 50, 4, GameStyle.ink)
            } else if variation == 1 || symbol.contains("display") || symbol.contains("desktop") {
                rect(-72, -52, 144, 98, 11, shell)
                rect(-62, -42, 124, 71, 5, GameStyle.ink)
                rect(-49, -28, 48, 5, 2, accent); rect(-49, -16, 77, 4, 2, accent.opacity(0.5))
                rect(-8, 44, 16, 16, 3, GameStyle.ink); rect(-36, 57, 72, 5, 2, GameStyle.ink)
            } else {
                let body = Path { p in
                    p.move(to: CGPoint(x: -52, y: -35)); p.addQuadCurve(to: CGPoint(x: 52, y: -35), control: CGPoint(x: 0, y: -50))
                    p.addCurve(to: CGPoint(x: 79, y: 48), control1: CGPoint(x: 78, y: -25), control2: CGPoint(x: 100, y: 60))
                    p.addQuadCurve(to: CGPoint(x: 32, y: 22), control: CGPoint(x: 63, y: 66))
                    p.addLine(to: CGPoint(x: -32, y: 22)); p.addQuadCurve(to: CGPoint(x: -79, y: 48), control: CGPoint(x: -63, y: 66))
                    p.addCurve(to: CGPoint(x: -52, y: -35), control1: CGPoint(x: -100, y: 60), control2: CGPoint(x: -78, y: -25)); p.closeSubpath()
                }
                context.fill(body, with: .color(shell))
                rect(-51, -17, 10, 32, 2, GameStyle.ink); rect(-62, -6, 32, 10, 2, GameStyle.ink)
                circle(45, -14, 7, accent); circle(58, 0, 7, GameStyle.ink)
                circle(32, 0, 7, GameStyle.ink); circle(45, 14, 7, accent)
                circle(-17, 20, 11, GameStyle.ink); circle(15, 20, 11, GameStyle.ink)
                rect(-11, -21, 22, 5, 2, .white.opacity(0.7))
            }
        }
        .background(LinearGradient(colors: [accent.opacity(0.10), accent.opacity(0.22)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityHidden(true)
    }
}
