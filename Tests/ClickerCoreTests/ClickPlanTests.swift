import XCTest
@testable import ClickerCore

final class ClickPlanTests: XCTestCase {
    func testRejectsInvalidInput() {
        var point = ClickPoint(x: 100, y: 200)
        XCTAssertTrue(point.isValid)
        point.hold = .nan
        XCTAssertFalse(point.isValid)
        point.hold = 10
        point.repetitions = 0
        XCTAssertFalse(point.isValid)
        point.repetitions = 1
        point.x = .infinity
        XCTAssertFalse(point.isValid)
    }

    func testRandomDelayHasPositiveFloor() {
        var point = ClickPoint(x: 0, y: 0)
        point.randomDelay = 100
        XCTAssertEqual(point.waitingTime(randomUnit: -1), 0.001)
        XCTAssertEqual(point.waitingTime(randomUnit: 1), 0.15, accuracy: 0.0001)
    }

    func testRandomLocationStaysInCircle() {
        var point = ClickPoint(x: -100, y: 400)
        point.radius = 5
        for angle in stride(from: 0.0, through: Double.pi * 2, by: 0.1) {
            let result = point.location(angle: angle, unitRadius: 0.8)
            XCTAssertLessThanOrEqual(hypot(result.x - point.x, result.y - point.y), 5.00001)
        }
    }

    func testPlanRoundTripAndDuplicateProtection() throws {
        var plan = ClickPlan()
        let point = ClickPoint(x: 100, y: 200)
        plan.points = [point]
        XCTAssertTrue(plan.isValid)
        XCTAssertEqual(try JSONDecoder().decode(ClickPlan.self, from: JSONEncoder().encode(plan)), plan)
        plan.points.append(point)
        XCTAssertFalse(plan.isValid)
        plan.points = [point]
        plan.cycles = -1
        XCTAssertFalse(plan.isValid)
    }
    func testTimingAndCoordinateLimits() {
        var point = ClickPoint(x: -1_000_000, y: 1_000_000)
        point.delay = 3_600_000
        point.hold = 60_000
        point.radius = 500
        point.randomDelay = 60_000
        point.repetitions = 100_000
        XCTAssertTrue(point.isValid)
        point.x = 1_000_001
        XCTAssertFalse(point.isValid)
        point.x = 0
        point.delay = 0
        XCTAssertFalse(point.isValid)
        point.delay = 50
        point.radius = -1
        XCTAssertFalse(point.isValid)
        var plan = ClickPlan()
        plan.points = [ClickPoint(x: 0, y: 0)]
        plan.defaultDelay = .nan
        XCTAssertFalse(plan.isValid)
        plan.defaultDelay = 50
        plan.cycles = 1_000_001
        XCTAssertFalse(plan.isValid)
    }

}
