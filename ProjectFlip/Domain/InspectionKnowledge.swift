import Foundation

/// Knowledge and tools belong to a category. Buying a kit never reveals hidden truth.
struct InspectionKnowledge: Codable, Equatable, Sendable {
    var experience: [String: Int] = [:]
    var tools: Set<ItemCategory> = []
    var learnedModels: [String: Set<String>]?
    var learnedDefects: [String: Set<Defect>]?
    var selfInspectionCapabilities: [String: Int] = [:]

    func points(in category: ItemCategory) -> Int { experience[category.rawValue, default: 0] }
    func level(in category: ItemCategory) -> Int {
        if points(in: category) >= 16 && modelCount(in: category) >= 6 && diagnosticCount(in: category) >= 3 { return 4 }
        return switch points(in: category) {
        case 0..<3: 0
        case 3..<8: 1
        case 8..<16: 2
        default: 3
        }
    }
    func modelCount(in category: ItemCategory) -> Int { learnedModels?[category.rawValue]?.count ?? 0 }
    func diagnosticCount(in category: ItemCategory) -> Int { learnedDefects?[category.rawValue]?.count ?? 0 }
    mutating func record(_ item: ItemInstance, category: ItemCategory) {
        var models = learnedModels ?? [:]; models[category.rawValue, default: []].insert(item.definitionID); learnedModels = models
        var findings = learnedDefects ?? [:]; findings[category.rawValue, default: []].formUnion(item.revealedDefects); learnedDefects = findings
    }
    func capability(in category: ItemCategory) -> Int { level(in: category) + (tools.contains(category) ? 4 : 0) }
    mutating func learn(_ points: Int, in category: ItemCategory) {
        experience[category.rawValue] = min(1_000_000, self.points(in: category) + points)
    }
    static func toolCost(for category: ItemCategory) -> Money {
        Money(minorUnits: category == .cameras ? 2_500 : category == .retro ? 2_000 : 1_750)
    }
    func canInspect(_ item: ItemInstance, category: ItemCategory) -> Bool {
        !item.professionallyInspected && (!item.inspected || capability(in: category) > selfInspectionCapabilities[item.id.rawValue, default: 0])
    }
    func validate() throws {
        guard (learnedModels ?? [:]).allSatisfy({ ItemCategory(rawValue: $0.key) != nil && $0.value.count <= 10_000 }),
              (learnedDefects ?? [:]).allSatisfy({ pair in guard let category = ItemCategory(rawValue: pair.key) else { return false }; return pair.value.allSatisfy { $0.category == category } }),
              experience.allSatisfy({ ItemCategory(rawValue: $0.key) != nil && (0...1_000_000).contains($0.value) }),
              selfInspectionCapabilities.allSatisfy({ !$0.key.isEmpty && (0...8).contains($0.value) }) else { throw SaveError.invalidSave }
    }
}

extension Defect {
    /// A novice can spot obvious wear on a worn item. Subtle faults need practice or a diagnostic kit.
    func detectable(condition: Int, level: Int, hasTools: Bool) -> Bool {
        switch self {
        case .noisyFan, .damagedPort, .lensScratch, .boxWear, .labelDamage, .missingManual, .incompleteSet:
            condition < 80 || level >= 1
        case .drift, .overheating, .batteryWear, .cameraBatteryWear, .replacementParts:
            level >= 1 && hasTools
        case .wirelessFault, .screenBurnIn, .autofocusFault, .shutterWear, .regionMismatch, .corrosion:
            level >= 2 && hasTools
        case .storageFailure, .sensorDamage, .lensFungus, .apertureStuck, .stabilizationFault, .counterfeitBoard:
            level >= 3 && hasTools
        }
    }
}
