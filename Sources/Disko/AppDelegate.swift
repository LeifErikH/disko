import AppKit
import Combine
import SwiftUI

final class NotchPanel: NSPanel {
    init() {
        super.init(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .statusBar
        isFloatingPanel = true
        hidesOnDeactivate = false
        ignoresMouseEvents = true
        acceptsMouseMovedEvents = true
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
    }

    override var canBecomeKey: Bool { false }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = Store()
    private let panel = NotchPanel()
    private var settings: NSWindow?
    private var monitors: [Any] = []
    private var collapse: DispatchWorkItem?
    private var edgeChange: AnyCancellable?

    private var placement: Placement { Placement(edge: store.edge) }

    func applicationDidFinishLaunching(_ notification: Notification) {
        store.openSettings = { [weak self] in self?.showSettings() }
        panel.contentView = NSHostingView(rootView: NotchView(store: store))
        place()
        panel.orderFrontRegardless()
        watchPointer()
        store.start()

        edgeChange = store.$edge.dropFirst().receive(on: RunLoop.main).sink { [weak self] _ in
            self?.store.isExpanded = false
            self?.store.focus = nil
            self?.place()
        }
        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification,
                                               object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.place() }
        }
    }

    private func place() {
        guard let screen = NSScreen.screens.first else { return }
        panel.setFrame(placement.windowFrame(on: screen.frame), display: true)
    }

    private func showSettings() {
        store.isExpanded = false
        store.focus = nil
        if settings == nil {
            let window = NSWindow(contentViewController: NSHostingController(rootView: SettingsView(store: store)))
            window.title = "Disko Settings"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.center()
            settings = window
        }
        NSApp.activate(ignoringOtherApps: true)
        settings?.makeKeyAndOrderFront(nil)
    }

    private func watchPointer() {
        monitors.append(NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged]) { [weak self] _ in
            MainActor.assumeIsolated { self?.pointerMoved() }
        } as Any)
        monitors.append(NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged]) { [weak self] event in
            MainActor.assumeIsolated { self?.pointerMoved() }
            return event
        } as Any)
    }

    private func pointerMoved() {
        let inside = isHot(NSEvent.mouseLocation)
        panel.ignoresMouseEvents = !inside

        if inside {
            collapse?.cancel()
            collapse = nil
            if !store.isExpanded { store.isExpanded = true }
        } else if store.isExpanded, collapse == nil {
            let work = DispatchWorkItem { [weak self] in
                guard let self else { return }
                self.collapse = nil
                guard !self.isHot(NSEvent.mouseLocation) else { return }
                self.store.isExpanded = false
                self.store.focus = nil
            }
            collapse = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
        }
    }

    private func isHot(_ point: CGPoint) -> Bool {
        hotRegions.contains { $0.contains(point) }
    }

    private var hotRegions: [CGRect] {
        let placement = placement
        let middle = placement.notchLength / 2

        guard store.isExpanded else {
            let pill = placement.rect(along: (middle - Layout.pillLength)...(middle + Layout.pillLength),
                                      across: 0...Layout.pillHotZone)
            let edge = placement.rect(along: Layout.curl...(placement.notchLength - Layout.curl),
                                      across: 0...Layout.edgeHotZone)
            return [pill, edge].map(onScreen)
        }

        let notch = placement.rect(along: 0...placement.notchLength, across: 0...placement.depth)
        let orb = CGRect(origin: placement.orbCenter, size: .zero).insetBy(dx: -Placement.orbReach, dy: -Placement.orbReach)
        let card = store.cardFrame == .zero ? notch : store.cardFrame
        return [notch.union(orb).union(card)].map(onScreen)
    }

    private func onScreen(_ rect: CGRect) -> CGRect {
        let window = panel.frame
        return CGRect(x: window.minX + rect.minX, y: window.maxY - rect.maxY, width: rect.width, height: rect.height)
    }
}
