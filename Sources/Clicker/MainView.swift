import SwiftUI
import ClickerCore

struct MainView: View {
    @ObservedObject var engine: ClickEngine
    @Environment(\.openWindow) private var openWindow
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 0) {
            sidebar.frame(width: 184)
            Divider()
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        if engine.page == "settings" { settings }
                        else if engine.page == "timing" { timing }
                        else { workspace }
                    }.padding(32).frame(maxWidth: 850, alignment: .leading).frame(maxWidth: .infinity)
                }
                Divider()
                statusBar
            }.background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(minWidth: 880, minHeight: 650)
        .tint(ClickerTheme.accent)
        .onAppear { engine.applyAppearance(); engine.openMain = { openWindow(id: "main") } }
        .alert(engine.t("需要留意", "Attention"), isPresented: Binding(get: { engine.message != nil }, set: { if !$0 { engine.message = nil } })) {
            if !engine.trusted { Button(engine.t("打开系统设置", "Open System Settings")) { engine.requestPermission() } }
            Button(engine.t("好", "OK"), role: .cancel) { engine.message = nil }
        } message: { Text(engine.message ?? "") }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 10) {
                Image(nsImage: NSApp.applicationIconImage).resizable().frame(width: 38, height: 38)
                VStack(alignment: .leading, spacing: 3) {
                    Text(engine.appName).font(.system(size: 13, weight: .semibold))
                    Text(engine.t("桌面点击助手", "Desktop companion")).font(.system(size: 10)).foregroundStyle(.secondary)
                }
            }.padding(.horizontal, 16).padding(.top, 25)
            VStack(spacing: 4) {
                navigation("workspace", "scope", engine.t("点击工作台", "Workspace"))
                navigation("timing", "timer", engine.t("点击参数", "Click settings"))
                navigation("settings", "gearshape", engine.t("应用设置", "App settings"))
            }.padding(.horizontal, 10)
            Spacer()
            VStack(alignment: .leading, spacing: 9) {
                Label(engine.t("键盘优先", "Stay in control"), systemImage: "keyboard").font(.system(size: 11, weight: .medium))
                Text("⌃ ⌥ Space").font(.system(size: 12, weight: .medium, design: .monospaced))
                Text(engine.t("开始 / 暂停 / 继续", "Start / pause / resume"))
                    .font(.system(size: 10)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }.padding(16)
        }
        .background(.regularMaterial)
    }

    private func navigation(_ page: String, _ symbol: String, _ label: String) -> some View {
        Button { engine.page = page } label: {
            Label(label, systemImage: symbol).font(.system(size: 13, weight: engine.page == page ? .medium : .regular))
                .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 12).padding(.vertical, 10)
                .foregroundStyle(engine.page == page ? ClickerTheme.accent : Color.primary)
                .background(engine.page == page ? ClickerTheme.green.opacity(0.12) : Color.clear, in: RoundedRectangle(cornerRadius: 7))
                .contentShape(Rectangle())
        }.buttonStyle(.plain)
    }

    private func heading(_ title: String, _ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.system(size: 24, weight: .semibold))
            Text(subtitle).font(.system(size: 13)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
    }

    private var workspace: some View {
        VStack(alignment: .leading, spacing: 26) {
            HStack(alignment: .top) {
                heading(engine.t("点击控制", "Click control"), engine.t("在桌面摆好位置，用键盘轻松接管。", "Place targets on your desktop. Stay in control with your keyboard."))
                Spacer()
                Button { engine.setEnabled(!engine.enabled) } label: {
                    Label(engine.enabled
                        ? (engine.running || engine.paused ? engine.t("关闭并重置", "Close & reset") : engine.t("关闭操作栏", "Close controls"))
                        : engine.t("显示操作栏", "Show controls"), systemImage: engine.enabled ? "rectangle.compress.vertical" : "rectangle.expand.vertical")
                }.controlSize(.large)
                    .help(engine.enabled ? engine.t("停止并关闭悬浮控制，清除当前进度。", "Stop, close floating controls and reset progress.") : engine.t("在桌面显示操作栏和点击位置。", "Show floating controls and click targets on the desktop."))
            }
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 16) {
                    Image(systemName: engine.paused ? "pause.circle" : "cursorarrow.click")
                        .font(.system(size: 34, weight: .light)).foregroundStyle(engine.paused ? Color.orange : ClickerTheme.accent)
                        .frame(width: 44)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(engine.statusTitle).font(.system(size: 18, weight: .semibold))
                        Text(engine.paused
                            ? engine.t("进度已保留，准备好后继续。", "Your progress is saved. Resume when you are ready.")
                            : engine.t("按编号顺序点击，隐藏标记也不影响执行。", "Click in numbered order, even with targets hidden."))
                            .font(.system(size: 12)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                }
                HStack(spacing: 12) {
                    Button { engine.toggleRunning() } label: {
                        Label(engine.runActionTitle, systemImage: engine.runSymbol).frame(minWidth: 86)
                    }.buttonStyle(.borderedProminent).tint(ClickerTheme.green).foregroundStyle(ClickerTheme.onGreen).controlSize(.large)
                    Button { engine.stop() } label: { Label(engine.t("停止并重置", "Stop & reset"), systemImage: "stop") }
                        .controlSize(.large).disabled(!engine.running && !engine.paused)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(engine.t("\(engine.plan.points.count) 个位置", engine.plan.points.count == 1 ? "1 target" : "\(engine.plan.points.count) targets"))
                        Text(engine.plan.cycles == 0 ? engine.t("持续循环", "Repeat until stopped") : engine.t("循环 \(engine.plan.cycles) 次", "\(engine.plan.cycles) cycles"))
                            .foregroundStyle(.secondary)
                    }.font(.system(size: 11)).monospacedDigit()
                }
            }.padding(22).background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 14))

            if !engine.trusted {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "hand.raised").foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(engine.t("首次使用，请允许辅助功能", "Allow Accessibility to get started")).font(.system(size: 12, weight: .medium))
                        Text(engine.t("用于发送鼠标点击，不需要录制屏幕。", "Used to send mouse clicks. No screen recording required."))
                            .font(.system(size: 11)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    Button(engine.t("去授权", "Grant access")) { engine.requestPermission() }.controlSize(.small)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(engine.t("点击位置", "Click targets")).font(.system(size: 14, weight: .semibold))
                    Spacer()
                    Button { engine.addPoint() } label: { Label(engine.t("添加位置", "Add target"), systemImage: "plus") }
                        .disabled(engine.running || engine.plan.points.count >= 50)
                }
                VStack(spacing: 0) {
                    ForEach(Array(engine.plan.points.enumerated()), id: \.element.id) { index, point in
                        if index > 0 { Divider().padding(.leading, 64) }
                        targetRow(point, number: index + 1)
                    }
                }.background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
                Text(engine.t("拖动靶点定位 · 长按、双击或右键编辑参数", "Drag targets to move · Hold, double-click or right-click to edit"))
                    .font(.system(size: 11)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }

            Divider()
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "keyboard").font(.system(size: 15)).foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 6) {
                    Text(engine.t("暂停，不必追着鼠标跑。", "Pause without chasing the pointer.")).font(.system(size: 12, weight: .medium))
                    Text(engine.t("⌃ ⌥ Space 暂停 / 继续；运行时 Esc 停止。右键操作栏可停止重置或恢复位置。", "⌃ ⌥ Space pauses / resumes. Esc stops while running. Right-click the toolbar to reset the run or its position."))
                        .font(.system(size: 11)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func targetRow(_ point: ClickPoint, number: Int) -> some View {
        HStack(spacing: 14) {
            Text("\(number)").font(.system(size: 15, weight: .medium, design: .rounded))
                .frame(width: 32, height: 32)
                .foregroundStyle(ClickerTheme.accent)
                .background(ClickerTheme.green.opacity(engine.running ? 0.20 : 0.09), in: Circle())
            VStack(alignment: .leading, spacing: 5) {
                Text(engine.t("点击位置", "Target") + " \(number)").font(.system(size: 13, weight: .medium))
                Text(engine.kindName(point.kind) + " · \(Int(point.delay)) ms · " + engine.t("重复 \(point.repetitions) 次", "Repeat \(point.repetitions)×"))
                    .font(.system(size: 11)).foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(Int(point.x)), \(Int(point.y))").font(.system(size: 11, design: .monospaced)).foregroundStyle(.secondary).monospacedDigit()
            Button { engine.overlays?.edit(point.id) } label: { Image(systemName: "slider.horizontal.3").frame(width: 25, height: 25) }
                .buttonStyle(.borderless).help(engine.t("编辑参数", "Edit target")).accessibilityLabel(engine.t("编辑位置", "Edit target") + " \(number)")
                .disabled(engine.running)
            Button { engine.deletePoint(point.id) } label: { Image(systemName: "minus.circle").frame(width: 25, height: 25) }
                .buttonStyle(.borderless).foregroundStyle(.secondary).help(engine.t("删除位置", "Remove target"))
                .accessibilityLabel(engine.t("删除位置", "Remove target") + " \(number)").disabled(engine.running || engine.plan.points.count == 1)
        }.padding(.horizontal, 16).padding(.vertical, 14)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: engine.running)
    }

    private var timing: some View {
        VStack(alignment: .leading, spacing: 24) {
            heading(engine.t("点击参数", "Click settings"), engine.t("默认参数用于新位置，也可以一键应用到所有位置。", "Defaults apply to new targets, or to all targets with one click."))
            Form {
                Section(engine.t("默认点击参数", "Default click settings")) {
                    NumberRow(title: engine.t("点击前延迟", "Delay before click"), value: $engine.plan.defaultDelay, unit: "ms", range: 1...3_600_000)
                    NumberRow(title: engine.t("按住时长", "Hold duration"), value: $engine.plan.defaultHold, unit: "ms", range: 1...60_000)
                    NumberRow(title: engine.t("位置随机半径", "Random position radius"), value: $engine.plan.defaultRadius, unit: "pt", range: 0...500)
                }
                Section(engine.t("循环执行", "Repeat sequence")) {
                    HStack {
                        Text(engine.t("循环次数", "Number of cycles")); Spacer()
                        TextField("0", value: $engine.plan.cycles, format: .number.grouping(.never)).labelsHidden().multilineTextAlignment(.trailing).frame(width: 90)
                    }
                    Text(engine.t("0 表示持续循环，直到手动停止。每轮按编号执行全部位置。", "0 repeats until stopped. Each cycle runs every target in numbered order.")).font(.caption).foregroundStyle(.secondary)
                }
                Section(engine.t("快捷预设", "Quick presets")) {
                    HStack {
                        ForEach([50.0, 100, 1000, 2000], id: \.self) { delay in
                            Button("\(Int(delay)) ms") { engine.plan.defaultDelay = delay }
                        }
                    }
                    Text(engine.t("延迟不含按住时长；系统调度和目标应用会影响实际速度。", "Delay excludes hold duration. Actual speed depends on macOS and the target app.")).font(.caption).foregroundStyle(.secondary)
                }
            }.formStyle(.grouped).scrollDisabled(true).frame(height: 570).disabled(engine.running)
            HStack {
                Spacer()
                Button(engine.t("应用到所有位置", "Apply to all targets")) {
                    for index in engine.plan.points.indices {
                        engine.plan.points[index].delay = engine.plan.defaultDelay
                        engine.plan.points[index].hold = engine.plan.defaultHold
                        engine.plan.points[index].radius = engine.plan.defaultRadius
                    }
                    engine.save()
                }.disabled(engine.running || !engine.plan.isValid)
                Button(engine.t("保存参数", "Save settings")) { engine.save() }.buttonStyle(.borderedProminent).disabled(engine.running || !engine.plan.isValid)
            }
        }
    }

    private var settings: some View {
        VStack(alignment: .leading, spacing: 24) {
            heading(engine.t("应用设置", "App settings"), engine.t("外观与语言随你，也可以交给系统。", "Choose your appearance and language, or follow your Mac."))
            Form {
                Section(engine.t("个性化", "Personalization")) {
                    Picker(engine.t("外观", "Appearance"), selection: $engine.appearance) {
                        Text(engine.t("跟随系统", "System")).tag(AppearanceMode.system)
                        Text(engine.t("浅色", "Light")).tag(AppearanceMode.light)
                        Text(engine.t("深色", "Dark")).tag(AppearanceMode.dark)
                    }.pickerStyle(.segmented)
                    Picker(engine.t("语言", "Language"), selection: $engine.language) {
                        Text(engine.t("跟随系统", "System default")).tag(AppLanguage.system)
                        Text("简体中文").tag(AppLanguage.zh)
                        Text("English").tag(AppLanguage.en)
                    }
                    Text(engine.t("更改即时生效，无需重启应用。", "Changes apply immediately. No restart needed.")).font(.caption).foregroundStyle(.secondary)
                }
                Section(engine.t("权限与控制", "Permissions & controls")) {
                    HStack {
                        Label(engine.t("辅助功能", "Accessibility"), systemImage: "hand.raised")
                        Spacer()
                        Text(engine.trusted ? engine.t("已授权", "Allowed") : engine.t("未授权", "Not allowed")).foregroundStyle(engine.trusted ? .green : .secondary)
                        Button(engine.t("系统设置", "System Settings")) { engine.requestPermission() }
                    }
                    LabeledContent(engine.t("开始 / 暂停 / 继续", "Start / pause / resume"), value: "⌃ ⌥ Space")
                    LabeledContent(engine.t("停止当前执行", "Stop current run"), value: "Esc " + engine.t("（运行时全局）", "(global while running)"))
                }
                Section(engine.t("关于", "About")) {
                    LabeledContent(engine.appName, value: "1.0.0")
                    Text(engine.t("一个安静、轻巧的桌面点击助手。所有配置仅保存在本机。", "A quiet, lightweight clicking companion. All settings stay on this Mac.")).font(.caption).foregroundStyle(.secondary)
                }
            }.formStyle(.grouped).scrollDisabled(true).frame(height: 520)
        }
    }

    private var statusBar: some View {
        HStack(spacing: 8) {
            Circle().fill(engine.paused ? Color.orange : (engine.running ? ClickerTheme.accent : Color.secondary.opacity(0.5))).frame(width: 6, height: 6)
            Text(engine.statusTitle)
            Spacer()
            if engine.completedClicks > 0 {
                Text(engine.t("已执行 \(engine.completedClicks) 次 · \(engine.completedCycles) 轮", "\(engine.completedClicks) clicks · \(engine.completedCycles) cycles")).monospacedDigit()
            }
            if engine.running && engine.globalEscapeAvailable { Text(engine.t("Esc 停止", "Esc to stop")) }
            if engine.enabled {
                Button { engine.toggleRunning() } label: {
                    Label(engine.runActionTitle, systemImage: engine.runSymbol)
                }.controlSize(.small).disabled(!engine.trusted && !engine.running)
            }
        }.font(.system(size: 11)).foregroundStyle(.secondary).padding(.horizontal, 24).frame(height: 44)
    }
}

struct NumberRow: View {
    let title: String
    @Binding var value: Double
    let unit: String
    let range: ClosedRange<Double>
    var body: some View {
        HStack {
            Text(title); Spacer()
            TextField("", value: $value, format: .number.grouping(.never).precision(.fractionLength(0...2)))
                .multilineTextAlignment(.trailing).frame(width: 95)
                .foregroundStyle(value.isFinite && range.contains(value) ? Color.primary : Color.red)
                .accessibilityLabel(title)
            Text(unit).foregroundStyle(.secondary).frame(width: 24, alignment: .leading)
        }
    }
}
