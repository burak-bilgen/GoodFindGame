// Deterministic file-size optimization only. Artwork is generated/edited separately.
// Usage: swift Scripts/optimize_product_photos.swift <Assets.xcassets> [--apply]
import Foundation
import ImageIO
import UniformTypeIdentifiers

let arguments = CommandLine.arguments
let root = URL(fileURLWithPath: arguments.count > 1 ? arguments[1] : "ProjectFlip/Resources/Assets.xcassets")
let apply = arguments.contains("--apply")
var before = 0, after = 0, changed = 0
for folder in try FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil).filter({ $0.lastPathComponent.hasPrefix("Product-") && $0.pathExtension == "imageset" }) {
    for file in try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil).filter({ ["jpg", "jpeg"].contains($0.pathExtension.lowercased()) }) {
        let original = try Data(contentsOf: file)
        before += original.count
        guard let source = CGImageSourceCreateWithData(original as CFData, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [kCGImageSourceCreateThumbnailFromImageAlways: true, kCGImageSourceThumbnailMaxPixelSize: 768, kCGImageSourceCreateThumbnailWithTransform: true] as CFDictionary) else { continue }
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil) else { continue }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.74] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { continue }
        // Avoid repeatedly re-encoding already small files for negligible savings.
        if output.length < original.count * 85 / 100 {
            changed += 1; after += output.length
            if apply { try (output as Data).write(to: file, options: .atomic) }
        } else { after += original.count }
    }
}
print("\(apply ? "Optimized" : "Preview") \(changed) photos: \(before) → \(after) bytes. Artwork and condition selection unchanged.")
