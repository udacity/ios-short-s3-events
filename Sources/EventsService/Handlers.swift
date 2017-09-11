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

    public func getSingleEvent(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {

        guard let id = request.parameters["id"] else {
            Log.error("Cannot initialize path parameter: id.")
            try response.send(json: JSON(["message": "Cannot initialize path parameter: id."]))
                        .status(.badRequest).end()
            return
        }

        let events = try dataAccessor.getEvents(withIDs: [id], pageSize: 1, pageNumber: 1)

        if events == nil {
            try response.status(.notFound).end()
            return
        }

        try response.send(json: events!.toJSON()).status(.OK).end()
    }

    public func getEvents(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {

        guard let pageSize = Int(request.queryParameters["page_size"] ?? "10"), let pageNumber = Int(request.queryParameters["page_number"] ?? "1"),
            pageSize > 0, pageSize <= 50 else {
            Log.error("Cannot initialize query parameters: page_size, page_number. page_size must be (0, 50].")
            try response.send(json: JSON(["message": "Cannot initialize query parameters: page_size, page_number. page_size must be (0, 50]."]))
                        .status(.badRequest).end()
            return
        }

        guard let body = request.body, case let .json(json) = body else {
            Log.error("Cannot initialize request body. This endpoint expects the request body to be a valid JSON object.")
            try response.send(json: JSON(["message": "Cannot initialize request body. This endpoint expects the request body to be a valid JSON object."]))
                        .status(.badRequest).end()
            return
        }

        guard let idFilter = json["id"].array else {
            Log.error("Cannot initialize body parameters: id. id is a JSON array of strings (event ids) to filter.")
            try response.send(json: JSON(["message": "Cannot initialize body parameters: id. id is a JSON array of strings (event ids) to filter."]))
                        .status(.badRequest).end()
            return
        }

        let ids = idFilter.map({$0.stringValue})
        let events = try dataAccessor.getEvents(withIDs: ids, pageSize: pageSize, pageNumber: pageNumber)

        if events == nil {
            try response.status(.notFound).end()
            return
        }

        try response.send(json: events!.toJSON()).status(.OK).end()
    }

    public func getScheduledEvents(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {

        guard let pageSize = Int(request.queryParameters["page_size"] ?? "10"), let pageNumber = Int(request.queryParameters["page_number"] ?? "1"),
            pageSize > 0, pageSize <= 50 else {
            Log.error("Cannot initialize query parameters: page_size, page_number. page_size must be (0, 50].")
            try response.send(json: JSON(["message": "Cannot initialize query parameters: page_size, page_number. page_size must be (0, 50]."]))
                        .status(.badRequest).end()
            return
        }

        guard let filterType = request.queryParameters["type"], let type = EventScheduleType(rawValue: filterType) else {
            Log.error("Cannot initialize query parameter: type. type must be upcoming, past, or all.")
            try response.send(json: JSON(["message": "Cannot initialize query parameter: type. type must be upcoming, past, or all."]))
                        .status(.badRequest).end()
            return
        }

        let events = try dataAccessor.getEvents(pageSize: pageSize, pageNumber: pageNumber, type: type)

        if events == nil {
            try response.status(.notFound).end()
            return
        }

        try response.send(json: events!.toJSON()).status(.OK).end()
    }

    public func getEventsBySearch(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {

        guard let pageSize = Int(request.queryParameters["page_size"] ?? "10"), let pageNumber = Int(request.queryParameters["page_number"] ?? "1"),
            pageSize > 0, pageSize <= 50 else {
            Log.error("Cannot initialize query parameters: page_size, page_number. page_size must be (0, 50].")
            try response.send(json: JSON(["message": "Cannot initialize query parameters: page_size, page_number. page_size must be (0, 50]."]))
                        .status(.badRequest).end()
            return
        }

        guard let distanceInMilesString = request.queryParameters["distance"], let distanceInMiles = Int(distanceInMilesString), distanceInMiles > 0 else {
            Log.error("Cannot initialize query parameters: distance. distance must be an unsigned integer.")
            try response.send(json: JSON(["message": "Cannot initialize query parameters: distance. distance must be an unsigned integer."]))
                        .status(.badRequest).end()
            return
        }

        guard let latitudeString = request.queryParameters["latitude"], let longitudeString = request.queryParameters["longitude"],
            let latitude = Double(latitudeString), let longitude = Double(longitudeString), latitude >= -90, latitude <= 90, longitude >= -180, longitude <= 180 else {
                Log.error("Cannot initialize query parameters: latitude, longitude. latitude must be [-90, 90]. longitude must be [-180, 180].")
                try response.send(json: JSON(["message": "Cannot initialize query parameters: latitude, longitude. latitude must be [-90, 90]. longitude must be [-180, 180]."]))
                            .status(.badRequest).end()
                return
        }

        var events: [Event]?

        // Use stored MySQL procedure to get ids for events near location, apply pagination
        if let ids = try dataAccessor.getEventIDsNearLocation(latitude: latitude, longitude: longitude,
            miles: distanceInMiles, pageSize: pageSize, pageNumber: pageNumber) {
            // Get data about events
            events = try dataAccessor.getEvents(withIDs: ids, pageSize: pageSize, pageNumber: 1)
        }

        if events == nil {
            try response.status(.notFound).end()
            return
        }

        try response.send(json: events!.toJSON()).status(.OK).end()
    }

    public func getRSVPsForEvent(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {

        guard let id = request.parameters["id"] else {
            Log.error("Cannot initialize path parameter: id.")
            try response.send(json: JSON(["message": "Cannot initialize path parameter: id."]))
                        .status(.badRequest).end()
            return
        }

        guard let pageSize = Int(request.queryParameters["page_size"] ?? "10"), let pageNumber = Int(request.queryParameters["page_number"] ?? "1"),
            pageSize > 0, pageSize <= 50 else {
            Log.error("Cannot initialize query parameters: page_size, page_number. page_size must be (0, 50].")
            try response.send(json: JSON(["message": "Cannot initialize query parameters: page_size, page_number. page_size must be (0, 50]."]))
                        .status(.badRequest).end()
            return
        }

        let rsvps = try dataAccessor.getRSVPs(forEventID: id, pageSize: pageSize, pageNumber: pageNumber)

        if rsvps == nil {
            try response.status(.notFound).end()
            return
        }

        try response.send(json: rsvps!.toJSON()).status(.OK).end()
    }

    public func getRSVPsForUser(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {

        guard let pageSize = Int(request.queryParameters["page_size"] ?? "10"), let pageNumber = Int(request.queryParameters["page_number"] ?? "1"),
            pageSize > 0, pageSize <= 50 else {
            Log.error("Cannot initialize query parameters: page_size, page_number. page_size must be (0, 50].")
            try response.send(json: JSON(["message": "Cannot initialize query parameters: page_size, page_number. page_size must be (0, 50]."]))
                        .status(.badRequest).end()
            return
        }

        // FIXME: Get RSVPs for user specified in JWT
        let rsvps = try dataAccessor.getRSVPsForUser(pageSize: pageSize, pageNumber: pageNumber)

        if rsvps == nil {
            try response.status(.notFound).end()
            return
        }

        try response.send(json: rsvps!.toJSON()).status(.OK).end()
    }

    // MARK: POST

    public func postEvent(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {

        guard let body = request.body, case let .json(json) = body else {
            Log.error("Cannot initialize request body. This endpoint expects the request body to be a valid JSON object.")
            try response.send(json: JSON(["message": "Cannot initialize request body. This endpoint expects the request body to be a valid JSON object."]))
                        .status(.badRequest).end()
            return
        }

        // An event must have a single activity
        guard let activitiesJSON = json["activities"].array else {
            Log.error("Cannot initialize body parameters: activities. activities is a JSON array of ints (activity ids). New event must have at least one activity.")
            try response.send(json: JSON(["message": "Cannot initialize body parameters: activities. activities is a JSON array of ints (activity ids)."]))
                        .status(.badRequest).end()
            return
        }

        var activities: [Int] = []
        for activityJSON in activitiesJSON {
            if let activity = activityJSON.int {
                activities.append(activity)
            }
        }
        guard activities.count > 0 else {
            Log.error("Cannot initialize body parameters: activities. activities is a JSON array of ints (activity ids). New event must have at least one activity.")
            try response.send(json: JSON(["message": "Cannot initialize body parameters: activities. activities is a JSON array of ints (activity ids). New event must have at least one activity."]))
                        .status(.badRequest).end()
            return
        }

        // RSVPs are optional for a newly created event
        let rsvps = json["rsvps"].arrayValue.map({
            RSVP(rsvpID: nil, userID: $0.stringValue, eventID: nil, accepted: nil, comment: nil)
        })

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let startTimeString = json["start_time"].stringValue
        let startTime: Date? = startTimeString != "" ? dateFormatter.date(from: startTimeString) : nil

        // Create temp event to insert into database
        let newEvent = Event(
            id: nil,
            name: json["name"].string,
            emoji: json["emoji"].string,
            description: json["description"].string,
            host: json["host"].string,
            startTime: startTime,
            location: json["location"].string,
            latitude: json["latitude"].double, longitude: json["longitude"].double,
            isPublic: json["is_public"].int,
            activities: activities, rsvps: rsvps,
            createdAt: nil, updatedAt: nil)

        let missingParameters = newEvent.validateParameters(
            ["name", "emoji", "description", "host", "startTime", "location",
                "latitude", "longitude", "isPublic", "activities", "rsvps"])

        if missingParameters.count != 0 {
            Log.error("Unable to initialize parameters from request body: \(missingParameters).")
            try response.send(json: JSON(["message": "Unable to initialize parameters from request body: \(missingParameters)."]))
                        .status(.badRequest).end()
            return
        }

        let success = try dataAccessor.createEvent(newEvent)

        if success {
            try response.send(json: JSON(["message": "Event created."])).status(.created).end()
            return
        }

        try response.status(.notModified).end()
    }

    public func postRSVPsForEvent(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {

        guard let body = request.body, case let .json(json) = body else {
            Log.error("Cannot initialize request body. This endpoint expects the request body to be a valid JSON object.")
            try response.send(json: JSON(["message": "Cannot initialize request body. This endpoint expects the request body to be a valid JSON object."]))
                        .status(.badRequest).end()
            return
        }

        guard let id = request.parameters["id"] else {
            Log.error("Cannot initialize path parameter: id.")
            try response.send(json: JSON(["message": "Cannot initialize path parameter: id."]))
                        .status(.badRequest).end()
            return
        }

        guard let rsvpJSONArray = json["rsvps"].array else {
            Log.error("Cannot initialize body parameters: rsvps. rsvps is a JSON array of JSON objects.")
            try response.send(json: JSON(["message": "Cannot initialize body parameters: rsvps. rsvps is a JSON array of JSON objects."]))
                        .status(.badRequest).end()
            return
        }

        var rsvps: [RSVP] = []
        for rsvpJSON in rsvpJSONArray {
            let rsvp = RSVP(
                rsvpID: nil,
                userID: rsvpJSON["user_id"].string,
                eventID: Int(id),
                accepted: rsvpJSON["accepted"].int,
                comment: rsvpJSON["comment"].string
            )

            let missingParameters = rsvp.validateParameters(["userID", "eventID", "accepted", "comment"])

            if missingParameters.count != 0 {
                Log.error("Unable to initialize parameters from request body (rsvps): \(missingParameters).")
                try response.send(json: JSON(["message": "Unable to initialize parameters from request body (rsvps): \(missingParameters)."]))
                            .status(.badRequest).end()
                return
            } else {
                rsvps.append(rsvp)
            }
        }

        var postEvent = Event()
        postEvent.id = Int(id)
        postEvent.rsvps = rsvps

        let missingParameters = postEvent.validateParameters(["id", "rsvps"])

        if missingParameters.count != 0 {
            Log.error("Unable to initialize parameters from request body: \(missingParameters).")
            try response.send(json: JSON(["message": "Unable to initialize parameters from request body: \(missingParameters)."]))
                        .status(.badRequest).end()
            return
        }

        let success = try dataAccessor.createEventRSVPs(withEvent: postEvent)

        if success {
            try response.send(json: JSON(["message": "RSVPs sent for event."])).status(.OK).end()
            return
        }

        try response.status(.notModified).end()
    }

    // MARK: PUT

    public func putEvent(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {

        guard let body = request.body, case let .json(json) = body else {
            Log.error("Cannot initialize request body. This endpoint expects the request body to be a valid JSON object.")
            try response.send(json: JSON(["message": "Cannot initialize request body. This endpoint expects the request body to be a valid JSON object."]))
                        .status(.badRequest).end()
            return
        }

        guard let id = request.parameters["id"] else {
            Log.error("Cannot initialize path parameter: id.")
            try response.send(json: JSON(["message": "Cannot initialize path parameter: id."]))
                        .status(.badRequest).end()
            return
        }

        let activities = json["activities"].arrayValue.map({$0.intValue})

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let startTimeString = json["start_time"].stringValue
        let startTime: Date? = startTimeString != "" ? dateFormatter.date(from: startTimeString) : nil

        let updateEvent = Event(
            id: Int(id),
            name: json["name"].string,
            emoji: json["emoji"].string,
            description: json["description"].string,
            host: json["host"].string,
            startTime: startTime,
            location: json["location"].string,
            latitude: json["latitude"].double, longitude: json["longitude"].double,
            isPublic: json["is_public"].int,
            activities: activities, rsvps: nil,
            createdAt: nil, updatedAt: nil)

        let missingParameters = updateEvent.validateParameters(
            ["name", "emoji", "description", "host", "startTime", "location",
                "latitude", "longitude", "isPublic", "activities"])

        if missingParameters.count != 0 {
            Log.error("Unable to initialize parameters from request body: \(missingParameters).")
            try response.send(json: JSON(["message": "Unable to initialize parameters from request body: \(missingParameters)."]))
                        .status(.badRequest).end()
            return
        }

        let success = try dataAccessor.updateEvent(updateEvent)

        if success {
            try response.send(json: JSON(["message": "Event updated."])).status(.OK).end()
            return
        }

        try response.status(.notModified).end()
    }

    public func putRSVPForEvent(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {

        guard let body = request.body, case let .json(json) = body else {
            Log.error("Cannot initialize request body. This endpoint expects the request body to be a valid JSON object.")
            try response.send(json: JSON(["message": "Cannot initialize request body. This endpoint expects the request body to be a valid JSON object."]))
                        .status(.badRequest).end()
            return
        }

        guard let id = request.parameters["id"] else {
            Log.error("Cannot initialize path parameter: id.")
            try response.send(json: JSON(["message": "Cannot initialize path parameter: id."]))
                        .status(.badRequest).end()
            return
        }

        guard let rsvpID = request.parameters["rsvp_id"] else {
            Log.error("Cannot initialize path parameter: rsvp_id.")
            try response.send(json: JSON(["message": "Cannot initialize path parameter: rsvp_id."]))
                        .status(.badRequest).end()
            return
        }

        var event = Event()
        event.id = Int(id)

        // FIXME: Use the userID specified in JWT
        let rsvp = RSVP(
            rsvpID: Int(rsvpID),
            userID: json["user_id"].string,
            eventID: event.id!,
            accepted: json["accepted"].int,
            comment: json["comment"].string
        )

        let missingParameters = rsvp.validateParameters(["userID", "accepted", "comment"])

        if missingParameters.count != 0 {
            Log.error("Unable to initialize parameters from request body: \(missingParameters).")
            try response.send(json: JSON(["message": "Unable to initialize parameters from request body: \(missingParameters)."]))
                        .status(.badRequest).end()
            return
        }

        let success = try dataAccessor.updateEventRSVP(event, rsvp: rsvp)

        if success {
            try response.send(json: JSON(["message": "RSVP updated for event."])).status(.OK).end()
            return
        }

        try response.status(.notModified).end()
    }

    // MARK: DELETE

    public func deleteEvent(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {

        guard let id = request.parameters["id"] else {
            Log.error("Cannot initialize path parameter: id.")
            try response.send(json: JSON(["message": "Cannot initialize path parameter: id."]))
                        .status(.badRequest).end()
            return
        }

        let success = try dataAccessor.deleteEvent(withID: id)

        if success {
            try response.send(json: JSON(["message": "Event deleted."])).status(.noContent).end()
            return
        }

        try response.status(.notModified).end()
    }
}
