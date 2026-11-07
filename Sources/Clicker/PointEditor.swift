import SwiftUI
import ClickerCore

struct PointEditor: View {
    @ObservedObject var engine: ClickEngine
    @State var point: ClickPoint
    let close: () -> Void
    @State private var tab = 0
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $tab) {
                Form {
                    NumberRow(title: engine.t("点击前延迟", "Delay before click"), value: $point.delay, unit: "ms", range: 1...3_600_000)
                    NumberRow(title: engine.t("按住时长", "Hold duration"), value: $point.hold, unit: "ms", range: 1...60_000)
                    HStack {
                        Text(engine.t("重复次数", "Repetitions")); Spacer()
                        TextField("1", value: $point.repetitions, format: .number.grouping(.never)).labelsHidden().multilineTextAlignment(.trailing).frame(width: 95)
                    }
                    Text(engine.t("重复次数为 1–100,000；延迟不含按住时长。", "Repeat 1–100,000 times. Delay excludes hold duration.")).font(.caption).foregroundStyle(.secondary)
                    LabeledContent(engine.t("坐标（屏幕点）", "Position (screen points)"), value: "\(Int(point.x)), \(Int(point.y))")
                    Text(engine.t("拖动桌面上的编号靶点以调整位置。", "Drag the numbered desktop target to change its position.")).font(.caption).foregroundStyle(.secondary)
                }.formStyle(.grouped).tabItem { Text(engine.t("通用设置", "General")) }.tag(0)
                Form {
                    Picker(engine.t("点击类型", "Click type"), selection: $point.kind) {
                        ForEach(ClickKind.allCases, id: \.self) { kind in Text(engine.kindName(kind)).tag(kind) }
                    }
                    NumberRow(title: engine.t("位置随机半径", "Position radius"), value: $point.radius, unit: "pt", range: 0...500)
                    Text(engine.t("以靶心为中心，在圆形范围内随机点击。0 为精确位置。", "Randomize within a circle around the target. 0 clicks the exact position.")).font(.caption).foregroundStyle(.secondary)
                    NumberRow(title: engine.t("随机延迟 ±", "Random delay ±"), value: $point.randomDelay, unit: "ms", range: 0...60_000)
                    Text(engine.t("在点击前延迟上随机加减此值，最短为 1 ms。", "Added to or subtracted from the delay, with a minimum of 1 ms.")).font(.caption).foregroundStyle(.secondary)
                    Button(engine.t("删除此位置", "Delete this target"), role: .destructive) { engine.deletePoint(point.id); close() }
                        .disabled(engine.plan.points.count <= 1 || engine.running)
                }.formStyle(.grouped).tabItem { Text(engine.t("高级设置", "Advanced")) }.tag(1)
            }.padding(16).disabled(engine.running)
            Divider()
            HStack {
                if !point.isValid { Text(engine.t("请检查数值范围", "Check the value ranges")).font(.caption).foregroundStyle(.red) }
                Spacer()
                Button(engine.t("取消", "Cancel")) { close() }.keyboardShortcut(.cancelAction)
                Button(engine.t("保存", "Save")) { engine.updatePoint(point); close() }
                    .keyboardShortcut(.defaultAction).buttonStyle(.borderedProminent).disabled(!point.isValid || engine.running)
            }.padding(16)
        }.frame(width: 440, height: 440).tint(ClickerTheme.accent)
    }
}
