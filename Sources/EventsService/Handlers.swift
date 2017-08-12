import MySQL
import Kitura
import LoggerAPI
import Foundation
import SwiftyJSON

// MARK: - Handlers

public class Handlers {

    // MARK: Properties

    let connectionPool: MySQLConnectionPoolProtocol

    // MARK: Initializer

    public init(connectionPool: MySQLConnectionPoolProtocol) {
        self.connectionPool = connectionPool
    }

    // MARK: OPTIONS

    public func getOptions(request: RouterRequest, response: RouterResponse, next: () -> Void) throws {
        response.headers["Access-Control-Allow-Headers"] = "accept, content-type"
        response.headers["Access-Control-Allow-Methods"] = "GET,POST,DELETE,OPTIONS,PUT"
        try response.status(.OK).end()
    }

    // MARK: GET

    public func getEvents(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {

        let id = request.parameters["id"]
        try safeDBQuery(response: response) {
            (eventAccessor: EventMySQLDataAccessor, eventGameAccessor: EventGameMySQLDataAccessor) in

            var events: [Event]?
            var eventGames: [EventGame]?

            if let id = id {
                events = try eventAccessor.getEvents(withID: id)
                eventGames = try eventGameAccessor.getGamesForEvent(withID: id)
            } else {
                events = try eventAccessor.getEvents()
            }

            if events == nil {
                try response.status(.notFound).end()
                return
            }

            events![0].games = [Int]()

            for game in eventGames! {
                events![0].games?.append(game.activityId!)
            }

            try response.send(json: events!.toJSON()).status(.OK).end()
        }
    }

    // MARK: Utility

    // execute queries safely and return error on failure
    private func safeDBQuery(response: RouterResponse, block: @escaping
        ((_: EventMySQLDataAccessor, _: EventGameMySQLDataAccessor) throws -> Void)) throws {
        do {
            try connectionPool.getConnection { (connection: MySQLConnectionProtocol) in
                    let eventAccessor = EventMySQLDataAccessor(connection: connection)
                    let eventGamesAccessor = EventGameMySQLDataAccessor(connection: connection)
                    try block(eventAccessor, eventGamesAccessor)
            }
        } catch {
            Log.error(error.localizedDescription)
            try response.status(.internalServerError).end()
        }
    }
}
