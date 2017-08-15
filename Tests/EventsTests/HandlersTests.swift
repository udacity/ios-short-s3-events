import Foundation
import XCTest
import KituraNet

@testable import KituraHTTPTest
@testable import Kitura
@testable import EventsService
@testable import MySQL

/*
  HandlersTests verify if the `Handlers` object functions correctly.
*/
public class HandlersTests: XCTestCase {

    // MARK: from Kitura
    var routerRequest: RouterRequest? // Request to server
    var routerResponse: RouterResponse? // Response from server

    // MARK: from EventsService
    var handlers: Handlers? // Request handler

    var mockDAO: MockEventDataAccessor?

    // MARK: from KituraHTTPTest (Nic Jackson)
    var request: Request? // A stubbed request
    // A stubbed response that is "captured" instead of being output to the
    // requester and stored in an internal buffer; this enables us to test responses
    var responseRecorder: ResponseRecorder?

    public override func setUp() {
        request = Request()

        var routerStack = Stack<Router>()
        routerStack.push(Router())

        routerRequest = RouterRequest(request: request!)
        responseRecorder = ResponseRecorder()
        routerResponse = RouterResponse(
                response: responseRecorder!,
                routerStack: routerStack,
                request: routerRequest!)

        mockDAO = MockEventDataAccessor()

        handlers = Handlers(dataAccessor: mockDAO!)
    }

    func testQueriesDataBaseForEvents() throws {
        routerRequest = RouterRequest(request: request!)

        try handlers!.getEvents(request: routerRequest!, response: routerResponse!) {}

        XCTAssertTrue(mockDAO!.getEventCalled)
    }

    func testReturnsEventsOnSuccessfulQuery() throws {
        // setup
        routerRequest = RouterRequest(request: request!)

        // setup expectation on the mock
        var event = Event()
        event.id = 123

        let events = [ event ]
        mockDAO!.getEventReturn = events

        // execute
        try handlers!.getEvents(request: routerRequest!, response: routerResponse!) {}

        // assert
        let body = responseRecorder!.jsonBody()
        XCTAssertEqual(123, body[0]["id"])
        XCTAssertEqual(HTTPStatusCode.OK, responseRecorder!.statusCode)
    }

    func testReturnsNotFoundWhenNoEventsFromQuery() throws {
        routerRequest = RouterRequest(request: request!)

        // because we are not setting the expectation on the mock the callback
        // will never get called and query result will be nil
        try handlers!.getEvents(request: routerRequest!, response: routerResponse!) {}

        XCTAssertEqual(HTTPStatusCode.notFound, responseRecorder!.statusCode)
    }
}

#if os(Linux)
extension HandlersTests {
    static var allTests: [(String, (HandlersTests) -> () throws -> Void)] {
        return [
            ("testQueriesDataBaseForEvents", testQueriesDataBaseForEvents),
            ("testReturnsEventsOnSuccessfulQuery", testReturnsEventsOnSuccessfulQuery),
            ("testReturnsNonFoundWhenNoEventsFromQuery", testReturnsNotFoundWhenNoEventsFromQuery)
       ]
    }
}
#endif
