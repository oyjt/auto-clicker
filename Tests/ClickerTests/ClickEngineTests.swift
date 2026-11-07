import XCTest
@testable import Clicker

final class ClickEngineTests: XCTestCase {
    @MainActor
    func testParameterSavePreservesDraggedPosition() async throws {
        let suite = "ClickerTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let engine = ClickEngine(defaults: defaults)
        var edited = engine.plan.points[0]
        edited.hold = 25
        engine.movePoint(edited.id, to: CGPoint(x: 230, y: 450))
        engine.updatePoint(edited)
        XCTAssertEqual(engine.plan.points[0].x, 230)
        XCTAssertEqual(engine.plan.points[0].y, 450)
        XCTAssertEqual(engine.plan.points[0].hold, 25)
        let restored = ClickEngine(defaults: defaults)
        XCTAssertEqual(restored.plan, engine.plan)
    }

    @MainActor
    func testInvalidParameterEditDoesNotReplaceValidPlan() async throws {
        let suite = "ClickerTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let engine = ClickEngine(defaults: defaults)
        let original = engine.plan
        var edited = original.points[0]
        edited.hold = 0
        engine.updatePoint(edited)
        XCTAssertEqual(engine.plan, original)
        engine.deletePoint()
        XCTAssertEqual(engine.plan.points.count, 1)
    }
    @MainActor
    func testPausePreservesCountsAndStopResetsSession() async throws {
        let suite = "ClickerTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let engine = ClickEngine(defaults: defaults)
        engine.running = true
        engine.completedClicks = 8
        engine.completedCycles = 2
        engine.pause()
        XCTAssertFalse(engine.running)
        XCTAssertTrue(engine.paused)
        XCTAssertEqual(engine.completedClicks, 8)
        XCTAssertEqual(engine.completedCycles, 2)
        engine.stop()
        XCTAssertFalse(engine.paused)
        XCTAssertEqual(engine.completedClicks, 0)
        XCTAssertEqual(engine.completedCycles, 0)
    }

    @MainActor
    func testVisibilityIconDescribesTheNextAction() async throws {
        let suite = "ClickerTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let engine = ClickEngine(defaults: defaults)
        XCTAssertTrue(engine.targetsVisible)
        XCTAssertEqual(engine.visibilitySymbol, "eye.slash")
        engine.targetsVisible = false
        XCTAssertEqual(engine.visibilitySymbol, "eye")
    }

}
