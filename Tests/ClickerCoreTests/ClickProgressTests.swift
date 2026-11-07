import XCTest
@testable import ClickerCore

final class ClickProgressTests: XCTestCase {
    func testCheckpointsFollowRepetitionsAndFiniteCycles() {
        var plan = ClickPlan()
        var first = ClickPoint(x: 0, y: 0)
        first.repetitions = 2
        var second = ClickPoint(x: 100, y: 100)
        second.repetitions = 3
        plan.points = [first, second]
        plan.cycles = 2
        var progress = ClickProgress()
        let expected = [0, 0, 1, 1, 1, 0, 0, 1, 1, 1]
        for (index, point) in expected.enumerated() {
            XCTAssertEqual(progress.pointIndex, point)
            XCTAssertEqual(progress.advance(in: plan), index == expected.count - 1)
        }
        XCTAssertEqual(progress.completedCycles, 2)
    }

    func testResumeContinuesFromCheckpointInsteadOfStartingOver() {
        var plan = ClickPlan()
        var point = ClickPoint(x: 0, y: 0)
        point.repetitions = 3
        plan.points = [point]
        var progress = ClickProgress()
        XCTAssertFalse(progress.advance(in: plan))
        XCTAssertEqual(progress.repetitionIndex, 1)
        // Pausing does not advance an unfinished action or discard the cursor.
        var resumed = progress
        XCTAssertFalse(resumed.advance(in: plan))
        XCTAssertEqual(resumed.repetitionIndex, 2)
        XCTAssertFalse(resumed.advance(in: plan))
        XCTAssertEqual(resumed.completedCycles, 1)
        XCTAssertEqual(resumed.repetitionIndex, 0)
    }
}
