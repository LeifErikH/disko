import AppKit

if CommandLine.arguments.contains("--print") {
    Report.print(Census.take())
    exit(0)
}

if let flag = CommandLine.arguments.firstIndex(of: "--snapshot"), CommandLine.arguments.count > flag + 2 {
    let focus = Agent(rawValue: CommandLine.arguments[flag + 1]) ?? .claude
    let census = Census.take()
    let edge = CommandLine.arguments.count > flag + 3 ? NotchEdge(rawValue: CommandLine.arguments[flag + 3]) ?? .right : .right
    MainActor.assumeIsolated { Report.snapshot(census, focus: focus, edge: edge, to: CommandLine.arguments[flag + 2]) }
    exit(0)
}

MainActor.assumeIsolated {
    let delegate = AppDelegate()
    NSApplication.shared.delegate = delegate
    NSApplication.shared.setActivationPolicy(.accessory)
    NSApplication.shared.run()
}
