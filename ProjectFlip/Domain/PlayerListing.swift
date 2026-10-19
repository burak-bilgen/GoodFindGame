import Foundation

enum PlayerListingStatus: String, Codable { case active, sold, cancelled }
struct PlayerListing: Codable, Identifiable, Equatable {
    let id: ListingID
    let itemID: ItemID
    var askingPrice: Money
    let createdAt: Date
    var status: PlayerListingStatus = .active
    var views: Int
    var favorites: Int
}
