import AppKit

struct DeskState {
    let name: String
    let title: String
    let group: String
    let fixture: String?
    let storeMode: String
    let defaults: [String: Any]
    let evidence: [[String: Any]]
}

struct Paths {
    static let here = URL(fileURLWithPath: #filePath).deletingLastPathComponent().standardizedFileURL
    static let root = here.deletingLastPathComponent().deletingLastPathComponent()
    static let desk = root.appendingPathComponent(".build/debug/Desk")
    static let fixtures = here.appendingPathComponent(".fixtures", isDirectory: true)
    static let runs = here.appendingPathComponent(".run", isDirectory: true)
    static let catalog = here.appendingPathComponent("states.json")
    static let seed = here.appendingPathComponent("seed.sh")
}

func die(_ message: String, code: Int32 = 1) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(code)
}

func loadCatalog() -> [(group: String, states: [DeskState])] {
    guard let data = try? Data(contentsOf: Paths.catalog),
          let groups = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]] else {
        die("Cannot read \(Paths.catalog.path)")
    }
    return groups.map { group in
        let name = group["group"] as? String ?? "States"
        let states = (group["states"] as? [[String: Any]] ?? []).map { entry in
            DeskState(name: entry["name"] as? String ?? "",
                      title: entry["title"] as? String ?? "",
                      group: name,
                      fixture: entry["fixture"] as? String,
                      storeMode: entry["storeMode"] as? String ?? "copy",
                      defaults: entry["defaults"] as? [String: Any] ?? [:],
                      evidence: entry["evidence"] as? [[String: Any]] ?? [])
        }
        return (name, states)
    }
}

@discardableResult
func run(_ executable: String, _ arguments: [String], in directory: URL = Paths.root) -> Int32 {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    process.currentDirectoryURL = directory
    do { try process.run() } catch { die("Cannot run \(executable): \(error.localizedDescription)") }
    process.waitUntilExit()
    return process.terminationStatus
}

func ensureReady() {
    if !FileManager.default.isExecutableFile(atPath: Paths.desk.path) {
        print("Building Desk")
        guard run("/usr/bin/env", ["swift", "build"]) == 0 else { die("swift build failed") }
    }
    if !FileManager.default.fileExists(atPath: Paths.fixtures.appendingPathComponent("typical/store.sqlite").path) {
        print("Seeding fixtures")
        guard run("/bin/zsh", [Paths.seed.path]) == 0 else { die("seed.sh failed") }
    }
}

func cleanRuns(keeping keep: Set<URL> = []) {
    let entries = (try? FileManager.default.contentsOfDirectory(at: Paths.runs, includingPropertiesForKeys: nil)) ?? []
    for entry in entries where !keep.contains(entry.standardizedFileURL) {
        try? FileManager.default.removeItem(at: entry)
    }
}

func prepare(_ state: DeskState) -> (environment: [String: String], directory: URL) {
    let stamp = Int(Date().timeIntervalSince1970 * 1000)
    let directory = Paths.runs.appendingPathComponent("\(state.name)-\(stamp)", isDirectory: true).standardizedFileURL
    let store = directory.appendingPathComponent("store", isDirectory: true)
    let manager = FileManager.default
    do {
        try manager.createDirectory(at: store, withIntermediateDirectories: true)
        if let fixture = state.fixture {
            let source = Paths.fixtures.appendingPathComponent(fixture, isDirectory: true)
            guard manager.fileExists(atPath: source.path) else { die("Missing fixture \(fixture). Run \(Paths.seed.path).") }
            for entry in try manager.contentsOfDirectory(atPath: source.path) {
                try manager.copyItem(at: source.appendingPathComponent(entry), to: store.appendingPathComponent(entry))
            }
        }
        let database = store.appendingPathComponent("store.sqlite")
        switch state.storeMode {
        case "readonly":
            for suffix in ["-wal", "-shm"] { try? manager.removeItem(atPath: database.path + suffix) }
            try manager.setAttributes([.posixPermissions: 0o444], ofItemAtPath: database.path)
        case "readonly-journal":
            for suffix in ["-wal", "-shm"] where !manager.fileExists(atPath: database.path + suffix) {
                manager.createFile(atPath: database.path + suffix, contents: Data())
            }
            try manager.setAttributes([.posixPermissions: 0o444], ofItemAtPath: database.path)
        default:
            break
        }
        let plist = try PropertyListSerialization.data(fromPropertyList: state.defaults, format: .xml, options: 0)
        try plist.write(to: directory.appendingPathComponent("defaults.plist"))
    } catch {
        die("Cannot prepare \(state.name): \(error.localizedDescription)")
    }
    var environment = ProcessInfo.processInfo.environment
    environment["DESK_VERIFY_SCRIPT"] = nil
    environment["DESK_STORE_URL"] = store.appendingPathComponent("store.sqlite").path
    environment["DESK_DEFAULTS_SUITE"] = directory.appendingPathComponent("defaults").path
    return (environment, directory)
}

func launchDesk(_ state: DeskState) -> Process {
    let (environment, directory) = prepare(state)
    cleanRuns(keeping: [directory])
    let process = Process()
    process.executableURL = Paths.desk
    process.environment = environment
    let log = directory.appendingPathComponent("desk.log")
    FileManager.default.createFile(atPath: log.path, contents: nil)
    if let handle = try? FileHandle(forWritingTo: log) {
        process.standardOutput = handle
        process.standardError = handle
    }
    do { try process.run() } catch { die("Cannot launch Desk: \(error.localizedDescription)") }
    print("Desk state \(state.name): DESK_STORE_URL=\(environment["DESK_STORE_URL"]!) DESK_DEFAULTS_SUITE=\(environment["DESK_DEFAULTS_SUITE"]!)")
    return process
}

func stop(_ process: Process?) {
    guard let process, process.isRunning else { return }
    process.terminate()
    let deadline = Date().addingTimeInterval(2)
    while process.isRunning && Date() < deadline { usleep(20_000) }
    if process.isRunning { kill(process.processIdentifier, SIGKILL) }
}

func substitute(_ value: Any, directory: String) -> Any {
    if let text = value as? String { return text.replacingOccurrences(of: "{dir}", with: directory) }
    if let list = value as? [Any] { return list.map { substitute($0, directory: directory) } }
    if let map = value as? [String: Any] { return map.mapValues { substitute($0, directory: directory) } }
    return value
}

func snapshot(_ states: [DeskState], into output: URL) -> Bool {
    try? FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
    var passed = true
    for state in states {
        let (environment, directory) = prepare(state)
        var steps: [Any] = [["kind": "wait", "ms": 600]]
        steps += state.evidence.map { substitute($0, directory: output.path) }
        steps.append(["kind": "snapshot", "path": output.appendingPathComponent("\(state.name).png").path])
        steps.append(["kind": "dumpState", "path": output.appendingPathComponent("\(state.name).json").path])
        let script = directory.appendingPathComponent("verify.json")
        do {
            try JSONSerialization.data(withJSONObject: steps, options: [.prettyPrinted]).write(to: script)
        } catch {
            die("Cannot write \(script.path)")
        }
        var scriptEnvironment = environment
        scriptEnvironment["DESK_VERIFY_SCRIPT"] = script.path
        let process = Process()
        process.executableURL = Paths.desk
        process.environment = scriptEnvironment
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do { try process.run() } catch { die("Cannot launch Desk: \(error.localizedDescription)") }
        let deadline = Date().addingTimeInterval(90)
        while process.isRunning && Date() < deadline { usleep(50_000) }
        if process.isRunning { process.terminate(); passed = false }
        let dump = output.appendingPathComponent("\(state.name).json")
        let info = (try? Data(contentsOf: dump)).flatMap { try? JSONSerialization.jsonObject(with: $0) } as? [String: Any] ?? [:]
        let notes = (info["notes"] as? [Any])?.count ?? -1
        let saveError = info["saveError"] as? String ?? ""
        let status = process.terminationStatus == 0 && notes >= 0 ? "ok" : "FAILED"
        if status != "ok" { passed = false }
        print("\(status)  \(state.name)  state=\(info["state"] ?? "?") cards=\(notes)\(saveError.isEmpty ? "" : " saveError=\"\(saveError)\"")  \(output.appendingPathComponent("\(state.name).png").path)")
    }
    cleanRuns()
    return passed
}

final class StateRow: NSButton {
    let deskState: DeskState
    var isActive = false { didSet { needsDisplay = true; setAccessibilityValue(isActive ? "selected" : "") } }
    private var hovering = false { didSet { needsDisplay = true } }

    init(state: DeskState) {
        deskState = state
        super.init(frame: .zero)
        isBordered = false
        title = state.title
        setAccessibilityLabel(state.title)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 29).isActive = true
    }

    required init?(coder: NSCoder) { nil }

    override var acceptsFirstResponder: Bool { false }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }
        addTrackingArea(NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self))
    }

    override func mouseEntered(with event: NSEvent) { hovering = true }
    override func mouseExited(with event: NSEvent) { hovering = false }

    override func draw(_ dirtyRect: NSRect) {
        if isActive {
            NSColor(white: 1, alpha: 0.14).setFill()
            NSBezierPath(roundedRect: bounds, xRadius: 8, yRadius: 8).fill()
        }
        let alpha: CGFloat = isActive ? 1 : hovering ? 0.85 : 0.6
        let font = NSFont.systemFont(ofSize: 13, weight: isActive ? .medium : .regular)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byTruncatingTail
        let text = NSAttributedString(string: deskState.title, attributes: [
            .font: font, .foregroundColor: NSColor(white: 1, alpha: alpha), .paragraphStyle: paragraph
        ])
        let height = text.size().height
        text.draw(in: CGRect(x: 10, y: (bounds.height - height) / 2, width: bounds.width - 20, height: height))
    }
}

final class FlippedStack: NSStackView {
    override var isFlipped: Bool { true }
}

final class SwitcherPanel: NSPanel {
    var onKey: ((NSEvent) -> Bool)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func keyDown(with event: NSEvent) {
        if onKey?(event) == true { return }
        super.keyDown(with: event)
    }
}

final class Switcher: NSObject, NSApplicationDelegate {
    private let catalog = loadCatalog()
    private lazy var states = catalog.flatMap(\.states)
    private var rows: [StateRow] = []
    private var panel: SwitcherPanel!
    private var scroll: NSScrollView!
    private var current: Int
    private var desk: Process?
    private var hidden = false

    init(initial: String) {
        let names = loadCatalog().flatMap(\.states).map(\.name)
        current = names.firstIndex(of: initial) ?? 0
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        installMenu()
        buildPanel()
        select(current)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        setHidden(false)
        panel.makeKeyAndOrderFront(nil)
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        stop(desk)
        cleanRuns()
    }

    private func installMenu() {
        let menu = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit State Switcher", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        menu.addItem(appItem)
        NSApp.mainMenu = menu
    }

    private func buildPanel() {
        let list = FlippedStack()
        list.orientation = .vertical
        list.alignment = .leading
        list.spacing = 16
        list.edgeInsets = NSEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        list.translatesAutoresizingMaskIntoConstraints = false
        list.setAccessibilityLabel("States")
        for group in catalog {
            let box = NSStackView()
            box.orientation = .vertical
            box.alignment = .leading
            box.spacing = 2
            box.translatesAutoresizingMaskIntoConstraints = false
            box.setAccessibilityElement(true)
            box.setAccessibilityRole(.group)
            box.setAccessibilityLabel(group.group)
            let icon = NSImageView(image: NSImage(systemSymbolName: "arrow.turn.down.right", accessibilityDescription: nil)!)
            icon.symbolConfiguration = .init(pointSize: 9, weight: .medium)
            icon.contentTintColor = NSColor(white: 1, alpha: 0.45)
            let label = NSTextField(labelWithString: group.group)
            label.font = .systemFont(ofSize: 11, weight: .medium)
            label.textColor = NSColor(white: 1, alpha: 0.45)
            let heading = NSStackView(views: [icon, label])
            heading.spacing = 6
            heading.edgeInsets = NSEdgeInsets(top: 4, left: 10, bottom: 6, right: 10)
            box.addArrangedSubview(heading)
            for state in group.states {
                let row = StateRow(state: state)
                row.target = self
                row.action = #selector(rowClicked(_:))
                rows.append(row)
                box.addArrangedSubview(row)
                row.widthAnchor.constraint(equalTo: box.widthAnchor).isActive = true
            }
            list.addArrangedSubview(box)
            box.widthAnchor.constraint(equalTo: list.widthAnchor, constant: -12).isActive = true
        }
        let width: CGFloat = 208
        list.widthAnchor.constraint(equalToConstant: width).isActive = true
        list.layoutSubtreeIfNeeded()
        let contentHeight = list.fittingSize.height
        let screen = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
        let height = min(contentHeight, screen.height - 48)

        scroll = NSScrollView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = false
        scroll.verticalScrollElasticity = .none
        scroll.documentView = list
        list.frame = CGRect(x: 0, y: 0, width: width, height: contentHeight)

        let surface = NSView(frame: scroll.frame)
        surface.wantsLayer = true
        surface.layer?.backgroundColor = NSColor(srgbRed: 20 / 255, green: 20 / 255, blue: 20 / 255, alpha: 0.92).cgColor
        surface.layer?.cornerRadius = 14
        surface.layer?.borderWidth = 1
        surface.layer?.borderColor = NSColor(white: 1, alpha: 0.1).cgColor
        surface.layer?.masksToBounds = true
        surface.appearance = NSAppearance(named: .darkAqua)
        surface.addSubview(scroll)

        panel = SwitcherPanel(contentRect: CGRect(x: screen.minX + 24, y: screen.maxY - 24 - height, width: width, height: height),
                              styleMask: [.borderless], backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = surface
        panel.title = "States"
        panel.onKey = { [weak self] event in self?.handle(event) ?? false }
        panel.makeKeyAndOrderFront(nil)
    }

    private func handle(_ event: NSEvent) -> Bool {
        guard event.modifierFlags.intersection([.command, .control, .option]).isEmpty else { return false }
        switch event.keyCode {
        case 124, 125:
            select(min(current + 1, states.count - 1))
            return true
        case 123, 126:
            select(max(current - 1, 0))
            return true
        default:
            if event.charactersIgnoringModifiers?.lowercased() == "h" {
                setHidden(!hidden)
                return true
            }
            return false
        }
    }

    private func setHidden(_ value: Bool) {
        hidden = value
        panel.alphaValue = value ? 0 : 1
        panel.ignoresMouseEvents = value
    }

    @objc private func rowClicked(_ sender: StateRow) {
        guard let index = rows.firstIndex(where: { $0 === sender }) else { return }
        select(index)
    }

    private func select(_ index: Int) {
        let changed = index != current || desk == nil
        current = index
        for (offset, row) in rows.enumerated() { row.isActive = offset == index }
        rows[index].scrollToVisible(rows[index].bounds.insetBy(dx: 0, dy: -8))
        guard changed else { return }
        stop(desk)
        desk = launchDesk(states[index])
        for delay in [0.7, 1.4] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self, self.current == index else { return }
                NSApp.activate(ignoringOtherApps: true)
                self.panel.makeKeyAndOrderFront(nil)
            }
        }
    }
}

func usage() -> Never {
    die("""
    usage: swift states/canvas/switcher.swift [--state <name>] [--no-panel] [--snapshot <dir>] [--list]
      --state <name>    Start with this state. Without --no-panel the floating panel opens too.
      --no-panel        Launch Desk with the state and wait for Desk to quit.
      --snapshot <dir>  Render the state (or every state without --state) through the Desk driver into <dir>.
      --list            Print the states by group.
    """, code: 2)
}

var stateName: String?
var noPanel = false
var snapshotDirectory: String?
var list = false
var cursor = CommandLine.arguments.dropFirst().makeIterator()
while let argument = cursor.next() {
    switch argument {
    case "--state":
        guard let value = cursor.next() else { usage() }
        stateName = value
    case "--no-panel": noPanel = true
    case "--snapshot":
        guard let value = cursor.next() else { usage() }
        snapshotDirectory = value
    case "--list": list = true
    case "-h", "--help": usage()
    default: usage()
    }
}

let catalog = loadCatalog()
let allStates = catalog.flatMap(\.states)
if list {
    for group in catalog {
        print(group.group)
        for state in group.states { print("  \(state.name.padding(toLength: 26, withPad: " ", startingAt: 0))\(state.title)") }
    }
    exit(0)
}
if let stateName, !allStates.contains(where: { $0.name == stateName }) {
    die("Unknown state \(stateName). Use --list.", code: 2)
}
ensureReady()

if let snapshotDirectory {
    let selected = stateName.map { name in allStates.filter { $0.name == name } } ?? allStates
    let output = URL(fileURLWithPath: snapshotDirectory, isDirectory: true).standardizedFileURL
    exit(snapshot(selected, into: output) ? 0 : 1)
}

if noPanel {
    let state = allStates.first { $0.name == (stateName ?? allStates[0].name) }!
    let process = launchDesk(state)
    signal(SIGINT, SIG_IGN)
    let interrupt = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
    interrupt.setEventHandler { stop(process); cleanRuns(); exit(130) }
    interrupt.resume()
    DispatchQueue.global().async {
        process.waitUntilExit()
        DispatchQueue.main.async { cleanRuns(); exit(process.terminationStatus) }
    }
    dispatchMain()
}

let app = NSApplication.shared
let switcher = Switcher(initial: stateName ?? allStates[0].name)
app.delegate = switcher
app.setActivationPolicy(.regular)
signal(SIGINT, SIG_IGN)
let interrupt = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
interrupt.setEventHandler { NSApp.terminate(nil) }
interrupt.resume()
app.run()
