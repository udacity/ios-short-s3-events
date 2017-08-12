import MySQL
import LoggerAPI
import Foundation

// MARK: - MySQLResultProtocol (EventGame)

public extension MySQLResultProtocol {

    public func toEventGames() -> [EventGame] {

        var eventGames = [EventGame]()

        while case let row? = self.nextResult() {

            var eventGame = EventGame()

            if let id = row["id"] as? Int {
                eventGame.id = id
            }

            if let activityId = row["activity_id"] as? Int {
                eventGame.activityId = activityId
            }

            if let eventId = row["event_id"] as? Int {
                eventGame.eventId = eventId
            }

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

            if let createdAtString = row["created_at"] as? String,
               let createdAt = dateFormatter.date(from: createdAtString) {
                   eventGame.createdAt = createdAt
            }

            if let updatedAtString = row["updated_at"] as? String,
               let updatedAt = dateFormatter.date(from: updatedAtString) {
                   eventGame.updatedAt = updatedAt
            }

            eventGames.append(eventGame)
        }

        return eventGames
    }
}
