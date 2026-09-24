import AppKit
import ServiceManagement

@MainActor
final class Store: ObservableObject {
    @Published private(set) var census: Census?
    @Published private(set) var isScanning = false
    @Published var isExpanded = false
    @Published var focus: Agent?
    @Published var cardFrame: CGRect = .zero
    @Published var edge = NotchEdge(rawValue: UserDefaults.standard.string(forKey: "edge") ?? "") ?? .right {
        didSet { UserDefaults.standard.set(edge.rawValue, forKey: "edge") }
    }
    @Published private(set) var opensAtLogin = SMAppService.mainApp.status == .enabled

    private var timer: Timer?
    var openSettings: () -> Void = {}

    init(census: Census? = nil) {
        self.census = census
    }

    func start() {
        openAtLoginOnFirstInstall()
        rescan()
        timer = Timer.scheduledTimer(withTimeInterval: 30 * 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.rescan() }
        }
    }

    func rescan() {
        guard !isScanning else { return }
        isScanning = true
        Task.detached(priority: .utility) {
            let census = Census.take()
            await MainActor.run {
                self.census = census
                self.isScanning = false
            }
        }
    }

    func toggleOpenAtLogin() {
        if opensAtLogin {
            try? SMAppService.mainApp.unregister()
        } else {
            try? SMAppService.mainApp.register()
        }
        opensAtLogin = SMAppService.mainApp.status == .enabled
    }

    private func openAtLoginOnFirstInstall() {
        let defaults = UserDefaults.standard
        guard Bundle.main.bundlePath.hasPrefix("/Applications/"), !defaults.bool(forKey: "offeredOpenAtLogin") else { return }
        defaults.set(true, forKey: "offeredOpenAtLogin")
        if !opensAtLogin { toggleOpenAtLogin() }
    }

    func footprint(of agent: Agent) -> Footprint? {
        census?.footprint(of: agent)
    }

    func share(of agent: Agent) -> Double {
        guard let census, census.total > 0, let footprint = footprint(of: agent) else { return 0 }
        return Double(footprint.bytes) / Double(census.total)
    }

    func reveal(_ slice: Footprint.Slice) {
        let paths = slice.finds.sorted { $0.bytes > $1.bytes }.compactMap(\.path)
        guard !paths.isEmpty else { return }
        NSWorkspace.shared.activateFileViewerSelecting(Array(paths.prefix(12)))
    }
}
