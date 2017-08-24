import Foundation
import XCTest

public class FunctionalTests: XCTestCase {

    func testSomething() {
        XCTAssertEqual(200,200)
    }

}

#if os(Linux)
extension FunctionalTests {
    static var allTests: [(String, (FunctionalTests) -> () throws -> Void)] {
        return [
                ("testSomething", testSomething)
        ]
    }
}
#endif
