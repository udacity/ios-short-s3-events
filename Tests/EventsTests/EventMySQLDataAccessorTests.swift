import XCTest

@testable import EventsService
@testable import MySQL

class EventMySQLDataAccessorTests: XCTestCase {
    var connection: MockMySQLConnection?
    var connectionPool: MockMySQLConnectionPool?
    var dataAccessor: EventMySQLDataAccessor?

    public override func setUp() {
        connection = MockMySQLConnection()

        let connectionString = MySQLConnectionString(host: "127.0.0.1")
        connectionPool = MockMySQLConnectionPool(connectionString: connectionString,
                                                  poolSize: 1,
                                                  defaultCharset: "utf8")
        connectionPool!.getConnectionReturn = connection

        dataAccessor = EventMySQLDataAccessor(pool: connectionPool!)
    }

    func testCreateEventCallsExecute() throws {
        _ = try dataAccessor!.createEvent(Event())

        XCTAssertTrue(connection!.executeBuilderCalled)
    }

    func testCreateEventReturnsTrueOnSuccess() throws {
        let result = MockMySQLResult()
        result.affectedRows = 1
        connection!.executeMySQLResultReturn = result

        let created = try dataAccessor!.createEvent(Event())

        XCTAssertTrue(created)
    }

    func testCreateEventReturnsFalseOnFail() throws {
        let result = MockMySQLResult()
        result.affectedRows = 0
        connection!.executeMySQLResultReturn = result

        let created = try dataAccessor!.createEvent(Event())

        XCTAssertFalse(created)
    }

    func testUpdateEventCallsExecute() throws {
        let result = MockMySQLResult()
        result.affectedRows = 0
        connection!.executeMySQLResultReturn = result

        var event = Event()
        event.id = 1234
        _ = try dataAccessor!.updateEvent(event)

        let query = connection!.executeBuilderParams?.build()
        let containsWhere = query!.contains("WHERE Id='1234'")
        XCTAssertTrue(containsWhere, "query should have been executed with correct parameters: \(query!)")
    }

    func testUpdateEventReturnsTrueOnSuccess() throws {
        let result = MockMySQLResult()
        result.affectedRows = 1
        connection!.executeMySQLResultReturn = result

        var event = Event()
        event.id = 1234
        let created = try dataAccessor!.updateEvent(event)

        XCTAssertTrue(created)
    }

    func testUpdateEventReturnsFalseOnFail() throws {
        let result = MockMySQLResult()
        result.affectedRows = 0
        connection!.executeMySQLResultReturn = result

        var event = Event()
        event.id = 1234
        let created = try dataAccessor!.updateEvent(event)

        XCTAssertFalse(created)
    }

    func testDeleteEventCallsExecute() throws {
        let result = MockMySQLResult()
        result.affectedRows = 0
        connection!.executeMySQLResultReturn = result

        _ = try dataAccessor!.deleteEvent(withID: "1234")

        let query = connection!.executeBuilderParams?.build()
        let containsWhere = query!.contains("WHERE Id='1234'")
        XCTAssertTrue(containsWhere, "query should have been executed with correct parameters: \(query!)")
    }

    func testDeleteEventReturnsTrueOnSuccess() throws {
        let result = MockMySQLResult()
        result.affectedRows = 1
        connection!.executeMySQLResultReturn = result

        let created = try dataAccessor!.deleteEvent(withID: "1234")

        XCTAssertTrue(created)
    }

    func testDeleteEventReturnsFalseOnFail() throws {
        let result = MockMySQLResult()
        result.affectedRows = 0
        connection!.executeMySQLResultReturn = result

        let created = try dataAccessor!.deleteEvent(withID: "1234")

        XCTAssertFalse(created)
    }

    func testGetEventWithIDCallsExecute() throws {
        let result = MockMySQLResult()
        result.affectedRows = 0
        connection!.executeMySQLResultReturn = result

        _ = try dataAccessor!.getEvents(withID: "1234")

        let query = connection!.executeBuilderParams?.build()
        let containsWhere = query!.contains("WHERE Id='1234'")
        XCTAssertTrue(containsWhere, "query should have been executed with correct parameters: \(query!)")
    }

    func testGetEventWithIDReturnsEventsOnSuccess() throws {
        let result = MockMySQLResult()
        result.affectedRows = -1
        result.results = [["id": 1234]]
        connection!.executeMySQLResultReturn = result

        let events = try dataAccessor!.getEvents(withID: "1234")

        XCTAssertEqual(1234, events![0].id)
    }

    func testGetEventWithIDReturnsNilOnFail() throws {
        let result = MockMySQLResult()
        result.affectedRows = 0
        connection!.executeMySQLResultReturn = result

        let events = try dataAccessor!.getEvents(withID: "1234")

        XCTAssertNil(events)
    }

    func testGetEventsCallsExecute() throws {
        let result = MockMySQLResult()
        result.affectedRows = 0
        connection!.executeMySQLResultReturn = result

        _ = try dataAccessor!.getEvents()

        let query = connection!.executeBuilderParams?.build()
        let containsWhere = query!.contains("WHERE")
        XCTAssertFalse(containsWhere, "query should have not have been executed with a where clause, query: \(query!)")
    }

    func testGetEventsReturnsEventsOnSuccess() throws {
        let result = MockMySQLResult()
        result.affectedRows = -1
        result.results = [["id": 1234]]
        connection!.executeMySQLResultReturn = result

        let events = try dataAccessor!.getEvents()

        XCTAssertEqual(1234, events![0].id)
    }

    func testGetEventsReturnsNilOnFail() throws {
        let result = MockMySQLResult()
        result.affectedRows = 0
        connection!.executeMySQLResultReturn = result

        let events = try dataAccessor!.getEvents()

        XCTAssertNil(events)
    }

}

#if os(Linux)
extension EventMySQLDataAccessorTests {
    static var allTests: [(String, (EventMySQLDataAccessorTests) -> () throws -> Void)] {
        return [
            ("testCreateEventCallsExecute", testCreateEventCallsExecute),
            ("testCreateEventReturnsTrueOnSuccess", testCreateEventReturnsTrueOnSuccess),
            ("testCreateEventReturnsFalseOnFail", testCreateEventReturnsFalseOnFail),
            ("testUpdateEventCallsExecute", testUpdateEventCallsExecute),
            ("testUpdateEventReturnsTrueOnSuccess", testUpdateEventReturnsTrueOnSuccess),
            ("testUpdateEventReturnsFalseOnFail", testUpdateEventReturnsFalseOnFail),
            ("testDeleteEventCallsExecute", testDeleteEventCallsExecute),
            ("testDeleteEventReturnsTrueOnSuccess", testDeleteEventReturnsTrueOnSuccess),
            ("testDeleteEventReturnsFalseOnFail", testDeleteEventReturnsFalseOnFail),
            ("testGetEventWithIDCallsExecute", testGetEventWithIDCallsExecute),
            ("testGetEventWithIDReturnsEventsOnSuccess", testGetEventWithIDReturnsEventsOnSuccess),
            ("testGetEventWithIDReturnsNilOnFail", testGetEventWithIDReturnsNilOnFail),
            ("testGetEventsCallsExecute", testGetEventsCallsExecute),
            ("testGetEventsReturnsEventsOnSuccess", testGetEventsReturnsEventsOnSuccess),
            ("testGetEventsReturnsNilOnFail", testGetEventsReturnsNilOnFail)
        ]
    }
}
#endif
