import Foundation

/// Pure transformations. The repository writes migration backups only after validation.
enum SaveMigrations {
    struct Prepared {
        let data: Data
        let backupSuffixes: [String]
        var needsRewrite: Bool { !backupSuffixes.isEmpty }
    }

    static func retiredShopRefund(from decoder: any Decoder) throws -> Money {
        let values = try decoder.container(keyedBy: RetiredFeatureKeys.self)
        return try values.decodeIfPresent(RetiredShopInvestment.self, forKey: .shop)?.refund() ?? .zero
    }

    static func prepare(_ data: Data) throws -> Prepared {
        guard var object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw SaveError.invalidSave }
        var backups: [String] = []
        if object["marketConfiguration"] == nil {
            backups.append("pre-economy-v2.json")
            func rebase(_ value: Any) -> Any {
                if let dict = value as? [String: Any] {
                    if dict.count == 1, let units = dict["minorUnits"] as? NSNumber { return ["minorUnits": units.int64Value / 20] }
                    return dict.mapValues(rebase)
                }
                if let array = value as? [Any] { return array.map(rebase) }
                return value
            }
            object = rebase(object) as? [String: Any] ?? [:]
            object["marketConfiguration"] = ["version": 1, "region": "unitedStates", "currency": "USD"]
            object["economyMigrationNotice"] = true
        }
        if var configuration = object["marketConfiguration"] as? [String: Any], configuration["version"] as? Int == 1 {
            backups.append("pre-shared-market-v3.json")
            object["sharedMarketMigrationNotice"] = configuration["region"] as? String == "turkey"
            configuration["version"] = 2
            configuration["region"] = "unitedStates"
            object["marketConfiguration"] = configuration
        }
        if object["shop"] != nil { backups.append("pre-shop-removal.json") }
        if object["collections"] != nil || (object["player"] as? [String: Any])?["reputation"] != nil {
            backups.append("pre-feature-cleanup.json")
        }
        if (object["career"] as? [String: Any])?["accessVersion"] as? Int != 2 {
            backups.append("pre-career-access-v2.json")
        }
        return Prepared(data: try JSONSerialization.data(withJSONObject: object), backupSuffixes: backups)
    }
}

// Read-only compatibility for storefront investments made before their removal.
private enum RetiredFeatureKeys: String, CodingKey { case shop }
private struct RetiredShopInvestment: Decodable {
    let name: String?
    let windowLevel: Int
    let invested: Money

    func refund() throws -> Money {
        guard (0...4).contains(windowLevel), invested >= .zero else { throw SaveError.invalidSave }
        if let name {
            guard (1...24).contains(name.count),
                  !name.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }),
                  invested.minorUnits == 15_000 + Int64(windowLevel * (windowLevel + 1) / 2) * 20_000 else { throw SaveError.invalidSave }
        } else {
            guard windowLevel == 0, invested == .zero else { throw SaveError.invalidSave }
        }
        return invested
    }
}
