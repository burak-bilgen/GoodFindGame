import Foundation
import SwiftUI
import UIKit
import Testing
@testable import ProjectFlip

struct DomainTests {
    @Test func exactMoneyAndOverflow() throws {
        let price = Money(minorUnits: 10_001)
        #expect(try price.scaled(byBasisPoints: 9_500) == Money(minorUnits: 9_500))
        #expect(try price.subtracting(Money(minorUnits: 1)) == Money(minorUnits: 10_000))
        #expect(throws: MoneyError.self) { try Money(minorUnits: .max).adding(Money(minorUnits: 1)) }
        #expect(throws: MoneyError.self) { try Money(minorUnits: .min).subtracting(Money(minorUnits: 1)) }
        #expect(throws: MoneyError.self) { try Money(minorUnits: .max).scaled(byBasisPoints: 10_000) }
    }

    @Test func seedAndHiddenTruthRoundTrip() throws {
        let seed = try SeedContent.load()
        #expect(seed.items.count == 80)
        let item = ItemInstance(id: ItemID("sample"), definitionID: seed.items[0].id, condition: 63, hiddenDefects: [.drift])
        let state = PlayerState(cash: Money(minorUnits: 2_000_000), inventory: [item])
        #expect(try JSONDecoder().decode(PlayerState.self, from: JSONEncoder().encode(state)) == state)
        #expect(state.inventory[0].revealedDefects.isEmpty)
        #expect(state.inventory[0].hiddenDefects == [.drift])
    }

    @Test func moneyFormatting() {
        let value = Money(minorUnits: 123_450)
        #expect(value.formatted(locale: Locale(identifier: "tr_TR")).contains("1.235"))
        #expect(value.formatted(locale: Locale(identifier: "en_US")).contains("1,235"))
        #expect(value.formatted(locale: Locale(identifier: "en_US")).contains("$"))
        #expect(value.formatted(locale: Locale(identifier: "en_GB")).contains("$"))
        #expect(value.formatted(locale: Locale(identifier: "tr_TR"), market: .turkey).contains("₺"))
        #expect(value.formatted(locale: Locale(identifier: "en_US"), signed: true).contains("+$"))
    }
}


extension DomainTests {
    /// The native contrast scanner misreports some custom-gradient labels even
    /// above 9:1. Independently enforce the actual opaque text palette against
    /// every panel endpoint, while native UI tests audit touch targets.
    @MainActor @Test func gameTextPaletteKeepsNormalTextContrastAcrossDarkPanels() throws {
        func luminance(_ color: Color) throws -> Double {
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            let resolved = UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
            #expect(resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha))
            #expect(alpha == 1)
            func linear(_ channel: CGFloat) -> Double {
                let value = Double(channel)
                return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
            }
            return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
        }
        for background in [GameStyle.ink, GameStyle.panel, GameStyle.panelTop] {
            for foreground in [Color.white, GameStyle.secondaryText, GameStyle.amber, GameStyle.gain, GameStyle.loss] {
                let a = try luminance(foreground), b = try luminance(background)
                #expect((max(a, b) + 0.05) / (min(a, b) + 0.05) >= 4.5)
            }
        }
    }
}
