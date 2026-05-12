import SwiftUI
import AppKit
import Combine

// MARK: - Model

struct StickerData: Codable, Identifiable, Equatable {
    var id: UUID
    var text: String
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var height: CGFloat
}

final class Store {
    static let shared = Store()
    let url: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("StickyNotes", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("stickers.json")
    }()

    func load() -> [StickerData] {
        guard let data = try? Data(contentsOf: url),
              let items = try? JSONDecoder().decode([StickerData].self, from: data) else {
            return []
        }
        return items
    }

    func save(_ items: [StickerData]) {
        if let data = try? JSONEncoder().encode(items) {
            try? data.write(to: url, options: .atomic)
        }
    }
}

// MARK: - Shared app state (drives both dashboard and stickers)

final class AppState: ObservableObject {
    @Published var stickers: [StickerData] = []

    func upsert(_ s: StickerData) {
        if let i = stickers.firstIndex(where: { $0.id == s.id }) {
            stickers[i] = s
        } else {
            stickers.append(s)
        }
        Store.shared.save(stickers)
    }

    func remove(_ id: UUID) {
        stickers.removeAll { $0.id == id }
        Store.shared.save(stickers)
    }

    func sticker(_ id: UUID) -> StickerData? {
        stickers.first { $0.id == id }
    }
}

// MARK: - Translucent background

struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = material
        v.blendingMode = blendingMode
        v.state = .active
        v.isEmphasized = true
        return v
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Sticker view

struct StickerView: View {
    let id: UUID
    @ObservedObject var state: AppState
    let onClose: () -> Void
    let onDrag: () -> Void
    @State private var hovering = false

    private var text: Binding<String> {
        Binding(
            get: { state.sticker(id)?.text ?? "" },
            set: { new in
                guard var s = state.sticker(id) else { return }
                s.text = new
                state.upsert(s)
            }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title bar — drag handle
            ZStack {
                Color.black.opacity(0.55)
                HStack {
                    Button(action: onClose) {
                        Circle()
                            .fill(Color.white.opacity(hovering ? 1 : 0.7))
                            .frame(width: 11, height: 11)
                            .overlay(
                                Image(systemName: "xmark")
                                    .font(.system(size: 7, weight: .bold, design: .rounded))
                                    .foregroundColor(.black)
                                    .opacity(hovering ? 1 : 0)
                            )
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.horizontal, 10)
            }
            .frame(height: 24)
            .gesture(
                DragGesture(minimumDistance: 0).onChanged { _ in onDrag() }
            )

            // Body
            TextEditor(text: text)
                .font(.system(size: 14, design: .rounded))
                .scrollContentBackground(.hidden)
                .padding(10)
                .foregroundColor(.primary)
        }
        .background(VisualEffectBlur(material: .hudWindow))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)
        .overlay(alignment: .bottomTrailing) {
            Path { p in
                p.move(to: CGPoint(x: 0, y: 12))
                p.addQuadCurve(to: CGPoint(x: 12, y: 0), control: CGPoint(x: 12, y: 12))
            }
            .stroke(Color.primary.opacity(0.35), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
            .frame(width: 12, height: 12)
            .padding(6)
            .allowsHitTesting(false)
        }
        .onHover { hovering = $0 }
    }
}

// MARK: - Sticker window

final class StickerWindow: NSWindow {
    let stickerID: UUID

    init(data: StickerData, state: AppState, onClose: @escaping (UUID) -> Void) {
        self.stickerID = data.id
        super.init(
            contentRect: NSRect(x: data.x, y: data.y, width: data.width, height: data.height),
            styleMask: [.titled, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        // Hide native chrome but keep titled-window resize behavior (edge/corner
        // hit testing + system cursors). The SwiftUI body draws the visible UI.
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true

        self.isReleasedWhenClosed = false
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false // SwiftUI provides shadow
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)))
        self.collectionBehavior = [.stationary, .ignoresCycle]
        self.minSize = NSSize(width: 160, height: 140)

        let id = data.id
        let view = StickerView(
            id: id,
            state: state,
            onClose: { onClose(id) },
            onDrag: { [weak self] in
                guard let self, let event = NSApp.currentEvent else { return }
                self.performDrag(with: event)
            }
        )
        self.contentView = FirstMouseHostingView(rootView: view)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

// NSHostingView subclass that lets clicks reach the SwiftUI gestures even
// when the window is not key — so dragging a sticker by its title bar works
// on the very first mousedown instead of requiring an activation click first.
final class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

// MARK: - Dashboard

struct DashboardView: View {
    @ObservedObject var state: AppState
    let onNew: () -> Void
    let onFocus: (UUID) -> Void
    let onDelete: (UUID) -> Void
    @State private var hoveredID: UUID? = nil

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Stick")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                Spacer()
                Button(action: onNew) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                        Text("New")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule().fill(Color.accentColor)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider().background(Color.primary.opacity(0.15))

            if state.stickers.isEmpty {
                VStack {
                    Spacer()
                    Text("No notes yet.\nTap + New to add one.")
                        .multilineTextAlignment(.center)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(state.stickers.enumerated()), id: \.element.id) { idx, s in
                            StickerRow(
                                s: s,
                                onFocus: { onFocus(s.id) },
                                onDelete: { onDelete(s.id) },
                                onHover: { isHover in
                                    withAnimation(.easeInOut(duration: 0.18)) {
                                        hoveredID = isHover ? s.id : (hoveredID == s.id ? nil : hoveredID)
                                    }
                                }
                            )
                            if idx < state.stickers.count - 1 {
                                let next = state.stickers[idx + 1].id
                                let hidden = hoveredID == s.id || hoveredID == next
                                Rectangle()
                                    .fill(Color.primary.opacity(hidden ? 0 : 0.08))
                                    .frame(height: 0.5)
                                    .padding(.horizontal, 14)
                            }
                        }
                    }
                    .padding(10)
                }
            }

            Divider().background(Color.primary.opacity(0.15))

            HStack(spacing: 6) {
                Image(systemName: "folder")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Text(Store.shared.url.path)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(Store.shared.url.path)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .onTapGesture {
                NSWorkspace.shared.activateFileViewerSelecting([Store.shared.url])
            }
        }
        .background(VisualEffectBlur(material: .hudWindow))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)
        .padding(10)
    }
}

struct StickerRow: View {
    let s: StickerData
    let onFocus: () -> Void
    let onDelete: () -> Void
    var onHover: (Bool) -> Void = { _ in }
    @State private var hover = false

    private var preview: String {
        let trimmed = s.text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "(empty)" : trimmed
    }

    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(Color.primary.opacity(0.7)).frame(width: 6, height: 6)
            Text(preview)
                .lineLimit(1)
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(.primary)
            Spacer()
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 10))
                    .foregroundColor(.primary)
                    .padding(4)
            }
            .buttonStyle(.plain)
            .opacity(hover ? 1 : 0)
            .allowsHitTesting(hover)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(hover ? 0.12 : 0))
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onFocus)
        .onHover { h in
            withAnimation(.easeInOut(duration: 0.18)) { hover = h }
            onHover(h)
        }
    }
}

final class DashboardWindow: NSWindow {
    init(rootView: NSView) {
        super.init(
            contentRect: NSRect(x: 100, y: 100, width: 280, height: 360),
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )
        self.isReleasedWhenClosed = false
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)))
        self.isMovableByWindowBackground = true
        self.collectionBehavior = [.stationary, .ignoresCycle]
        self.minSize = NSSize(width: 240, height: 240)
        self.contentView = rootView
    }
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

// MARK: - App delegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    let state = AppState()
    private var stickerWindows: [UUID: StickerWindow] = [:]
    private var dashboard: DashboardWindow?
    private var statusItem: NSStatusItem!
    private var observers: [NSObjectProtocol] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        // Menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let b = statusItem.button {
            b.image = NSImage(systemSymbolName: "note.text", accessibilityDescription: "Stick")
            b.image?.isTemplate = true
        }
        let menu = NSMenu()
        let mNew = NSMenuItem(title: "New Note", action: #selector(menuNew), keyEquivalent: "n")
        mNew.target = self
        menu.addItem(mNew)
        let mDash = NSMenuItem(title: "Show / Hide Dashboard", action: #selector(toggleDashboard), keyEquivalent: "d")
        mDash.target = self
        menu.addItem(mDash)
        menu.addItem(.separator())
        let mQuit = NSMenuItem(title: "Quit Stick", action: #selector(menuQuit), keyEquivalent: "q")
        mQuit.target = self
        menu.addItem(mQuit)
        statusItem.menu = menu

        // Load
        state.stickers = Store.shared.load()
        for s in state.stickers { spawnWindow(for: s) }

        // Dashboard
        showDashboard()

        // Keep window frames in sync
        let nc = NotificationCenter.default
        observers.append(nc.addObserver(forName: NSWindow.didMoveNotification, object: nil, queue: .main) { [weak self] n in
            self?.syncFrame(n)
        })
        observers.append(nc.addObserver(forName: NSWindow.didResizeNotification, object: nil, queue: .main) { [weak self] n in
            self?.syncFrame(n)
        })
    }

    func applicationWillTerminate(_ notification: Notification) {
        Store.shared.save(state.stickers)
    }

    @objc func menuNew() { newSticker() }
    @objc func menuQuit() { NSApp.terminate(nil) }

    @objc func toggleDashboard() {
        if let d = dashboard, d.isVisible {
            d.orderOut(nil)
        } else {
            showDashboard()
        }
    }

    private func showDashboard() {
        if dashboard == nil {
            let host = NSHostingView(rootView: DashboardView(
                state: state,
                onNew: { [weak self] in self?.newSticker() },
                onFocus: { [weak self] id in self?.focusSticker(id) },
                onDelete: { [weak self] id in self?.deleteSticker(id) }
            ))
            host.frame = NSRect(x: 0, y: 0, width: 280, height: 360)
            host.autoresizingMask = [.width, .height]
            dashboard = DashboardWindow(rootView: host)
            if let screen = NSScreen.main {
                let f = screen.visibleFrame
                dashboard?.setFrameOrigin(NSPoint(x: f.maxX - 300, y: f.maxY - 380))
            }
        }
        dashboard?.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }

    func newSticker() {
        let frame = NSScreen.main?.visibleFrame ?? NSRect(x: 200, y: 200, width: 240, height: 200)
        let s = StickerData(
            id: UUID(),
            text: "",
            x: frame.midX - 120 + CGFloat.random(in: -80...80),
            y: frame.midY - 100 + CGFloat.random(in: -80...80),
            width: 240, height: 200
        )
        state.upsert(s)
        spawnWindow(for: s)
    }

    private func spawnWindow(for s: StickerData) {
        let w = StickerWindow(data: s, state: state, onClose: { [weak self] id in
            self?.closeStickerWindow(id)
        })
        stickerWindows[s.id] = w
        w.orderFrontRegardless()
    }

    private func closeStickerWindow(_ id: UUID) {
        if let w = stickerWindows.removeValue(forKey: id) {
            w.orderOut(nil)
        }
        showDashboard()
    }

    private func focusSticker(_ id: UUID) {
        if let w = stickerWindows[id] {
            w.orderFrontRegardless()
            w.makeKey()
            return
        }
        guard let s = state.sticker(id) else { return }
        spawnWindow(for: s)
        stickerWindows[id]?.makeKey()
    }

    private func deleteSticker(_ id: UUID) {
        if let w = stickerWindows.removeValue(forKey: id) {
            w.orderOut(nil)
            w.close()
        }
        state.remove(id)
    }

    private func syncFrame(_ note: Notification) {
        guard let w = note.object as? StickerWindow else { return }
        guard var s = state.sticker(w.stickerID) else { return }
        let f = w.frame
        s.x = f.origin.x; s.y = f.origin.y
        s.width = f.size.width; s.height = f.size.height
        state.upsert(s)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
