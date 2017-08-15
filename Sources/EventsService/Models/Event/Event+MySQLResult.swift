import MySQL
import LoggerAPI
import Foundation

// MARK: - MySQLResultProtocol (Event)

public extension MySQLResultProtocol {

    public func toEvents() -> [Event] {

        var eventsDictionary = [Int:Event]()
        var usersAttending = [Int]()

        while case let row? = self.nextResult() {

            if let id = row["master_id"] as? Int {
                if eventsDictionary[id] == nil {
                    eventsDictionary[id] = Event()
                }
                eventsDictionary[id]?.id = id

                if let activityID = row["activity_id"] as? Int {
                    if eventsDictionary[id]?.activities == nil {
                        eventsDictionary[id]?.activities = [Int]()
                    }
                    if eventsDictionary[id]?.activities?.contains(activityID) == false {
                        eventsDictionary[id]?.activities?.append(activityID)
                    }
                }

                if let userID = row["user_id"] as? Int {
                    if eventsDictionary[id]?.attendees == nil {
                        eventsDictionary[id]?.attendees = [RSVP]()
                        usersAttending.append(userID)
                    }
                    if usersAttending.contains(userID) == false {
                        var rsvp = RSVP()
                        rsvp.userID = userID
                        rsvp.eventID = row["event_id"] as? Int
                        rsvp.accepted = row["accepted"] as? Int
                        rsvp.comment = row["comment"] as? String
                        eventsDictionary[id]?.attendees?.append(rsvp)
                    }
                }

                eventsDictionary[id]?.host = row["host"] as? Int
                eventsDictionary[id]?.isPublic = row["is_public"] as? Int

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

                eventsDictionary[id]?.name = row["name"] as? String
                eventsDictionary[id]?.emoji = row["emoji"] as? String
                eventsDictionary[id]?.description = row["description"] as? String
                eventsDictionary[id]?.location = row["location"] as? String

            } else {
                Log.error("event_id not found in \(row)")
            }
        }

        return Array(eventsDictionary.values)
    }
}
