import Foundation

enum PlayerListingStatus: String, Codable { case active, sold, cancelled, expired }
struct PlayerListing: Codable, Identifiable, Equatable {
    let id: ListingID
    let itemID: ItemID
    var askingPrice: Money
    let createdAt: Date
    var status: PlayerListingStatus = .active
    var views: Int
    var favorites: Int
    var offers: [BuyerOffer] = []
    var messages: [DialogueMessage] = []
    var itemSnapshot: ItemInstance?
    var soldPrice: Money?
    var soldAt: Date?
    var expiresAt: Date?
    enum CodingKeys: String, CodingKey { case id, itemID, askingPrice, createdAt, status, views, favorites, offers, messages, itemSnapshot, soldPrice, soldAt, expiresAt }
}

extension PlayerListing {
    init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(ListingID.self, forKey: .id)
        itemID = try values.decode(ItemID.self, forKey: .itemID)
        askingPrice = try values.decode(Money.self, forKey: .askingPrice)
        createdAt = try values.decode(Date.self, forKey: .createdAt)
        status = try values.decode(PlayerListingStatus.self, forKey: .status)
        views = try values.decode(Int.self, forKey: .views)
        favorites = try values.decode(Int.self, forKey: .favorites)
        offers = try values.decodeIfPresent([BuyerOffer].self, forKey: .offers) ?? []
        messages = try values.decodeIfPresent([DialogueMessage].self, forKey: .messages) ?? []
        itemSnapshot = try values.decodeIfPresent(ItemInstance.self, forKey: .itemSnapshot)
        soldPrice = try values.decodeIfPresent(Money.self, forKey: .soldPrice)
        soldAt = try values.decodeIfPresent(Date.self, forKey: .soldAt)
        expiresAt = try values.decodeIfPresent(Date.self, forKey: .expiresAt)
    }
}
