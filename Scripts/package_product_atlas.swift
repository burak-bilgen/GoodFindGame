// Build-time packaging only: split an imagegen 2x2 atlas without retouching its artwork.
// Usage: swift Scripts/package_product_atlas.swift family source.png
import AppKit
import Foundation

guard CommandLine.arguments.count == 3 else { fatalError("Expected family and source atlas") }
let family = CommandLine.arguments[1]
let source = URL(fileURLWithPath: CommandLine.arguments[2])
guard let image = NSImage(contentsOf: source), let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil), cg.width == cg.height, cg.width % 2 == 0 else { fatalError("Expected even square atlas") }
// Trim two boundary pixels so a generated quadrant separator never enters a photo.
let edge = cg.width / 2
let root = URL(fileURLWithPath: "ProjectFlip/Resources/Assets.xcassets")
for (index, condition) in ["excellent", "good", "fair", "poor"].enumerated() {
    guard let crop = cg.cropping(to: CGRect(x: index % 2 * edge + 2, y: index / 2 * edge + 2, width: edge - 4, height: edge - 4)) else { fatalError("Crop failed") }
    let folder = root.appendingPathComponent("Product-\(family)-\(condition).imageset")
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    let bitmap = NSBitmapImageRep(cgImage: crop)
    guard let data = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.9]) else { fatalError("JPEG failed") }
    try data.write(to: folder.appendingPathComponent("photo.jpg"))
    let manifest: [String: Any] = ["images": [["filename": "photo.jpg", "idiom": "universal"]], "info": ["author": "xcode", "version": 1]]
    try JSONSerialization.data(withJSONObject: manifest, options: [.prettyPrinted, .sortedKeys]).write(to: folder.appendingPathComponent("Contents.json"))
    print("Packaged \(family) \(condition): \(edge - 4)x\(edge - 4)")
}
