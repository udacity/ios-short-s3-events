import MySQL
import LoggerAPI
import Foundation

// MARK: - MySQLResultProtocol (Event)

public extension MySQLResultProtocol {

    public func toEvents(pageSize: Int = 10) -> [Event] {

        // Track unique event records with a dictionary
        // This eliminates duplicates in the results of JOIN-based queries
        var eventsDictionary = [Int:Event]()
        var usersInvited = [String]()

        while case let row? = self.nextResult() {

            if let id = row["id"] as? Int {

                // If the id DNE in dictionary, create a new event
                if eventsDictionary[id] == nil {
                    eventsDictionary[id] = Event()
                }

                // Add activities to event
                if let activityID = row["activity_id"] as? Int {
                    // If activities is nil, the create new activities array
                    if eventsDictionary[id]?.activities == nil {
                        eventsDictionary[id]?.activities = [Int]()
                    }
                    // Only append unique activities
                    if eventsDictionary[id]?.activities?.contains(activityID) == false {
                        eventsDictionary[id]?.activities?.append(activityID)
                    }
                }

                // Add rsvps to event
                if let userID = row["user_id"] as? String {
                    // If rsvps is nil, then create new RSVP array
                    if eventsDictionary[id]?.rsvps == nil {
                        eventsDictionary[id]?.rsvps = [RSVP]()
                    }
                    // Only append unique rsvps
                    if usersInvited.contains(userID) == false {
                        var rsvp = RSVP()
                        rsvp.userID = userID
                        rsvp.eventID = row["event_id"] as? Int
                        rsvp.accepted = row["accepted"] as? Int
                        rsvp.comment = row["comment"] as? String
                        eventsDictionary[id]?.rsvps?.append(rsvp)
                        usersInvited.append(userID)
                    }
                }

                // Add remaining properties
                eventsDictionary[id]?.id = id
                eventsDictionary[id]?.host = row["host"] as? String
                eventsDictionary[id]?.isPublic = row["is_public"] as? Int
                eventsDictionary[id]?.name = row["name"] as? String
                eventsDictionary[id]?.emoji = row["emoji"] as? String
                eventsDictionary[id]?.description = row["description"] as? String
                eventsDictionary[id]?.location = row["location"] as? String
                eventsDictionary[id]?.latitude = row["latitude"] as? Double
                eventsDictionary[id]?.longitude = row["longitude"] as? Double

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
            }

            // Return collection limited by page size if specified
            if pageSize > 0 && eventsDictionary.count == Int(pageSize) {
                break
            }
        }

        return Array(eventsDictionary.values)
    }
}
