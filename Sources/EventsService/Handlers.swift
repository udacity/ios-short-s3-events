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
        try safeDBQuery(response: response) { (accessor: EventMySQLDataAccessor) in

            var events: [Event]?

            if let id = id {
                events = try accessor.getEvents(withID: id)
            } else {
                events = try accessor.getEvents()
            }

            if events == nil {
                try response.status(.notFound).end()
                return
            }

            try response.send(json: events!.toJSON()).status(.OK).end()
        }
    }

    // MARK: Utility

    // execute queries safely and return error on failure
    private func safeDBQuery(response: RouterResponse,
                             block: @escaping ((_: EventMySQLDataAccessor) throws -> Void)) throws {
        do {
            try connectionPool.getConnection { (connection: MySQLConnectionProtocol) in
                    let dataAccessor = EventMySQLDataAccessor(connection: connection)
                    try block(dataAccessor)
            }
        } catch {
            Log.error(error.localizedDescription)
            try response.status(.internalServerError).end()
        }
    }
}
