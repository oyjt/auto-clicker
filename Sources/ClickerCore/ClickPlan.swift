import Foundation

public enum ClickKind: String, Codable, CaseIterable {
    case left = "左键单击", right = "右键单击", double = "左键双击"
}

public struct ClickPoint: Identifiable, Codable, Equatable {
    public var id = UUID()
    public var x: Double
    public var y: Double
    public var delay = 50.0
    public var hold = 10.0
    public var repetitions = 1
    public var radius = 0.0
    public var randomDelay = 0.0
    public var kind: ClickKind = .left

    public init(x: Double, y: Double) { self.x = x; self.y = y }

    public var isValid: Bool {
        [x, y, delay, hold, radius, randomDelay].allSatisfy(\.isFinite)
        && abs(x) <= 1_000_000 && abs(y) <= 1_000_000
        && delay >= 1 && delay <= 3_600_000 && hold >= 1 && hold <= 60_000
        && repetitions >= 1 && repetitions <= 100_000
        && radius >= 0 && radius <= 500 && randomDelay >= 0 && randomDelay <= 60_000
    }

    public func waitingTime(randomUnit: Double) -> Double {
        max(1, delay + min(1, max(-1, randomUnit)) * randomDelay) / 1000
    }

    public func location(angle: Double, unitRadius: Double) -> CGPoint {
        let distance = sqrt(min(1, max(0, unitRadius))) * radius
        return CGPoint(x: x + cos(angle) * distance, y: y + sin(angle) * distance)
    }
}

public struct ClickPlan: Codable, Equatable {
    public var points: [ClickPoint] = []
    public var cycles = 0
    public var defaultDelay = 50.0
    public var defaultHold = 10.0
    public var defaultRadius = 0.0
    public init() {}

    public var isValid: Bool {
        !points.isEmpty && points.count <= 50 && points.allSatisfy(\.isValid)
        && cycles >= 0 && cycles <= 1_000_000
        && defaultDelay.isFinite && (1...3_600_000).contains(defaultDelay)
        && defaultHold.isFinite && (1...60_000).contains(defaultHold)
        && defaultRadius.isFinite && (0...500).contains(defaultRadius)
        && Set(points.map(\.id)).count == points.count
    }
}
