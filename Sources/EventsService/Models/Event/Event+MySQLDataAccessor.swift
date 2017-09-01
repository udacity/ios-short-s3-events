import MySQL
import LoggerAPI

// MARK: - EventMySQLDataAccessorProtocol

public protocol EventMySQLDataAccessorProtocol {
    func getEvents(pageSize: Int, pageNumber: Int, type: EventScheduleType) throws -> [Event]?
    func getEvents(withIDs ids: [String], pageSize: Int, pageNumber: Int) throws -> [Event]?
    func getEventIDsNearLocation(latitude: Double, longitude: Double, miles: Int, pageSize: Int, pageNumber: Int) throws -> [String]?
    func getRSVPs(forEventID: String, pageSize: Int, pageNumber: Int) throws -> [RSVP]?
    func getRSVPsForUser(pageSize: Int, pageNumber: Int) throws -> [RSVP]?
    func createEvent(_ event: Event) throws -> Bool
    func updateEvent(_ event: Event) throws -> Bool
    func postEventRSVPs(withEvent event: Event) throws -> Bool
    func deleteEvent(withID id: String) throws -> Bool
}

// MARK: - EventMySQLDataAccessor: EventMySQLDataAccessorProtocol

public class EventMySQLDataAccessor: EventMySQLDataAccessorProtocol {

    // MARK: Properties

    let pool: MySQLConnectionPoolProtocol

    // MARK: Initializer

    public init(pool: MySQLConnectionPoolProtocol) {
        self.pool = pool
    }

    // MARK: READ

    public func getEvents(pageSize: Int = 10, pageNumber: Int = 1, type: EventScheduleType = .all) throws -> [Event]? {
        // select event ids and apply pagination before doing joins
        var selectEventIDs = MySQLQueryBuilder()
            .select(fields: ["id"], table: "events")

        switch type {
        case .upcoming:
            selectEventIDs = selectEventIDs.wheres(statement: "start_time >= CURDATE()", parameters: [])
        case .past:
            selectEventIDs = selectEventIDs.wheres(statement: "start_time < CURDATE()", parameters: [])
        default:
            break
        }

        var events = [Event]()

        let simpleResults = try execute(builder: selectEventIDs)
        simpleResults.seek(offset: cacluateOffset(pageSize: pageSize, pageNumber: pageNumber))

        let simpleEvents = simpleResults.toEvents(pageSize: pageSize)
        let ids = simpleEvents.map({String($0.id!)})

        // once the ids are determind, perform the joins
        if ids.count > 0 {
            let selectEvents = MySQLQueryBuilder()
                .select(fields: ["id", "name", "emoji", "description", "host", "start_time",
                    "location", "latitude", "longitude", "is_public"], table: "events")
            let selectEventGames = MySQLQueryBuilder()
                .select(fields: ["activity_id", "event_id"], table: "event_games")
            let selectRSVPs = MySQLQueryBuilder()
                .select(fields: ["user_id", "event_id", "accepted", "comment"], table: "rsvps")
            let selectQuery = selectEvents.wheres(statement: "id IN (?)", parameters: ids)
                .join(builder: selectEventGames, from: "id", to: "event_id", type: .LeftJoin)
                .join(builder: selectRSVPs, from: "id", to: "event_id", type: .LeftJoin)

            let result = try execute(builder: selectQuery)
            events = result.toEvents()
        }

        return (events.count == 0) ? nil : events
    }

    public func getEvents(withIDs ids: [String], pageSize: Int = 10, pageNumber: Int = 1) throws -> [Event]? {
        let selectEvents = MySQLQueryBuilder()
            .select(fields: ["id", "name", "emoji", "description", "host", "start_time",
                "location", "latitude", "longitude", "is_public"], table: "events")
        let selectEventGames = MySQLQueryBuilder()
            .select(fields: ["activity_id", "event_id"], table: "event_games")
        let selectRSVPs = MySQLQueryBuilder()
            .select(fields: ["user_id", "event_id", "accepted", "comment"], table: "rsvps")

        let selectQuery = selectEvents.wheres(statement:"id IN (?)", parameters: ids)
            .join(builder: selectEventGames, from: "id", to: "event_id", type: .LeftJoin)
            .join(builder: selectRSVPs, from: "id", to: "event_id", type: .LeftJoin)

        let result = try execute(builder: selectQuery)
        result.seek(offset: cacluateOffset(pageSize: pageSize, pageNumber: pageNumber))

        let events = result.toEvents(pageSize: pageSize)
        return (events.count == 0) ? nil : events
    }

    public func getEventIDsNearLocation(latitude: Double, longitude: Double, miles: Int, pageSize: Int = 10, pageNumber: Int = 1) throws -> [String]? {
        let connection = try pool.getConnection()
        defer { pool.releaseConnection(connection!) }

        let procedureCall = "CALL events_within_miles_from_location(\(latitude), \(longitude), \(miles))"

        let result = try connection!.execute(query: procedureCall)
        result.seek(offset: cacluateOffset(pageSize: pageSize, pageNumber: pageNumber))

        let events = result.toEvents(pageSize: pageSize)
        let ids = events.map({String($0.id!)})
        return (ids.count == 0) ? nil : ids
    }

    public func getRSVPs(forEventID: String, pageSize: Int = 10, pageNumber: Int = 1) throws -> [RSVP]? {
        let selectRSVPs = MySQLQueryBuilder()
            .select(fields: ["user_id", "accepted", "comment"], table: "rsvps")
            .wheres(statement: "event_id=?", parameters: forEventID)

        let result = try execute(builder: selectRSVPs)
        result.seek(offset: cacluateOffset(pageSize: pageSize, pageNumber: pageNumber))

        let rsvps = result.toRSVPs(pageSize: pageSize)
        return (rsvps.count == 0) ? nil : rsvps
    }

    public func getRSVPsForUser(pageSize: Int = 10, pageNumber: Int = 1) throws -> [RSVP]? {
        return nil
    }

    // MARK: CREATE

    public func createEvent(_ event: Event) throws -> Bool {
        let insertEventQuery = MySQLQueryBuilder()
            .insert(data: event.toMySQLRow(), table: "events")
        let selectLastEventID = MySQLQueryBuilder()
            .select(fields: [MySQLFunction.LastInsertID], table: "events")
        var result: MySQLResultProtocol

        guard let connection = try pool.getConnection() else {
            Log.error("could not get a connection")
            return false
        }
        defer { pool.releaseConnection(connection) }

        func rollbackEventTransaction(withConnection: MySQLConnectionProtocol, message: String) -> Bool {
            Log.error("could not create event: \(message)")
            try! connection.rollbackTransaction()
            return false
        }

        connection.startTransaction()

        do {
            result = try connection.execute(builder: insertEventQuery)
            if result.affectedRows < 1 {
                return rollbackEventTransaction(withConnection: connection, message: "failed to insert event")
            }

            result = try connection.execute(builder: selectLastEventID)
            guard let row = result.nextResult(), let lastEventID = row["LAST_INSERT_ID()"] as? Int else {
                return rollbackEventTransaction(withConnection: connection, message: "could not get last inserted event id")
            }

            if let activities = event.activities {
                for activityID in activities {
                    let insertEventGameQuery = MySQLQueryBuilder()
                        .insert(data: ["activity_id": activityID, "event_id": lastEventID], table: "event_games")
                    result = try connection.execute(builder: insertEventGameQuery)
                    if result.affectedRows < 1 {
                        return rollbackEventTransaction(withConnection: connection, message: "failed to insert \(activityID) into event_games")
                    }
                }
            }

            if let rsvps = event.rsvps {
                for rsvp in rsvps {
                    let insertRSVPQuery = MySQLQueryBuilder()
                        .insert(data: [
                            "user_id": rsvp.userID!,
                            "event_id": lastEventID,
                            "accepted": -1,
                            "comment": ""
                        ], table: "rsvps")
                    result = try connection.execute(builder: insertRSVPQuery)
                    if result.affectedRows < 1 {
                        return rollbackEventTransaction(withConnection: connection, message: "failed to insert \(rsvp) into rsvps")
                    }
                }
            }

            try connection.commitTransaction()

        } catch {
            return rollbackEventTransaction(withConnection: connection, message: "createEvent failed")
        }

        return true
    }

    public func postEventRSVPs(withEvent event: Event) throws -> Bool {
        let selectEventID = MySQLQueryBuilder()
            .select(fields: ["id"], table: "events")
            .wheres(statement: "Id=?", parameters: "\(event.id!)")
        var result: MySQLResultProtocol

        guard let connection = try pool.getConnection() else {
            Log.error("could not get a connection")
            return false
        }
        defer { pool.releaseConnection(connection) }

        func rollbackEventTransaction(withConnection: MySQLConnectionProtocol, message: String) -> Bool {
            Log.error("could not post event rsvps: \(message)")
            try! connection.rollbackTransaction()
            return false
        }

        connection.startTransaction()

        do {
            result = try connection.execute(builder: selectEventID)
            guard let row = result.nextResult(), let eventID = row["id"] as? Int else {
                return rollbackEventTransaction(withConnection: connection, message: "event with id \(event.id!) does not exist")
            }

            if let rsvps = event.rsvps {
                for rsvp in rsvps {
                    let insertRSVPQuery = MySQLQueryBuilder()
                        .insert(data: [
                            "user_id": rsvp.userID!,
                            "event_id": eventID,
                            "accepted": -1,
                            "comment": ""
                        ], table: "rsvps")
                    result = try connection.execute(builder: insertRSVPQuery)
                    if result.affectedRows < 1 {
                        return rollbackEventTransaction(withConnection: connection, message: "failed to insert \(rsvp) into rsvps")
                    }
                }
            }
            try connection.commitTransaction()

        } catch {
            return rollbackEventTransaction(withConnection: connection, message: "postEventRSVPs failed")
        }

        return true
    }

    // MARK: UPDATE

    public func updateEvent(_ event: Event) throws -> Bool {
        return false
    }

    // MARK: DELETE

    public func deleteEvent(withID id: String) throws -> Bool {
        let deleteEventQuery = MySQLQueryBuilder()
                .delete(fromTable: "events")
                .wheres(statement: "Id=?", parameters: "\(id)")
        let deleteEventGameQuery = MySQLQueryBuilder()
                .delete(fromTable: "event_games")
                .wheres(statement: "event_id=?", parameters: "\(id)")
        let deleteRSVPQuery = MySQLQueryBuilder()
                .delete(fromTable: "rsvps")
                .wheres(statement: "event_id=?", parameters: "\(id)")
        var result: MySQLResultProtocol

        guard let connection = try pool.getConnection() else {
            Log.error("could not get a connection")
            return false
        }
        defer { pool.releaseConnection(connection) }

        func rollbackEventTransaction(withConnection: MySQLConnectionProtocol, message: String) -> Bool {
            Log.error("could not delete event: \(message)")
            try! connection.rollbackTransaction()
            return false
        }

        connection.startTransaction()

        do {
            result = try connection.execute(builder: deleteEventQuery)
            if result.affectedRows < 1 {
                return rollbackEventTransaction(withConnection: connection, message: "failed to delete event")
            }

            result = try connection.execute(builder: deleteEventGameQuery)
            if result.affectedRows < 1 {
                return rollbackEventTransaction(withConnection: connection, message: "failed to delete event games")
            }

            result = try connection.execute(builder: deleteRSVPQuery)
            if result.affectedRows < 1 {
                return rollbackEventTransaction(withConnection: connection, message: "failed to delete rsvps")
            }

            try connection.commitTransaction()

        } catch {
            return rollbackEventTransaction(withConnection: connection, message: "deleteEvent failed")
        }

        return true
    }

    // MARK: Utility

    func execute(builder: MySQLQueryBuilder) throws -> MySQLResultProtocol {
        let connection = try pool.getConnection()
        defer { pool.releaseConnection(connection!) }

        return try connection!.execute(builder: builder)
    }

    func cacluateOffset(pageSize: Int, pageNumber: Int) -> Int64 {
        return Int64(pageNumber > 1 ? pageSize * (pageNumber - 1) : 0)
    }
}
