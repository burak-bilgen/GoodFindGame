import SwiftUI

/// Original vector toy-like still lifes. Identity controls palette, never hidden condition.
struct DeviceArt: View {
    let symbol: String
    var identity: String = "gaming-0"
    private var category: ItemCategory {
        identity.hasPrefix("cameras") ? .cameras : identity.hasPrefix("retro") ? .retro : .gaming
    }
    var body: some View {
        let accent = GameStyle.light(category)
        Canvas { context, size in
            let scale = min(size.width / 240, size.height / 155)
            context.translateBy(x: size.width / 2, y: size.height / 2)
            context.scaleBy(x: scale, y: scale)
            let variation = Int(SeededRandom.seed(for: identity) % 4)
            let shell = [Color(red: 0.90, green: 0.80, blue: 0.60), Color(red: 0.65, green: 0.77, blue: 0.77), Color(red: 0.82, green: 0.65, blue: 0.60), Color(red: 0.72, green: 0.68, blue: 0.82)][variation]
            func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ radius: CGFloat, _ color: Color) {
                let shape = Path(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: radius)
                context.fill(shape, with: .linearGradient(Gradient(colors: [color, color.opacity(0.78)]), startPoint: CGPoint(x: x, y: y), endPoint: CGPoint(x: x+w, y: y+h)))
                context.stroke(shape, with: .color(.white.opacity(0.16)), lineWidth: 0.8)
            }
            func circle(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ color: Color) {
                context.fill(Path(ellipseIn: CGRect(x: x-r, y: y-r, width: r*2, height: r*2)), with: .color(color))
            }
            context.fill(Path(ellipseIn: CGRect(x: -83, y: 43, width: 166, height: 18)), with: .color(.black.opacity(0.45)))
            context.rotate(by: .degrees(Double([-10, 7, -5, 12][variation])))
            if category == .cameras {
                if !symbol.contains("aperture") {
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
                if symbol == "opticaldisc" {
                    circle(0, 0, 58, shell); circle(0, 0, 43, accent); circle(0, 0, 12, GameStyle.ink)
                    rect(-38, -30, 40, 7, 3, .white.opacity(0.5))
                } else if symbol == "gamecontroller" || symbol == "tv" {
                    rect(-62, -60, 124, 122, 14, shell)
                    rect(-51, -49, 102, 65, 6, GameStyle.ink); rect(-43, -41, 86, 49, 2, accent)
                    rect(-42, 26, 10, 28, 2, GameStyle.ink); rect(-51, 35, 28, 10, 2, GameStyle.ink)
                    circle(30, 40, 7, GameStyle.ink); circle(46, 30, 7, GameStyle.ink)
                } else if symbol == "rectangle.stack" {
                    rect(-51, -60, 102, 120, 8, shell)
                    rect(-41, -46, 82, 67, 4, accent)
                    circle(0, -12, 22, GameStyle.ink)
                    rect(-16, -16, 32, 8, 2, shell)
                    for line in 0..<6 { rect(CGFloat(line*12)-34, 35, 5, 20, 1, GameStyle.ink) }
                } else {
                rect(-65, -54, 130, 112, 10, GameStyle.ink)
                rect(-58, -47, 116, 77, 5, shell)
                rect(-41, -30, 82, 44, 3, accent)
                circle(0, -8, 14, .white.opacity(0.4))
                for line in 0..<5 { rect(CGFloat(line*18)-41, 39, 10, 14, 2, shell) }
                rect(-21, -58, 42, 8, 2, GameStyle.ink)
                }
            } else if symbol.contains("hifispeaker") || symbol.contains("externaldrive") {
                rect(-47, -58, 94, 119, 13, shell)
                if symbol.contains("hifispeaker") {
                    circle(0, -24, 17, GameStyle.ink); circle(0, 25, 29, GameStyle.ink); circle(0, 25, 15, accent)
                } else {
                    rect(-33, -41, 66, 7, 2, GameStyle.ink); rect(-33, -26, 66, 7, 2, GameStyle.ink)
                    circle(24, 40, 4, accent)
                }
            } else if symbol.contains("headphone") {
                let arc = Path { p in p.addArc(center: CGPoint(x: 0, y: 3), radius: 49, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false) }
                context.stroke(arc, with: .color(GameStyle.ink), style: StrokeStyle(lineWidth: 18, lineCap: .round))
                rect(-63, -3, 32, 63, 14, shell); rect(31, -3, 32, 63, 14, shell)
                rect(-35, 3, 9, 50, 4, GameStyle.ink); rect(26, 3, 9, 50, 4, GameStyle.ink)
            } else if symbol.contains("desktop") {
                rect(-45, -60, 90, 120, 12, shell)
                rect(-35, -49, 70, 98, 7, GameStyle.ink)
                for y in 0..<4 { rect(-25, CGFloat(y * 13) - 34, 50, 5, 2, accent.opacity(0.65)) }
                circle(23, 34, 5, accent)
                rect(-28, 55, 12, 9, 2, GameStyle.ink); rect(17, 55, 12, 9, 2, GameStyle.ink)
            } else if symbol.contains("display") {
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
        .background {
            GeometryReader { geometry in
                ZStack {
                    LinearGradient(colors: [Color(red: 0.15, green: 0.23, blue: 0.30), GameStyle.ink], startPoint: .topLeading, endPoint: .bottomTrailing)
                    Circle().fill(RadialGradient(colors: [accent.opacity(0.38), accent.opacity(0)], center: .center, startRadius: 0, endRadius: geometry.size.width * 0.55))
                        .frame(width: geometry.size.width * 1.2, height: geometry.size.width * 1.2)
                    Canvas { context, size in
                        let center = CGPoint(x: size.width / 2, y: size.height / 2)
                        for ring in 1...3 {
                            let radius = CGFloat(ring) * min(size.width, size.height) * 0.22
                            context.stroke(Path(ellipseIn: CGRect(x: center.x-radius, y: center.y-radius, width: radius*2, height: radius*2)), with: .color(accent.opacity(0.10)), lineWidth: 1)
                        }
                        for x in stride(from: CGFloat(14), to: size.width, by: 22) {
                            for y in stride(from: CGFloat(14), to: size.height, by: 22) {
                                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1.5, height: 1.5)), with: .color(.white.opacity(0.10)))
                            }
                        }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.white.opacity(0.12), lineWidth: 1))
        .accessibilityHidden(true)
    }
}
