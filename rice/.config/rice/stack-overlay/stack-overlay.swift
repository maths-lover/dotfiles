// stack-overlay — tabs drawn on top of a yabai stack.
//
// A yabai stack puts several windows in one frame; only the top one is on
// screen and nothing shows that others hide behind it (with SIP on, yabai
// cannot draw, and JankyBorders only colours the focused border). This
// program keeps one transparent, click-through panel per visible stack,
// floating above the windows, and draws a tab strip in the top-right corner
// of the frame: one tab per window (app icon + name), the window on top in
// the theme's accent colour. Colours come from ~/.local/state/rice/palette.sh.
//
// It re-reads `yabai -m query --windows` when it receives SIGUSR1 (sent by
// yabai signals from yabairc: `pkill -USR1 -x stack-overlay`) and every two
// seconds as a safety net. Started from sketchybarrc, so `sketchybar --reload`
// (which `rice.sh apply` does on every theme change) restarts it with the new
// palette. Built by `rice.sh install` with swiftc into ~/.local/state/rice/bin.
import AppKit

// --- palette -------------------------------------------------------------------
func argb(_ s: String) -> NSColor? {
    var hex = s.trimmingCharacters(in: CharacterSet(charactersIn: "\"' "))
    if hex.hasPrefix("0x") { hex.removeFirst(2) }
    guard hex.count == 8, let v = UInt32(hex, radix: 16) else { return nil }
    return NSColor(srgbRed: CGFloat((v >> 16) & 0xff) / 255, green: CGFloat((v >> 8) & 0xff) / 255,
                   blue: CGFloat(v & 0xff) / 255, alpha: CGFloat((v >> 24) & 0xff) / 255)
}
struct Palette {
    var accent = NSColor(srgbRed: 0.48, green: 0.64, blue: 0.97, alpha: 1)
    var bg = NSColor(srgbRed: 0.10, green: 0.11, blue: 0.15, alpha: 1)
    var bgAlt = NSColor(srgbRed: 0.18, green: 0.19, blue: 0.25, alpha: 1)
    var fg = NSColor.white
    var fgDim = NSColor(white: 0.6, alpha: 1)
    var border = NSColor(white: 0.3, alpha: 1)
    static func load() -> Palette {
        var p = Palette()
        let path = NSString(string: "~/.local/state/rice/palette.sh").expandingTildeInPath
        guard let text = try? String(contentsOfFile: path, encoding: .utf8) else { return p }
        for line in text.split(separator: "\n") {
            let parts = line.split(separator: "=", maxSplits: 1).map(String.init)
            guard parts.count == 2, let c = argb(parts[1]) else { continue }
            switch parts[0] {
            case "RICE_ACCENT_0X": p.accent = c
            case "RICE_BG_0X": p.bg = c
            case "RICE_BG_ALT2_0X": p.bgAlt = c
            case "RICE_FG_0X": p.fg = c
            case "RICE_FG_DIM_0X": p.fgDim = c
            case "RICE_BORDER_0X": p.border = c
            default: break
            }
        }
        return p
    }
}
let palette = Palette.load()
let font = NSFont(name: "Maple Mono NF", size: 11.5) ?? NSFont.systemFont(ofSize: 11.5, weight: .medium)

// --- yabai -----------------------------------------------------------------------
struct Frame: Decodable, Hashable { let x: Double; let y: Double; let w: Double; let h: Double }
struct Win: Decodable {
    let id: Int; let pid: Int32; let app: String; let frame: Frame; let space: Int
    let stackIndex: Int; let isVisible: Bool; let hasFocus: Bool
    enum CodingKeys: String, CodingKey {
        case id, pid, app, frame, space
        case stackIndex = "stack-index", isVisible = "is-visible", hasFocus = "has-focus"
    }
}
let yabaiPath: String = {
    for p in ["/opt/homebrew/bin/yabai", "/usr/local/bin/yabai", "/run/current-system/sw/bin/yabai"]
    where FileManager.default.isExecutableFile(atPath: p) { return p }
    return "yabai"
}()
func queryWindows() -> [Win] {
    let proc = Process()
    proc.executableURL = URL(fileURLWithPath: yabaiPath)
    proc.arguments = ["-m", "query", "--windows"]
    let pipe = Pipe()
    proc.standardOutput = pipe
    proc.standardError = FileHandle.nullDevice
    do { try proc.run() } catch { return [] }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    proc.waitUntilExit()
    return (try? JSONDecoder().decode([Win].self, from: data)) ?? []
}

// --- drawing -----------------------------------------------------------------------
struct Tab { let name: String; let icon: NSImage?; let current: Bool }
let stripH: CGFloat = 26, tabH: CGFloat = 20, pad: CGFloat = 3, gap: CGFloat = 3
let iconS: CGFloat = 14, maxText: CGFloat = 110

final class StripView: NSView {
    var tabs: [Tab] = [] { didSet { needsDisplay = true } }
    var focused = false
    override var isFlipped: Bool { true }
    static func textWidth(_ s: String) -> CGFloat {
        min(maxText, ceil((s as NSString).size(withAttributes: [.font: font]).width))
    }
    static func tabWidth(_ t: Tab) -> CGFloat { 6 + iconS + 5 + textWidth(t.name) + 7 }
    static func width(_ tabs: [Tab]) -> CGFloat {
        tabs.reduce(0) { $0 + tabWidth($1) } + CGFloat(max(0, tabs.count - 1)) * gap + 2 * pad
    }
    override func draw(_ dirtyRect: NSRect) {
        let outer = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: 7, yRadius: 7)
        palette.bg.withAlphaComponent(0.94).setFill(); outer.fill()
        (focused ? palette.accent : palette.border).withAlphaComponent(focused ? 0.8 : 1).setStroke()
        outer.lineWidth = 1; outer.stroke()
        var x = pad
        let para = NSMutableParagraphStyle(); para.lineBreakMode = .byTruncatingTail
        for t in tabs {
            let w = StripView.tabWidth(t)
            let r = NSRect(x: x, y: pad, width: w, height: tabH)
            let path = NSBezierPath(roundedRect: r, xRadius: 5, yRadius: 5)
            (t.current ? palette.accent : palette.bgAlt).setFill(); path.fill()
            if let icon = t.icon {
                let ir = NSRect(x: r.minX + 6, y: r.midY - iconS / 2, width: iconS, height: iconS)
                icon.draw(in: ir, from: .zero, operation: .sourceOver, fraction: t.current ? 1 : 0.75,
                          respectFlipped: true, hints: nil)
            }
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font, .paragraphStyle: para,
                .foregroundColor: t.current ? palette.bg : palette.fgDim]
            let tr = NSRect(x: r.minX + 6 + iconS + 5, y: r.minY + 2, width: StripView.textWidth(t.name), height: tabH - 3)
            (t.name as NSString).draw(with: tr, options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine], attributes: attrs)
            x += w + gap
        }
    }
}

final class StripPanel: NSPanel {
    let strip = StripView()
    init() {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 10, height: stripH),
                   styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isOpaque = false; backgroundColor = .clear; hasShadow = false
        ignoresMouseEvents = true; hidesOnDeactivate = false; isReleasedWhenClosed = false
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        contentView = strip
    }
}

// --- state ---------------------------------------------------------------------------
var panels: [String: StripPanel] = [:]
var iconCache: [Int32: NSImage?] = [:]
func icon(for pid: Int32) -> NSImage? {
    if let c = iconCache[pid] { return c }
    let i = NSRunningApplication(processIdentifier: pid)?.icon
    iconCache[pid] = i
    return i
}

// Front-to-back order of the windows on screen, from the window server.
// yabai marks every member of a stack on a visible Space as visible, so this
// is what tells the window on top from the ones behind it.
func zOrder() -> [Int: Int] {
    guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]]
    else { return [:] }
    var z: [Int: Int] = [:]
    for (i, w) in list.enumerated() {
        if let n = w[kCGWindowNumber as String] as? Int, z[n] == nil { z[n] = i }
    }
    return z
}

func refresh() {
    let wins = queryWindows()
    let z = zOrder()
    // A stack = windows on one Space that share a frame and carry a stack index.
    var groups: [String: [Win]] = [:]
    for w in wins where w.stackIndex > 0 {
        groups["\(w.space)|\(w.frame.x)|\(w.frame.y)|\(w.frame.w)|\(w.frame.h)", default: []].append(w)
    }
    let primaryH = NSScreen.screens.first?.frame.height ?? 0
    var seen = Set<String>()
    for (key, members) in groups {
        let sorted = members.sorted { $0.stackIndex < $1.stackIndex }
        // Only stacks on a visible Space, with the top window actually on screen.
        guard sorted.count >= 2, sorted.contains(where: { $0.isVisible }) else { continue }
        seen.insert(key)
        // On top = frontmost on screen; else the focused one; else the stack's first.
        let top = sorted.min { (z[$0.id] ?? .max) < (z[$1.id] ?? .max) }
        let topId = (z[top?.id ?? -1] != nil ? top?.id : nil)
            ?? sorted.first { $0.hasFocus }?.id ?? sorted[0].id
        let tabs = sorted.map { Tab(name: $0.app, icon: icon(for: $0.pid), current: $0.id == topId) }
        let panel = panels[key] ?? { let p = StripPanel(); panels[key] = p; return p }()
        panel.strip.focused = sorted.contains { $0.hasFocus }
        panel.strip.tabs = tabs
        let f = sorted[0].frame
        let w = min(StripView.width(tabs), CGFloat(f.w) - 20)
        // yabai frames use CoreGraphics coordinates (origin top-left of the main
        // display); AppKit's origin is that display's bottom-left.
        let xCG = CGFloat(f.x + f.w) - w - 10, yCG = CGFloat(f.y) + 8
        panel.setFrame(NSRect(x: xCG, y: primaryH - yCG - stripH, width: w, height: stripH), display: true)
        panel.orderFrontRegardless()
    }
    for (key, panel) in panels where !seen.contains(key) {
        panel.orderOut(nil); panels.removeValue(forKey: key)
    }
}

var pending: DispatchWorkItem?
func scheduleRefresh() {
    pending?.cancel()
    let item = DispatchWorkItem { refresh() }
    pending = item
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.08, execute: item)
}

signal(SIGUSR1, SIG_IGN)
let sigSource = DispatchSource.makeSignalSource(signal: SIGUSR1, queue: .main)
sigSource.setEventHandler { scheduleRefresh() }
sigSource.resume()
let timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in refresh() }
RunLoop.main.add(timer, forMode: .common)

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
refresh()
app.run()
