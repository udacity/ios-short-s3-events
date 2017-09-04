import Foundation
import SwiftyJSON

// MARK: - RSVP

public struct RSVP {
    public var rsvpID: Int?
    public var userID: String?
    public var eventID: Int?
    public var accepted: Int?
    public var comment: String?
}

// MARK: - RSVP: JSONAble

extension RSVP: JSONAble {
    public func toJSON() -> JSON {
        var dict = [String: Any]()
        let nilValue: Any? = nil

        dict["rsvp_id"] = rsvpID != nil ? rsvpID : nilValue
        dict["user_id"] = userID != nil ? userID : nilValue
        dict["accepted"] = accepted != nil ? accepted : nilValue
        dict["comment"] = comment != nil ? comment : nilValue

        return JSON(dict)
    }
}

// MARK: - RSVP (MySQLRow)

extension RSVP {
    func toMySQLRow() -> ([String: Any]) {
        var data = [String: Any]()
        
        data["user_id"] = userID
        data["event_id"] = eventID
        data["accepted"] = accepted
        data["comment"] = comment

        return data
    }
}

// MARK: - RSVP (Validate)

extension RSVP {
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
