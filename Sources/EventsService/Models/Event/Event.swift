import Foundation
import SwiftyJSON
import LoggerAPI

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
    public var rsvps: [RSVP]?
    public var createdAt: Date?
    public var updatedAt: Date?
}

// MARK: - Event: JSONAble

extension Event: JSONAble {
    public func toJSON() -> JSON {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        var dict = [String: Any]()
        let nilValue: Any? = nil

        dict["id"] = id != nil ? id : nilValue
        dict["public"] = isPublic != nil ? isPublic : nilValue
        dict["host"] = host != nil ? host : nilValue

        dict["name"] = name != nil ? name : nilValue
        dict["emoji"] = emoji != nil ? emoji : nilValue
        dict["description"] = description != nil ? description : nilValue
        dict["location"] = location != nil ? location : nilValue

        dict["start_time"] = startTime != nil ? dateFormatter.string(from: startTime!) : nilValue
        dict["created_at"] = createdAt != nil ? dateFormatter.string(from: createdAt!) : nilValue
        dict["updated_at"] = updatedAt != nil ? dateFormatter.string(from: updatedAt!) : nilValue

        dict["games"] = games != nil ? games : nilValue
        dict["rsvps"] = rsvps != nil ? rsvps!.toJSON().object : nilValue

        return JSON(dict)
    }
}
