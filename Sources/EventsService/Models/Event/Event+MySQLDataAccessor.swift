import MySQL

// MARK: - EventMySQLDataAccessorProtocol

public protocol EventMySQLDataAccessorProtocol {
    func getEvents(withID id: String) throws -> [Event]?
    func getEvents() throws -> [Event]?
}

// MARK: - EventMySQLDataAccessor: EventMySQLDataAccessorProtocol

public class EventMySQLDataAccessor: EventMySQLDataAccessorProtocol {

    // MARK: Properties

    let pool: MySQLConnectionPoolProtocol

    let selectQuery = "SELECT *, events.id AS master_id " +
                "FROM events " +
                "LEFT JOIN event_games " +
                "ON events.id = event_games.event_id " +
                "LEFT JOIN rsvps " +
                "ON events.id = rsvps.event_id"

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
        let query = selectQuery + " WHERE events.id=\(id)"
        let result = try execute(query: query)
        let events = result.toEvents()
        return (events.count == 0) ? nil : events
    }

    public func getEvents() throws -> [Event]? {
        let result = try execute(query: selectQuery)
        let events = result.toEvents()
        return (events.count == 0) ? nil : events
    }

    // MARK: Utility

    func execute(builder: MySQLQueryBuilder) throws -> MySQLResultProtocol {
        let connection = try pool.getConnection()
        defer { pool.releaseConnection(connection!) }

        return try connection!.execute(builder: builder)
    }

    func execute(query: String) throws -> MySQLResultProtocol {
        let connection = try pool.getConnection()
        defer { pool.releaseConnection(connection!) }

        return try connection!.execute(query: query)
    }
}
