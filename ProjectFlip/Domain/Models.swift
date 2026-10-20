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

enum ItemCategory: String, Codable, CaseIterable, Sendable { case gaming, cameras, retro }
enum Defect: String, Codable, CaseIterable, Sendable {
    case drift, overheating, noisyFan, damagedPort, storageFailure, batteryWear, screenBurnIn, wirelessFault
    case sensorDamage, lensFungus, lensScratch, autofocusFault, shutterWear, apertureStuck, stabilizationFault, cameraBatteryWear
    case replacementParts, missingManual, boxWear, regionMismatch, counterfeitBoard, labelDamage, corrosion, incompleteSet

    var category: ItemCategory {
        switch self {
        case .drift, .overheating, .noisyFan, .damagedPort, .storageFailure, .batteryWear, .screenBurnIn, .wirelessFault: .gaming
        case .sensorDamage, .lensFungus, .lensScratch, .autofocusFault, .shutterWear, .apertureStuck, .stabilizationFault, .cameraBatteryWear: .cameras
        case .replacementParts, .missingManual, .boxWear, .regionMismatch, .counterfeitBoard, .labelDamage, .corrosion, .incompleteSet: .retro
        }
    }
    var valuePenaltyBasisPoints: Int64 {
        switch self {
        case .drift, .overheating, .noisyFan, .damagedPort, .storageFailure, .shutterWear: 3_000
        case .batteryWear, .cameraBatteryWear, .missingManual: 1_200
        case .screenBurnIn, .apertureStuck, .stabilizationFault, .incompleteSet: 2_500
        case .wirelessFault: 1_800
        case .sensorDamage: 4_500
        case .lensFungus, .corrosion: 3_500
        case .lensScratch, .replacementParts: 2_000
        case .autofocusFault: 2_800
        case .boxWear: 1_000
        case .regionMismatch, .labelDamage: 1_500
        case .counterfeitBoard: 6_000
        }
    }
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
    var repairedDefects: [Defect]?
    var activeDefects: [Defect] { hiddenDefects.filter { !(repairedDefects ?? []).contains($0) } }
    var knownActiveDefects: [Defect] { revealedDefects.filter { !(repairedDefects ?? []).contains($0) } }
    var facts: ItemFacts?
    var revealedFactKeys: Set<ItemFactKey>?
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
        try result.validate()
        return result
    }
    func validate() throws {
        guard items.count >= 45, Set(items.map(\.id)).count == items.count,
              Set(items.map(\.name)).count == items.count,
              ItemCategory.allCases.allSatisfy({ category in items.contains { $0.category == category } }),
              items.allSatisfy({ item in
                  !item.id.isEmpty && !item.brand.isEmpty && !item.model.isEmpty && !item.artSymbol.isEmpty &&
                  item.baseValue > .zero && item.baseValue <= GameBalanceConfig.current.maximumTransactionAmount &&
                  !item.possibleDefects.isEmpty && Set(item.possibleDefects).count == item.possibleDefects.count &&
                  item.possibleDefects.allSatisfy { $0.category == item.category }
              }) else { throw ContentError.invalidSeed }
    }
}
enum ContentError: Error { case missingSeed, invalidSeed }
