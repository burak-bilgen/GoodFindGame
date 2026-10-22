import Testing
import UIKit
@testable import ProjectFlip

struct ProductPhotoTests {
    @Test @MainActor func catalogHasPackagedPhotographsForEveryCondition() throws {
        let definitions = try SeedContent.load().items
        let families = try Set(definitions.map { definition in
            try #require(ProductPhoto.family(identity: definition.id, symbol: definition.artSymbol))
        })
        for family in families.union(ProductPhoto.dedicatedModels.map { "model-" + $0 }) {
            for scene in 0..<ProductPhoto.sceneCount(family: family) {
                var encoded: Set<Data> = []
                for wear in [ItemAppearance.Wear.excellent, .good, .fair, .poor] {
                    let name = ProductPhoto.asset(family: family, wear: wear, scene: scene)
                    let image = try #require(UIImage(named: name), "Missing packaged photograph: \(name)")
                    #expect(image.size.width >= 500 && image.size.height >= 500)
                    encoded.insert(try #require(image.pngData()))
                }
                #expect(encoded.count == 4, "Cosmetic conditions must have distinct photographs")
            }
        }
    }

    @Test func neutralPresentationDoesNotChooseWorstHiddenCondition() {
        #expect(ProductPhoto.asset(family: "camera", wear: .unverified) == ProductPhoto.asset(family: "camera", wear: .good))
        #expect(ProductPhoto.family(identity: "future-0", symbol: "future") == nil)
        #expect(ProductPhoto.family(identity: "gaming-15", symbol: "gamecontroller") == "handheld")
    }
}
