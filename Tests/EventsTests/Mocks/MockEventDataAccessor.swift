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

    var postEventRSVPsReturn: Bool = false
    var postEventRSVPsError: Error?
    var postEventRSVPsCalled: Bool = false

    var patchEventRSVPsReturn: Bool = false
    var patchEventRSVPsError: Error?
    var patchEventRSVPsCalled: Bool = false

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

    func getEvents(withID id: String, pageSize: Int, pageNumber: Int) throws -> [Event]? {
        getEventCalled = true

        if let err = getEventError {
            throw err
        }

        return getEventReturn
    }

    func getEvents(pageSize: Int = 10, pageNumber: Int = 1, type: EventScheduleType = .all) throws -> [Event]? {
        getEventCalled = true

        if let err = getEventError {
            throw err
        }

        return getEventReturn
    }

    func postEventRSVPs(withEvent event: Event) throws -> Bool {
        postEventRSVPsCalled = true

        if let err = postEventRSVPsError {
            throw err
        }

        return postEventRSVPsReturn
    }

    func patchEventRSVPs(withEvent event: Event) throws -> Bool {
        patchEventRSVPsCalled = true

        if let err = patchEventRSVPsError {
            throw err
        }

        return patchEventRSVPsReturn
    }
}
