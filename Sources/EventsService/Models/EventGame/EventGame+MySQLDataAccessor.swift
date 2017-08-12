import MySQL

// MARK: - EventGameMySQLDataAccessor

class EventGameMySQLDataAccessor {

    // MARK: Properties

    let connection: MySQLConnectionProtocol

    let selectGamesForEvents = MySQLQueryBuilder()
            .select(fields: ["id", "activity_id", "event_id", "created_at",
            "updated_at"], table: "event_games")

    // MARK: Initializer

    init(connection: MySQLConnectionProtocol) {
        self.connection = connection
    }

    // MARK: Queries

    func getGamesForEvent(withID id: String) throws -> [EventGame]? {
        let select = selectGamesForEvents.wheres(statement:"WHERE event_id=?", parameters: id)

        let result = try connection.execute(builder: select)
        let eventGames = result.toEventGames()

        return (eventGames.count == 0) ? nil : eventGames
    }
}
