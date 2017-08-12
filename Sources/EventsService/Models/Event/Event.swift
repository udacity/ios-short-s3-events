import Foundation
import SwiftyJSON

// MARK: - Event

public struct Event {
    public var id: Int?
    public var name: String?
    public var emoji: String?
    public var description: String?
    public var host: Int?
    public var startTime: Date?
    public var location: String?
    public var isPublic: Int?
    public var games: [Int]?
    public var createdAt: Date?
    public var updatedAt: Date?
}

// MARK: - Event: JSONAble

extension Event: JSONAble {
    public func toJSON() -> JSON {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        var dict = [String: Any]()
        let nilString: String? = nil
        let nilInt: Int? = nil
        let nilDate: Date? = nil
        let nilGames: [Int]? = nil

        dict["id"] = id != nil ? id : nilInt
        dict["public"] = isPublic != nil ? isPublic : nilInt
        dict["host"] = host != nil ? host : nilInt

        dict["name"] = name != nil ? name : nilString
        dict["emoji"] = emoji != nil ? emoji : nilString
        dict["description"] = description != nil ? description : nilString
        dict["location"] = location != nil ? location : nilString

        dict["start_time"] = startTime != nil ? dateFormatter.string(from: startTime!) : nilDate
        dict["created_at"] = createdAt != nil ? dateFormatter.string(from: createdAt!) : nilDate
        dict["updated_at"] = updatedAt != nil ? dateFormatter.string(from: updatedAt!) : nilDate

        dict["games"] = games != nil ? games : nilGames

        return JSON(dict)
    }
}
