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

        let activities = json["activities"].arrayValue.map({$0.intValue})
        let rsvps = json["rsvps"].arrayValue.map({
            RSVP(userID: $0.stringValue, eventID: nil, accepted: nil, comment: nil)
        })

        let newEvent = Event(
            id: nil,
            name: json["name"].string,
            emoji: json["emoji"].string,
            description: json["description"].string,
            host: json["host"].string,
            startTime: nil,
            location: json["location"].string,
            isPublic: json["is_public"].int,
            activities: activities, rsvps: rsvps,
            createdAt: nil, updatedAt: nil)

        let missingParameters = newEvent.validateParameters(
            ["name", "emoji", "description", "host", "start_time", "location", "is_public", "activities", "rsvps"])

        if missingParameters.count != 0 {
            Log.error("parameters missing \(missingParameters)")
            try response.send(json: JSON(["message": "parameters missing \(missingParameters)"]))
                        .status(.badRequest).end()
            return
        }

        let success = try dataAccessor.createEvent(newEvent)

        if success {
            try response.send(json: JSON(["message": "event created"])).status(.created).end()
            return
        }

        try response.status(.notModified).end()
    }

    public func postEventRSVPs(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {

        guard let body = request.body, case let .json(json) = body else {
            Log.error("body contains invalid JSON")
            try response.send(json: JSON(["message": "body is missing JSON or JSON is invalid"]))
                        .status(.badRequest).end()
            return
        }

        guard let id = request.parameters["id"] else {
            Log.error("id (path parameter) missing")
            try response.send(json: JSON(["message": "id (path parameter) missing"]))
                        .status(.badRequest).end()
            return
        }

        let rsvps = json["rsvps"].arrayValue.map({
            RSVP(userID: $0.stringValue, eventID: nil, accepted: nil, comment: nil)
        })

        let postEvent = Event(
            id: Int(id),
            name: nil,
            emoji: nil,
            description: nil,
            host: nil,
            startTime: nil,
            location: nil,
            isPublic: nil,
            activities: nil, rsvps: rsvps,
            createdAt: nil, updatedAt: nil)

        let missingParameters = postEvent.validateParameters(["id", "rsvps"])

        if missingParameters.count != 0 {
            Log.error("parameters missing \(missingParameters)")
            try response.send(json: JSON(["message": "parameters missing \(missingParameters)"]))
                        .status(.badRequest).end()
            return
        }

        let success = try dataAccessor.postEventRSVPs(withEvent: postEvent)

        if success {
            try response.send(json: JSON(["message": "rsvps sent"])).status(.OK).end()
        }

        try response.status(.notModified).end()
    }

    // MARK: PUT

    public func putEvent(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {

        guard let body = request.body, case let .json(json) = body else {
            Log.error("body contains invalid JSON")
            try response.send(json: JSON(["message": "body is missing JSON or JSON is invalid"]))
                        .status(.badRequest).end()
            return
        }

        guard let id = request.parameters["id"] else {
            Log.error("id (path parameter) missing")
            try response.send(json: JSON(["message": "id (path parameter) missing"]))
                        .status(.badRequest).end()
            return
        }

        let updateEvent = Event(
            id: Int(id),
            name: json["name"].string,
            emoji: json["emoji"].string,
            description: json["description"].string,
            host: json["host"].string,
            startTime: nil,
            location: json["location"].string,
            isPublic: json["is_public"].int,
            activities: nil, rsvps: nil,
            createdAt: nil, updatedAt: nil)

        let missingParameters = updateEvent.validateParameters(
            ["name", "emoji", "description", "host", "start_time", "location", "is_public"])

        if missingParameters.count != 0 {
            Log.error("parameters missing \(missingParameters)")
            try response.send(json: JSON(["message": "parameters missing \(missingParameters)"]))
                        .status(.badRequest).end()
            return
        }

        Log.info("perform put")
    }

    // MARK: PATCH

    public func patchEventRSVPs(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
    }

    // MARK: DELETE

    public func deleteEvent(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {

        guard let id = request.parameters["id"] else {
            Log.error("id (path parameter) missing")
            try response.send(json: JSON(["message": "id (path parameter) missing"]))
                        .status(.badRequest).end()
            return
        }

        let success = try dataAccessor.deleteEvent(withID: id)

        if success {
            try response.send(json: JSON(["message": "resource deleted"])).status(.noContent).end()
        }

        try response.status(.notModified).end()
    }
}
