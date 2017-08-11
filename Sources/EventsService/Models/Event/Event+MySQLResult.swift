import MySQL
import LoggerAPI
import Foundation

// MARK: - MySQLResultProtocol (Event)

public extension MySQLResultProtocol {

    public func toEvents() -> [Event] {

        var events = [Event]()

        while case let row? = self.nextResult() {

            var event = Event()

            if let id = row["id"] as? Int {
                event.id = id
            }

            if let host = row["host"] as? Int {
                event.host = host
            }

            if let isPublic = row["is_public"] as? Int {
                event.isPublic = isPublic
            }

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

            if let startTimeString = row["start_time"] as? String,
               let startTime = dateFormatter.date(from: startTimeString) {
                   event.startTime = startTime
            }

            if let createdAtString = row["created_at"] as? String,
               let createdAt = dateFormatter.date(from: createdAtString) {
                   event.createdAt = createdAt
            }

            if let updatedAtString = row["updated_at"] as? String,
               let updatedAt = dateFormatter.date(from: updatedAtString) {
                   event.updatedAt = updatedAt
            }

            if let name = row["name"] as? String {
                event.name = name
            }

            if let emoji = row["emoji"] as? String {
                event.emoji = emoji
            }

            if let description = row["description"] as? String {
                event.description = description
            }

            if let location = row["location"] as? String {
                event.location = location
            }

            events.append(event)
        }

        return events
    }
}
