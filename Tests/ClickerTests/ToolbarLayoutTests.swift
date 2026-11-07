import XCTest
@testable import Clicker

final class ToolbarLayoutTests: XCTestCase {
    let main = CGRect(x: 0, y: 0, width: 1440, height: 880)

    func testDefaultIsCenteredBelowMenuBar() {
        let point = ToolbarLayout.origin(saved: nil, screens: [main], preferred: main)
        XCTAssertEqual(point.x, 578)
        XCTAssertEqual(point.y, 812)
        XCTAssertEqual(point.y + ToolbarLayout.size.height, main.maxY - 16)
    }

    func testRestoresPositionOnSecondaryDisplay() {
        let secondary = CGRect(x: -1280, y: 100, width: 1280, height: 900)
        XCTAssertEqual(ToolbarLayout.origin(saved: [-900, 600], screens: [main, secondary], preferred: main), CGPoint(x: -900, y: 600))
    }

    func testDisconnectedOrPartiallyOffscreenPositionReturnsToDefault() {
        let expected = ToolbarLayout.origin(saved: nil, screens: [main], preferred: main)
        for saved in [[-900.0, 600], [1400, 200], [500, 860]] {
            XCTAssertEqual(ToolbarLayout.origin(saved: saved, screens: [main], preferred: main), expected)
        }
    }

    func testMalformedStoredCoordinatesAreIgnored() {
        let expected = ToolbarLayout.origin(saved: nil, screens: [main], preferred: main)
        for saved in [[], [10], [1, 2, 3], [.nan, 100], [100, .infinity]] {
            XCTAssertEqual(ToolbarLayout.origin(saved: saved, screens: [main], preferred: main), expected)
        }
    }
}
