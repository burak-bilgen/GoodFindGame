import Foundation

struct EntityID<Tag>: RawRepresentable, Codable, Hashable, Sendable {
    let rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
    init(_ value: String) { rawValue = value }
}

enum ItemTag {}
enum SellerTag {}
enum ListingTag {}
enum OfferTag {}
typealias ItemID = EntityID<ItemTag>
typealias SellerID = EntityID<SellerTag>
typealias ListingID = EntityID<ListingTag>
typealias OfferID = EntityID<OfferTag>

enum ItemCategory: String, Codable, CaseIterable, Sendable { case gaming }
enum Defect: String, Codable, CaseIterable, Sendable {
    case drift, overheating, noisyFan, damagedPort, storageFailure
    var key: String { "defect.\(rawValue)" }
}

struct ItemDefinition: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let brand: String
    let model: String
    let category: ItemCategory
    let baseValue: Money
    let possibleDefects: [Defect]
    let artSymbol: String
    var name: String { "\(brand) \(model)" }
}

struct ItemInstance: Codable, Identifiable, Equatable, Sendable {
    let id: ItemID
    let definitionID: String
    let condition: Int // 0...100 generated once, never inferred from a redraw
    let hiddenDefects: [Defect]
    var revealedDefects: [Defect] = []
    var inspected = false
    var professionallyInspected = false
    var purchasePrice: Money = .zero
    var inspectionCost: Money = .zero
    var repairCost: Money = .zero
    var acquiredAt: Date?
}

enum SellerArchetype: String, Codable, CaseIterable, Sendable {
    case casual, clueless, urgent, professional, stubborn, friendly, manipulative, collector
}

struct SellerProfile: Codable, Identifiable, Equatable, Sendable {
    let id: SellerID
    let identityIndex: Int // locale content chooses display name and location
    let archetype: SellerArchetype
    let knowledge: Int
    let honesty: Int
    let urgency: Int
    let bargainingSkill: Int
    var patience: Int
    let tradeCount: Int
    let ratingTenths: Int
}

struct MarketplaceListing: Codable, Identifiable, Equatable, Sendable {
    let id: ListingID
    let item: ItemInstance
    let seller: SellerProfile
    var askingPrice: Money
    var reservationPrice: Money
    let claimedCondition: Int
    let descriptionIntent: String
    let createdAt: Date
    var available = true
}

enum OfferStatus: String, Codable, Sendable { case pending, accepted, rejected, countered, withdrawn }
struct Offer: Codable, Identifiable, Equatable, Sendable {
    let id: OfferID
    let listingID: ListingID
    let amount: Money
    var status: OfferStatus
}

struct PlayerState: Codable, Equatable, Sendable {
    var cash: Money
    var inventory: [ItemInstance] = []
    var reputation = 50
    var inventoryCapacity = 8
}

struct SeedContent: Codable, Sendable {
    let items: [ItemDefinition]
    static func load(bundle: Bundle = .main) throws -> SeedContent {
        guard let url = bundle.url(forResource: "items", withExtension: "json") else { throw ContentError.missingSeed }
        let result = try JSONDecoder().decode(Self.self, from: Data(contentsOf: url))
        guard result.items.count == 10, Set(result.items.map(\.id)).count == 10,
              result.items.allSatisfy({ $0.baseValue > .zero && !$0.possibleDefects.isEmpty }) else { throw ContentError.invalidSeed }
        return result
    }
}
enum ContentError: Error { case missingSeed, invalidSeed }
