import MySQL
import LoggerAPI

// MARK: - EventMySQLDataAccessorProtocol

public protocol EventMySQLDataAccessorProtocol {
    func getEvents(withID id: String) throws -> [Event]?
    func getEvents() throws -> [Event]?
    func createEvent(_ event: Event) throws -> Bool
    func updateEvent(_ event: Event) throws -> Bool
    func postEventRSVPs(withEvent event: Event) throws -> Bool
    func patchEventRSVPs(withEvent event: Event) throws -> Bool
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

    // MARK: Queries

    public func createEvent(_ event: Event) throws -> Bool {
        let insertEventQuery = MySQLQueryBuilder()
            .insert(data: event.toMySQLRow(), table: "events")
        let selectLastEventID = MySQLQueryBuilder()
            .select(fields: [MySQLFunction.LastInsertID], table: "events")
        var result: MySQLResultProtocol

        guard let connection = try pool.getConnection() as? MySQLConnection else {
            Log.error("could not get a connection")
            return false
        }
        defer { pool.releaseConnection(connection) }

        func rollbackEventTransaction(withConnection: MySQLConnection, message: String) -> Bool {
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

    public func updateEvent(_ event: Event) throws -> Bool {
        return false
    }

    public func postEventRSVPs(withEvent event: Event) throws -> Bool {
        let selectEventID = MySQLQueryBuilder()
            .select(fields: ["id"], table: "events")
            .wheres(statement: "id=?", parameters: "\(event.id!)")
        var result: MySQLResultProtocol

        guard let connection = try pool.getConnection() as? MySQLConnection else {
            Log.error("could not get a connection")
            return false
        }
        defer { pool.releaseConnection(connection) }

        func rollbackEventTransaction(withConnection: MySQLConnection, message: String) -> Bool {
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

    public func patchEventRSVPs(withEvent event: Event) throws -> Bool {
        return false
    }

    public func deleteEvent(withID id: String) throws -> Bool {
        let deleteEventQuery = MySQLQueryBuilder()
                .delete(fromTable: "events")
                .wheres(statement: "id=?", parameters: "\(id)")
        let deleteEventGameQuery = MySQLQueryBuilder()
                .delete(fromTable: "event_games")
                .wheres(statement: "event_id=?", parameters: "\(id)")
        let deleteRSVPQuery = MySQLQueryBuilder()
                .delete(fromTable: "rsvps")
                .wheres(statement: "event_id=?", parameters: "\(id)")
        var result: MySQLResultProtocol

        guard let connection = try pool.getConnection() as? MySQLConnection else {
            Log.error("could not get a connection")
            return false
        }
        defer { pool.releaseConnection(connection) }

        func rollbackEventTransaction(withConnection: MySQLConnection, message: String) -> Bool {
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

    public func getEvents(withID id: String) throws -> [Event]? {
        let selectEvents = MySQLQueryBuilder()
            .select(fields: ["id", "name", "emoji", "description", "host", "start_time", "location", "is_public"], table: "events")
        let selectEventGames = MySQLQueryBuilder()
            .select(fields: ["activity_id", "event_id"], table: "event_games")
        let selectRSVPs = MySQLQueryBuilder()
            .select(fields: ["user_id", "event_id", "accepted", "comment"], table: "rsvps")

        let selectQuery = selectEvents.wheres(statement:"id=?", parameters: id)
            .join(builder: selectEventGames, from: "id", to: "event_id", type: .LeftJoin)
            .join(builder: selectRSVPs, from: "id", to: "event_id", type: .LeftJoin)

        let result = try execute(builder: selectQuery)
        let events = result.toEvents()
        return (events.count == 0) ? nil : events
    }

    public func getEvents() throws -> [Event]? {
        let selectEvents = MySQLQueryBuilder()
            .select(fields: ["id", "name", "emoji", "description", "host", "start_time", "location", "is_public"], table: "events")
        let selectEventGames = MySQLQueryBuilder()
            .select(fields: ["activity_id", "event_id"], table: "event_games")
        let selectRSVPs = MySQLQueryBuilder()
            .select(fields: ["user_id", "event_id", "accepted", "comment"], table: "rsvps")

        let selectQuery = selectEvents
            .join(builder: selectEventGames, from: "id", to: "event_id", type: .LeftJoin)
            .join(builder: selectRSVPs, from: "id", to: "event_id", type: .LeftJoin)

        let result = try execute(builder: selectQuery)
        let events = result.toEvents()
        return (events.count == 0) ? nil : events
    }

    // MARK: Utility

    func execute(builder: MySQLQueryBuilder) throws -> MySQLResultProtocol {
        let connection = try pool.getConnection()
        defer { pool.releaseConnection(connection!) }

        return try connection!.execute(builder: builder)
    }
}
