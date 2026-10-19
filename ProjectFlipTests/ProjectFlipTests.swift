import Foundation
import Testing
@testable import ProjectFlip

struct LocalizationTests {
    @Test(arguments: ["en", "tr"])
    func shellTranslationsExist(language: String) throws {
        let path = try #require(Bundle.main.path(forResource: language, ofType: "lproj"))
        let bundle = try #require(Bundle(path: path))
        for key in ["market.title", "market.empty", "messages.title", "messages.empty", "inventory.title", "inventory.empty", "selling.title", "selling.empty", "profile.title", "profile.intro"] + (0..<10).flatMap({ ["npc.name.\($0)", "npc.city.\($0)"] }) + Defect.allCases.map(\.key) {
            #expect(bundle.localizedString(forKey: key, value: nil, table: "Localizable") != key)
        }
    }
}
