// File-size packaging only: preserve artwork; one fixed photograph per product.
// Usage: swift Scripts/package_product_photo.swift <identity> <source.png>
import Foundation
import ImageIO
import UniformTypeIdentifiers
let args = CommandLine.arguments
guard args.count == 3 else { fatalError("Expected product identity and source image") }
let root = URL(fileURLWithPath: "ProjectFlip/Resources/Assets.xcassets/Product-model-\(args[1]).imageset")
let sourceURL = URL(fileURLWithPath: args[2])
guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil), let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [kCGImageSourceCreateThumbnailFromImageAlways: true, kCGImageSourceThumbnailMaxPixelSize: 768, kCGImageSourceCreateThumbnailWithTransform: true] as CFDictionary) else { fatalError("Invalid source") }
try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
guard let destination = CGImageDestinationCreateWithURL(root.appendingPathComponent("photo.jpg") as CFURL, UTType.jpeg.identifier as CFString, 1, nil) else { fatalError("Invalid destination") }
CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.74] as CFDictionary)
guard CGImageDestinationFinalize(destination) else { fatalError("JPEG failed") }
let manifest: [String: Any] = ["images": [["filename": "photo.jpg", "idiom": "universal"]], "info": ["author": "xcode", "version": 1]]
try JSONSerialization.data(withJSONObject: manifest, options: [.prettyPrinted, .sortedKeys]).write(to: root.appendingPathComponent("Contents.json"))
