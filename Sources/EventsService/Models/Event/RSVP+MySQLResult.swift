import MySQL
import LoggerAPI
import Foundation

// MARK: - MySQLResultProtocol (RSVP)

public extension MySQLResultProtocol {

    public func toRSVPs(pageSize: Int = 10) -> [RSVP] {

        var rsvps = [RSVP]()

        while case let row? = self.nextResult() {

            var rsvp = RSVP()

            rsvp.userID = row["user_id"] as? String
            rsvp.comment = row["comment"] as? String
            rsvp.accepted = row["accepted"] as? Int

            rsvps.append(rsvp)

            // return collection limited by page size if specified
            if pageSize > 0 && rsvps.count == Int(pageSize) {
                break
            }
        }

        return rsvps
    }
}
