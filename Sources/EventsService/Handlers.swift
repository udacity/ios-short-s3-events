import MySQL
import Kitura
import LoggerAPI
import Foundation
import SwiftyJSON

// MARK: - Handlers

public class Handlers {

    // MARK: Properties

    let dataAccessor: EventMySQLDataAccessorProtocol

    // MARK: Initializer

    public init(dataAccessor: EventMySQLDataAccessorProtocol) {
        self.dataAccessor = dataAccessor
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

        var events: [Event]?

        if let id = id {
            events = try dataAccessor.getEvents(withID: id)
        } else {
            events = try dataAccessor.getEvents()
        }

        if events == nil {
            try response.status(.notFound).end()
            return
        }

        try response.send(json: events!.toJSON()).status(.OK).end()
    }
}
