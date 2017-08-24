import MySQL

// MARK: - EventMySQLDataAccessorProtocol

public protocol EventMySQLDataAccessorProtocol {
    func getEvents(withID id: String) throws -> [Event]?
    func getEvents() throws -> [Event]?
    func createEvent(_ event: Event) throws -> Bool
    func updateEvent(_ event: Event) throws -> Bool
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
        return false
    }

    public func updateEvent(_ event: Event) throws -> Bool {
        return false
    }

    public func deleteEvent(withID id: String) throws -> Bool {
        return false
    }

    public func getEvents(withID id: String) throws -> [Event]? {
        let selectEvents = MySQLQueryBuilder()
            .select(fields: ["id", "name", "emoji", "description", "host", "start_time", "location", "public"], table: "events")
        let selectEventGames = MySQLQueryBuilder()
            .select(fields: ["activity_id", "event_id"], table: "event_games")
        let selectRSVPs = MySQLQueryBuilder()
            .select(fields: ["user_id", "event_id", "accepted", "comment"], table: "rsvps")

        let selectQuery = selectEvents.wheres(statement:"id=?", parameters: id)
            .join(builder: selectEventGames, from: "id", to: "event_id", type: .LeftJoin)
            .join(builder: selectRSVPs, from: "id", to: "event_id", type: .LeftJoin)

        print(selectQuery.build())

        let result = try execute(builder: selectQuery)
        let events = result.toEvents()
        return (events.count == 0) ? nil : events
    }

    public func getEvents() throws -> [Event]? {
        let selectEvents = MySQLQueryBuilder()
            .select(fields: ["id", "name", "emoji", "description", "host", "start_time", "location", "public"], table: "events")
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
