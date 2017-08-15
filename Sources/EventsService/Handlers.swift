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

    // MARK: POST

    public func postEvent(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {

        guard let body = request.body, case let .json(json) = body else {
            Log.error("body contains invalid JSON")
            try response.send(json: JSON(["message": "body is missing JSON or JSON is invalid"]))
                        .status(.badRequest).end()
            return
        }

        let newEvent = Event(
            id: nil,
            name: json["name"].string,
            emoji: json["emoji"].string,
            description: json["description"].string,
            host: json["host"].int,
            startTime: nil,
            location: json["location"].string,
            isPublic: json["public"].int,
            games: nil, rsvps: nil,
            createdAt: nil, updatedAt: nil)

        let missingParameters = newEvent.validateParameters(
            ["name", "emoji", "description", "host", "start_time", "location", "is_public"])

        if missingParameters.count != 0 {
            Log.error("parameters missing \(missingParameters)")
            try response.send(json: JSON(["message": "parameters missing \(missingParameters)"]))
                        .status(.badRequest).end()
            return
        }

        Log.info("perform post")
    }

    // MARK: PUT

    public func putEvent(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
        Log.info("perform put")
    }

    // MARK: DELETE

    public func deleteEvent(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
        Log.info("perform delete")
    }
}
