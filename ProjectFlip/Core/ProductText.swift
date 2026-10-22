import Foundation

extension ItemDefinition {
    /// Presentation names explain the product type. IDs, seed metadata and saved
    /// item truth remain stable; legacy names stay searchable for existing players.
    func displayName(locale: Locale) -> String {
        GameText.string("product.name.\(id)", locale: locale)
    }
}
