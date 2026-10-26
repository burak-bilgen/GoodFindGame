import Foundation
import Testing
@testable import ProjectFlip

struct LanguageTests {
    @Test func dynamicContentUsesSelectedLanguageAndFallsBackForUnsupportedLanguages() {
        for (code, market, person, place, product) in [
            ("de_DE", "Markt", "Jana", "Flussufer", "Hearth Kaffeemaschine"),
            ("fr_FR", "Marché", "Julien", "Les Berges", "Cafetière Hearth"),
            ("es_ES", "Mercado", "Lucía", "La Ribera", "Cafetera Hearth"),
            ("it_IT", "Mercato", "Giulia", "Lungofiume", "Macchina da caffè Hearth")
        ] {
            let locale = Locale(identifier: code)
            #expect(GameText.string("market.title", locale: locale) == market)
            #expect(GameText.marketPerson("name", index: 1, market: .us, locale: locale) == person)
            #expect(GameText.marketPerson("city", index: 1, market: .us, locale: locale) == place)
            #expect(GameText.string("product.name.home-0", locale: locale) == product)
            #expect(GameText.string("selling.title", locale: locale) != GameText.string("selling.title", locale: Locale(identifier: "en")))
            let notification = GameText.format("notifications.priceDrop", locale: locale, "Test item", "42")
            #expect(notification.contains("Test item") && notification.contains("42") && !notification.contains("%@"))
        }
        #expect(GameText.string("product.name.gaming-0", locale: Locale(identifier: "de")) == "Arc Funkcontroller")
        #expect(GameText.string("product.name.gaming-0", locale: Locale(identifier: "fr")) == "Manette sans fil Arc")
        #expect(GameText.string("product.name.cameras-11", locale: Locale(identifier: "tr")) == "Field Zoom Objektif")
        #expect(GameText.string("market.title", locale: Locale(identifier: "ja_JP")) == "Market")
        #expect(GameText.string("market.title", locale: Locale(identifier: "fr_CA")) == "Marché")
    }
}
