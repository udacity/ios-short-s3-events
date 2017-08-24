import Foundation
import SwiftyJSON

// MARK: - RSVP

public struct RSVP {
    public var userID: Int?
    public var eventID: Int?
    public var accepted: Int?
    public var comment: String?
}

// MARK: - RSVP: JSONAble

extension RSVP: JSONAble {
    public func toJSON() -> JSON {
        var dict = [String: Any]()
        let nilValue: Any? = nil

        dict["user_id"] = userID != nil ? userID : nilValue
        dict["event_id"] = eventID != nil ? eventID : nilValue
        dict["accepted"] = accepted != nil ? accepted : nilValue
        dict["comment"] = comment != nil ? comment : nilValue

        return JSON(dict)
    }
}
