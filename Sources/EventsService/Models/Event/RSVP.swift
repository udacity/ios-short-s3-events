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
        let nilString: String? = nil
        let nilInt: Int? = nil
        
        dict["user_id"] = userID != nil ? userID : nilInt
        dict["event_id"] = eventID != nil ? eventID : nilInt
        dict["accepted"] = accepted != nil ? accepted : nilInt

        dict["comment"] = comment != nil ? comment : nilString

        return JSON(dict)
    }
}
