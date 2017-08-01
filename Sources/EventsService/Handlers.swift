import Foundation
import Kitura
import SwiftyJSON
import LoggerAPI
import MySQL

public class Handlers {
    var connectionPool: MySQLConnectionPool

    public init(connectionPool: MySQLConnectionPool) {
        self.connectionPool = connectionPool
    }

    /**
     * Handler for getting an application/json response.
     */
    public func getEvents(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {

        Log.info("GET - /events route handler...")

        if request.method != RouterMethod.get {
            try response.status(.badRequest).end()
            return
        }

        do {
          let connection = try connectionPool.getConnection()!

          // release the connection back to the pool
          defer {
            connectionPool.releaseConnection(connection)
          }

          let client = MySQLClient(connection: connection)
          let result = client.execute(query: "SELECT * from events")
          try returnResult(result: result, response: response)

        } catch {
          Log.error("Unable to create connection")
          try response.status(.internalServerError).end()
        }
    }

    private func returnResult(result: (MySQLResultProtocol?, error: MySQLError?), response: RouterResponse) throws {
      if let _ = result.1 {
            try response.status(.internalServerError).end()
            return
        }

        let events = toEvents(result: result.0!)

        if events.count > 0 {
            try response.send(json: events.toJSON()).status(.OK).end()
        } else {
            try response.status(.notFound).end()
        }
    }

    private func toEvents(result: MySQLResultProtocol) -> [Event] {

      var events = [Event]()

      while case let row? = result.nextResult() {

        var event = Event()

        if let id = row["id"] as? Int {
          event.id = id
        }

        if let host = row["host"] as? Int {
          event.host = host
        }

        if let isPublic = row["public"] as? Int {
          event.isPublic = isPublic
        }

        if let name = row["name"] as? String {
          event.name = name
        }

        if let location = row["location"] as? String {
          event.location = location
        }

        if let emoji = row["emoji"] as? String {
          event.emoji = emoji
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        if let startTimeString = row["start_time"] as? String, let startTime = dateFormatter.date(from: startTimeString) {
          event.startTime = startTime
        }

        if let createdAtString = row["created_at"] as? String, let createdAt = dateFormatter.date(from: createdAtString) {
          event.createdAt = createdAt
        }

        if let updatedAtString = row["updated_at"] as? String, let updatedAt = dateFormatter.date(from: updatedAtString) {
          event.updatedAt = updatedAt
        }

        events.append(event)
      }

      return events
    }
}
