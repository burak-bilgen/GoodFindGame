import AppKit

// Original controller silhouette from DeviceArt.swift, with the game's ink/mint/amber palette.
// Render offscreen: swift Scripts/render_app_icon.swift <output.png>
let output = CommandLine.arguments.dropFirst().first ?? "ProjectFlip/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
enum IconRenderError: Error { case context, gradient, encoding }
let edge = 1024
let space = CGColorSpaceCreateDeviceRGB()
guard let context = CGContext(data: nil, width: edge, height: edge, bitsPerComponent: 8, bytesPerRow: edge * 4, space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
    throw IconRenderError.context
}
func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: r, green: g, blue: b, alpha: a)
}
let ink = color(0.065, 0.11, 0.17)
let mint = color(0.36, 0.83, 0.80)
let amber = color(1, 0.70, 0.32)
func gradient(_ colors: [CGColor], from start: CGPoint, to end: CGPoint) throws {
    guard let fill = CGGradient(colorsSpace: space, colors: colors as CFArray, locations: nil) else { throw IconRenderError.gradient }
    context.drawLinearGradient(fill, start: start, end: end, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
}
func fill(_ path: CGPath, _ color: CGColor) {
    context.addPath(path); context.setFillColor(color); context.fillPath()
}
func circle(_ x: CGFloat, _ y: CGFloat, _ radius: CGFloat, _ color: CGColor) {
    context.setFillColor(color); context.fillEllipse(in: CGRect(x: x-radius, y: y-radius, width: radius*2, height: radius*2))
}
func rect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat, _ radius: CGFloat, _ color: CGColor) {
    fill(CGPath(roundedRect: CGRect(x: x, y: y, width: width, height: height), cornerWidth: radius, cornerHeight: radius, transform: nil), color)
}
context.translateBy(x: 0, y: CGFloat(edge)); context.scaleBy(x: 1, y: -1)
try gradient([color(0.18, 0.31, 0.37), ink], from: .zero, to: CGPoint(x: 850, y: 1024))
// An illuminated collectible card and price tag, not a coin/finance logo.
context.saveGState()
context.translateBy(x: 430, y: 470); context.rotate(by: -0.16)
context.setShadow(offset: CGSize(width: 0, height: 25), blur: 30, color: color(0, 0, 0, 0.30))
rect(-255, -260, 510, 530, 60, color(0.22, 0.43, 0.47))
context.restoreGState()
context.saveGState()
context.translateBy(x: 430, y: 470); context.rotate(by: -0.16)
let outline = CGPath(roundedRect: CGRect(x: -255, y: -260, width: 510, height: 530), cornerWidth: 60, cornerHeight: 60, transform: nil)
context.addPath(outline); context.setStrokeColor(color(0.60, 0.92, 0.88, 0.42)); context.setLineWidth(9); context.strokePath()
context.restoreGState()
let tag = CGMutablePath()
tag.move(to: CGPoint(x: 530, y: 165)); tag.addLine(to: CGPoint(x: 720, y: 165))
tag.addQuadCurve(to: CGPoint(x: 750, y: 180), control: CGPoint(x: 740, y: 165))
tag.addLine(to: CGPoint(x: 875, y: 300)); tag.addQuadCurve(to: CGPoint(x: 875, y: 340), control: CGPoint(x: 897, y: 320))
tag.addLine(to: CGPoint(x: 750, y: 462)); tag.addQuadCurve(to: CGPoint(x: 720, y: 477), control: CGPoint(x: 740, y: 477))
tag.addLine(to: CGPoint(x: 530, y: 477)); tag.addQuadCurve(to: CGPoint(x: 500, y: 447), control: CGPoint(x: 500, y: 477))
tag.addLine(to: CGPoint(x: 500, y: 195)); tag.addQuadCurve(to: CGPoint(x: 530, y: 165), control: CGPoint(x: 500, y: 165)); tag.closeSubpath()
context.saveGState(); context.setShadow(offset: CGSize(width: 0, height: 17), blur: 22, color: color(0, 0, 0, 0.32)); fill(tag, amber); context.restoreGState()
circle(817, 320, 22, ink)
// A compact exchange cue. No currency symbol, fake rarity, lettering or real product mark.
let arrow = CGMutablePath()
arrow.move(to: CGPoint(x: 253, y: 350)); arrow.addCurve(to: CGPoint(x: 360, y: 270), control1: CGPoint(x: 248, y: 278), control2: CGPoint(x: 310, y: 249))
context.addPath(arrow); context.setLineWidth(22); context.setLineCap(.round); context.setStrokeColor(mint); context.strokePath()
let arrowhead = CGMutablePath(); arrowhead.move(to: CGPoint(x: 334, y: 236)); arrowhead.addLine(to: CGPoint(x: 373, y: 275)); arrowhead.addLine(to: CGPoint(x: 320, y: 284))
context.addPath(arrowhead); context.setLineJoin(.round); context.strokePath()
context.saveGState()
context.translateBy(x: 512, y: 619); context.rotate(by: -0.09); context.scaleBy(x: 4.4, y: 4.4)
let body = CGMutablePath()
body.move(to: CGPoint(x: -52, y: -35)); body.addQuadCurve(to: CGPoint(x: 52, y: -35), control: CGPoint(x: 0, y: -50))
body.addCurve(to: CGPoint(x: 79, y: 48), control1: CGPoint(x: 78, y: -25), control2: CGPoint(x: 100, y: 60))
body.addQuadCurve(to: CGPoint(x: 32, y: 22), control: CGPoint(x: 63, y: 66)); body.addLine(to: CGPoint(x: -32, y: 22))
body.addQuadCurve(to: CGPoint(x: -79, y: 48), control: CGPoint(x: -63, y: 66))
body.addCurve(to: CGPoint(x: -52, y: -35), control1: CGPoint(x: -100, y: 60), control2: CGPoint(x: -78, y: -25)); body.closeSubpath()
context.saveGState(); context.setShadow(offset: CGSize(width: 0, height: 8), blur: 8, color: color(0, 0, 0, 0.45)); fill(body, color(0.65, 0.77, 0.77)); context.restoreGState()
context.saveGState(); context.addPath(body); context.clip()
try gradient([color(0.82, 0.91, 0.87), color(0.50, 0.68, 0.71)], from: CGPoint(x: 0, y: -48), to: CGPoint(x: 15, y: 65))
context.restoreGState()
context.addPath(body); context.setStrokeColor(color(0.90, 1, 0.95, 0.65)); context.setLineWidth(1.5); context.strokePath()
rect(-51, -17, 10, 32, 2, ink); rect(-62, -6, 32, 10, 2, ink)
circle(45, -14, 7, mint); circle(58, 0, 7, ink); circle(32, 0, 7, ink); circle(45, 14, 7, mint)
circle(-17, 20, 11, ink); circle(15, 20, 11, ink)
rect(-11, -21, 22, 5, 2, color(0.96, 1, 0.98, 0.80))
context.restoreGState()
guard let image = context.makeImage(), let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else {
    throw IconRenderError.encoding
}
try png.write(to: URL(fileURLWithPath: output))
print("Rendered opaque \(edge)×\(edge) app icon")
