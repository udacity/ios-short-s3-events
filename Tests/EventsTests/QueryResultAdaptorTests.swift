import Foundation
import XCTest
@testable import MySQL

public class QueryResultAdaptorTests: XCTestCase {

    public func testSQLResultReturnsEvent() {
        let queryResult = MockMySQLResult()
        queryResult.results = [["master_id": 123 as Any]]

        var events = queryResult.toEvents()
        XCTAssertEqual(123, events[0].id)
    }
}

#if os(Linux)
extension QueryResultAdaptorTests {
    static var allTests: [(String, (QueryResultAdaptorTests) -> () throws -> Void)] {
        return [
            ("testSQLResultReturnsEvent", testSQLResultReturnsEvent),
       ]
    }
}
#endif
