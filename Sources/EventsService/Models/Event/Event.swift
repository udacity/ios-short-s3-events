import Foundation
import SwiftyJSON
import LoggerAPI

// MARK: - EventScheduleType

public enum EventScheduleType: String {
    case all, past, upcoming
}

// MARK: - Event

public struct Event {
    public var id: Int?
    public var name: String?
    public var emoji: String?
    public var description: String?
    public var host: String?
    public var startTime: Date?
    public var location: String?
    public var latitude: Double?
    public var longitude: Double?
    public var isPublic: Int?
    public var activities: [Int]?
    public var rsvps: [RSVP]?
    public var createdAt: Date?
    public var updatedAt: Date?
}

// MARK: - Event: JSONAble

extension Event: JSONAble {
    public func toJSON() -> JSON {
        var dict = [String: Any]()
        let nilValue: Any? = nil

        dict["id"] = id != nil ? id : nilValue
        dict["is_public"] = isPublic != nil ? isPublic : nilValue
        dict["host"] = host != nil ? host : nilValue
        dict["name"] = name != nil ? name : nilValue
        dict["emoji"] = emoji != nil ? emoji : nilValue
        dict["description"] = description != nil ? description : nilValue
        dict["location"] = location != nil ? location : nilValue
        dict["latitude"] = latitude != nil ? latitude : nilValue
        dict["longitude"] = longitude != nil ? longitude : nilValue
        dict["activities"] = activities != nil ? activities : nilValue
        dict["rsvps"] = rsvps != nil ? rsvps!.toJSON().object : nilValue

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        dict["start_time"] = startTime != nil ? dateFormatter.string(from: startTime!) : nilValue
        dict["created_at"] = createdAt != nil ? dateFormatter.string(from: createdAt!) : nilValue
        dict["updated_at"] = updatedAt != nil ? dateFormatter.string(from: updatedAt!) : nilValue

        return JSON(dict)
    }
}

// MARK: - Event (MySQLRow)

extension Event {
    func toMySQLRow() -> ([String: Any]) {
        var data = [String: Any]()

        data["name"] = name
        data["emoji"] = emoji
        data["description"] = description
        data["host"] = host
        data["start_time"] = startTime
        data["location"] = location
        data["latitude"] = latitude
        data["longitude"] = longitude
        data["is_public"] = isPublic

        return data
    }
}

// MARK: - Event (Validate)

extension Event {
    public func validateParameters(_ parameters: [String]) -> [String] {
        var missingParameters = [String]()
        let mirror = Mirror(reflecting: self)

        for (name, value) in mirror.children {
            guard let name = name, parameters.contains(name) else { continue }
            if "\(value)" == "nil" {
                missingParameters.append("\(name)")
            }
        }

        return missingParameters
    }
}
