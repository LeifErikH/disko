import Foundation

struct Census {
    let finds: [Find]
    let takenAt: Date

    static func take() -> Census {
        let measured = measure(distinct(nestedFinds + spotFinds + bundledFinds + sweptFinds + Worktrees().discover()))
        return Census(finds: measured + Docker.finds(), takenAt: .now)
    }

    func footprint(of agent: Agent) -> Footprint {
        Footprint(agent: agent, finds: finds.filter { $0.agent == agent && $0.bytes > 0 })
    }

    var total: Int64 { finds.reduce(0) { $0 + $1.bytes } }

    private static var nestedFinds: [Find] {
        Agent.allCases.flatMap { agent in
            agent.nests.flatMap { nest in
                nest.path.children.map { Find(agent: agent, kind: nest.kind(of: $0.lastPathComponent), path: $0) }
            }
        }
    }

    private static var spotFinds: [Find] {
        Agent.allCases.flatMap { agent in
            agent.spots.filter(\.path.exists).map { Find(agent: agent, kind: $0.kind, path: $0.path) }
        }
    }

    private static var bundledFinds: [Find] {
        Agent.allCases.flatMap { agent in
            agent.bundles.flatMap(\.children)
                .filter { agent.claims($0.lastPathComponent) }
                .map { Find(agent: agent, kind: .app, path: $0) }
        }
    }

    private static var sweptFinds: [Find] {
        let nests = Set(Agent.allCases.flatMap(\.nests).map(\.path.canonicalPath))
        return sweeps.flatMap { place, kind in
            place.children.compactMap { child -> Find? in
                guard !nests.contains(child.canonicalPath),
                      let agent = Agent.allCases.first(where: { $0.claims(child.lastPathComponent) })
                else { return nil }
                return Find(agent: agent, kind: child.isWorktree ? .worktrees : kind, path: child)
            }
        }
    }

    private static var sweeps: [(URL, Kind)] {
        [
            (.home("Library/Caches"), .caches),
            (.home("Library/HTTPStorages"), .caches),
            (.home("Library/WebKit"), .caches),
            (.home("Library/Logs"), .logs),
            (.home("Library/Application Support"), .state),
            (.home("Library/Application Support/Caches"), .caches),
            (URL(filePath: "/Applications"), .app),
            (.home("Applications"), .app),
            (URL(filePath: "/private/tmp"), .temp),
            (URL(filePath: NSTemporaryDirectory()), .temp),
        ]
    }

    private static func distinct(_ finds: [Find]) -> [Find] {
        let unique = Dictionary(finds.map { ($0.path!.canonicalPath, $0) }, uniquingKeysWith: { first, _ in first })
        let paths = Array(unique.keys)
        return unique.compactMap { path, find in
            paths.contains { path.hasPrefix($0 + "/") } ? nil : find
        }
    }

    private static func measure(_ finds: [Find]) -> [Find] {
        var measured = finds
        let lock = NSLock()
        DispatchQueue.concurrentPerform(iterations: finds.count) { index in
            let bytes = size(of: finds[index].path!)
            lock.withLock { measured[index].bytes = bytes }
        }
        return measured
    }

    private static func size(of path: URL) -> Int64 {
        let output = Shell.run("/usr/bin/du", ["-skx", path.path(percentEncoded: false)]) ?? ""
        let kilobytes = output.split(separator: "\t").first.flatMap { Int64($0) } ?? 0
        return kilobytes * 1024
    }
}
