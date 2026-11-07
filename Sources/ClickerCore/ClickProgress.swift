/// Checkpoint only completed click actions; an interrupted press restarts on resume.
public struct ClickProgress: Equatable {
    public private(set) var pointIndex = 0
    public private(set) var repetitionIndex = 0
    public private(set) var completedCycles = 0
    public init() {}

    @discardableResult
    public mutating func advance(in plan: ClickPlan) -> Bool {
        precondition(plan.isValid && plan.points.indices.contains(pointIndex))
        repetitionIndex += 1
        if repetitionIndex >= plan.points[pointIndex].repetitions {
            repetitionIndex = 0
            pointIndex += 1
            if pointIndex == plan.points.count {
                pointIndex = 0
                completedCycles += 1
            }
        }
        return plan.cycles > 0 && completedCycles >= plan.cycles
    }
}
