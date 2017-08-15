import EventsService

class MockEventDataAccessor: EventMySQLDataAccessorProtocol {
    var createEventReturn: Bool = false
    var createEventError: Error?
    var createEventCalled: Bool = false

    var updateEventReturn: Bool = false
    var updateEventError: Error?
    var updateEventCalled: Bool = false

    var deleteEventReturn: Bool = false
    var deleteEventError: Error?
    var deleteEventCalled: Bool = false

    var getEventReturn: [Event]?
    var getEventError: Error?
    var getEventCalled: Bool = false

    func createEvent(_ event: Event) throws -> Bool {
        createEventCalled = true

        if let err = createEventError {
            throw err
        }

        return createEventReturn
    }

    func updateEvent(_ event: Event) throws -> Bool {
        updateEventCalled = true

        if let err = updateEventError {
            throw err
        }

        return updateEventReturn
    }

    func deleteEvent(withID id: String) throws -> Bool {
        deleteEventCalled = true

        if let err = deleteEventError {
            throw err
        }

        return deleteEventReturn
    }

    func getEvents(withID id: String) throws -> [Event]? {
        getEventCalled = true

        if let err = getEventError {
            throw err
        }

        return getEventReturn
    }

    func getEvents() throws -> [Event]? {
        getEventCalled = true

        if let err = getEventError {
            throw err
        }

        return getEventReturn
    }
}
