import SwiftUI

extension View {
    func gameEntrance() -> some View { modifier(GameEntrance()) }
}

/// Appearance affects opacity only: controls never slide away from an incoming tap.
private struct GameEntrance: ViewModifier {
    @GameReduceMotion private var reduceMotion
    @State private var visible = false
    func body(content: Content) -> some View {
        content.opacity(visible || reduceMotion ? 1 : 0)
            .onAppear { withAnimation(reduceMotion ? nil : .easeOut(duration: 0.22)) { visible = true } }
    }
}

/// Decorative radar, not a forecast of stock or an undiscovered bargain.
struct GameScanner: View {
    var size: CGFloat = 70
    @GameReduceMotion private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    var body: some View {
        Group {
            if reduceMotion { radar(phase: 0.18) }
            else {
                TimelineView(.animation(minimumInterval: 1.0 / 15, paused: scenePhase != .active)) { timeline in
                    radar(phase: timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 6) / 6)
                }
            }
        }.frame(width: size, height: size).accessibilityHidden(true).allowsHitTesting(false)
    }
    private func radar(phase: Double) -> some View {
        Canvas { context, bounds in
            let center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
            let radius = bounds.width * 0.43
            for ratio in [0.42, 0.72, 1.0] {
                context.stroke(Path(ellipseIn: CGRect(x: center.x - radius * ratio, y: center.y - radius * ratio, width: radius * ratio * 2, height: radius * ratio * 2)), with: .color(GameStyle.gain.opacity(0.22)), lineWidth: 1)
            }
            for index in 0..<12 {
                let angle = Double(index) * .pi / 6
                let a = CGPoint(x: center.x + cos(angle) * radius * 0.90, y: center.y + sin(angle) * radius * 0.90)
                let b = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
                context.stroke(Path { $0.move(to: a); $0.addLine(to: b) }, with: .color(GameStyle.gain.opacity(0.5)), lineWidth: 1.5)
            }
            let angle = phase * .pi * 2
            for trail in 0..<16 {
                let a = angle - Double(trail) * 0.035
                context.stroke(Path { $0.move(to: center); $0.addLine(to: CGPoint(x: center.x + cos(a) * radius, y: center.y + sin(a) * radius)) }, with: .color(GameStyle.gain.opacity(Double(16 - trail) / 55)), lineWidth: 2)
            }
            context.fill(Path(ellipseIn: CGRect(x: center.x - 3, y: center.y - 3, width: 6, height: 6)), with: .color(GameStyle.amber))
        }
    }
}

/// Moving lights identify real pending work without inventing completion percentages.
struct GameActivityLights: View {
    @GameReduceMotion private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    var body: some View {
        Group {
            if reduceMotion { lights(phase: 0) }
            else {
                TimelineView(.animation(minimumInterval: 1.0 / 12, paused: scenePhase != .active)) { timeline in
                    lights(phase: timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1.8) / 1.8)
                }
            }
        }.frame(width: 34, height: 10).accessibilityHidden(true).allowsHitTesting(false)
    }
    private func lights(phase: Double) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<4) { index in
                RoundedRectangle(cornerRadius: 2).fill(GameStyle.gain.opacity(reduceMotion || Int(phase * 4) == index ? 1 : 0.2))
            }
        }
    }
}

/// Short payoff particles stay inside the outcome panel. No invented rewards.
struct GamePayoffBurst: View {
    @GameReduceMotion private var reduceMotion
    @State private var progress: CGFloat = 0
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if !reduceMotion {
                    ForEach(0..<18) { index in
                        let angle = Double(index) * .pi * 2 / 18
                        let distance = CGFloat(index % 3 + 2) * 22 * progress
                        RoundedRectangle(cornerRadius: 1)
                            .fill(index % 3 == 0 ? GameStyle.gain : GameStyle.amber)
                            .frame(width: 4, height: index % 2 == 0 ? 8 : 4)
                            .rotationEffect(.degrees(Double(index * 23) + Double(progress) * 120))
                            .position(x: geometry.size.width * 0.5, y: geometry.size.height * 0.35)
                            .offset(x: cos(angle) * distance, y: sin(angle) * distance + 35 * progress * progress)
                            .opacity(Double(1 - progress))
                    }
                }
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
            .onAppear { guard !reduceMotion else { return }; withAnimation(.easeOut(duration: 0.85)) { progress = 1 } }
    }
}
