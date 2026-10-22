import Testing
import UIKit
@testable import ProjectFlip

struct ProductPhotoTests {
    @Test @MainActor func photographedProductsHaveOnePackagedAsset() throws {
        let definitions = try SeedContent.load().items
        for definition in MarketCatalog.active(definitions) {
            guard let name = ProductPhoto.asset(identity: definition.id, symbol: definition.artSymbol) else {
                // Ordinary goods are explicitly illustrated until their own photo is authored.
                #expect([ItemCategory.home, .furniture, .everyday].contains(definition.category))
                continue
            }
            let image = try #require(UIImage(named: name), "Missing photograph: \(name)")
            #expect(image.size.width >= 500 && image.size.height >= 500)
            #expect(!name.hasSuffix("-excellent") && !name.hasSuffix("-poor"))
        }
    }
    @Test func onlyProductIdentitySelectsThePhoto() {
        #expect(ProductPhoto.asset(identity: "future-0", symbol: "future") == nil)
        #expect(ProductPhoto.asset(identity: "furniture-0", symbol: "chair") == "Product-model-furniture-0")
        #expect(ProductPhoto.family(identity: "gaming-15", symbol: "gamecontroller") == "handheld")
    }
}
