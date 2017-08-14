import MySQL
import LoggerAPI
import Foundation

// MARK: - MySQLResultProtocol (Event)

public extension MySQLResultProtocol {

    public func toEvents() -> [Event] {

        var eventsDictionary = [Int:Event]()
        var userIdsAttending = [Int]()

        while case let row? = self.nextResult() {

            if let id = row["master_id"] as? Int {
                if eventsDictionary[id] == nil {
                    eventsDictionary[id] = Event()
                }
                eventsDictionary[id]?.id = id

                if let activityID = row["activity_id"] as? Int {
                    if eventsDictionary[id]?.games == nil {
                        eventsDictionary[id]?.games = [Int]()
                    }
                    if eventsDictionary[id]?.games?.contains(activityID) == false {
                        eventsDictionary[id]?.games?.append(activityID)
                    }
                }

                if let userID = row["user_id"] as? Int {
                    if eventsDictionary[id]?.rsvps == nil {
                        eventsDictionary[id]?.rsvps = [RSVP]()
                        userIdsAttending.append(userID)
                    }
                    if userIdsAttending.contains(userID) == false {
                        var rsvp = RSVP()
                        rsvp.userID = userID
                        rsvp.eventID = row["event_id"] as? Int
                        rsvp.accepted = row["accepted"] as? Int
                        rsvp.comment = row["comment"] as? String
                        eventsDictionary[id]?.rsvps?.append(rsvp)
                    }
                }

                if let host = row["host"] as? Int {
                    eventsDictionary[id]?.host = host
                }

                if let isPublic = row["is_public"] as? Int {
                    eventsDictionary[id]?.isPublic = isPublic
                }

                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

                if let startTimeString = row["start_time"] as? String,
                   let startTime = dateFormatter.date(from: startTimeString) {
                       eventsDictionary[id]?.startTime = startTime
                }

                if let createdAtString = row["created_at"] as? String,
                   let createdAt = dateFormatter.date(from: createdAtString) {
                       eventsDictionary[id]?.createdAt = createdAt
                }

                if let updatedAtString = row["updated_at"] as? String,
                   let updatedAt = dateFormatter.date(from: updatedAtString) {
                       eventsDictionary[id]?.updatedAt = updatedAt
                }

                if let name = row["name"] as? String {
                    eventsDictionary[id]?.name = name
                }

                if let emoji = row["emoji"] as? String {
                    eventsDictionary[id]?.emoji = emoji
                }

                if let description = row["description"] as? String {
                    eventsDictionary[id]?.description = description
                }

                if let location = row["location"] as? String {
                    eventsDictionary[id]?.location = location
                }

            } else {
                Log.error("event_id not found in \(row)")
            }
        }

        return Array(eventsDictionary.values)
    }
}
