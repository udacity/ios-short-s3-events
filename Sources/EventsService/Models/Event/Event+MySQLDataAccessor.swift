import MySQL

// MARK: - EventMySQLDataAccessor

class EventMySQLDataAccessor {

    // MARK: Properties

    let connection: MySQLConnectionProtocol

    let selectEvents = MySQLQueryBuilder()
            .select(fields: ["id", "name", "emoji", "description", "host", "start_time",
            "location", "public", "created_at", "updated_at"], table: "events")

    // MARK: Initializer

    init(connection: MySQLConnectionProtocol) {
        self.connection = connection
    }

    // MARK: Queries


    func getEvents(withID id: String) throws -> [Event]? {
        let select = selectEvents.wheres(statement:"WHERE Id=?", parameters: id)

        let result = try connection.execute(builder: select)
        let events = result.toEvents()

        return (events.count == 0) ? nil : events
    }

    func getEvents() throws -> [Event]? {
        let result = try connection.execute(builder: selectEvents)
        let events = result.toEvents()

        return (events.count == 0) ? nil : events
    }
}
