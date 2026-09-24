import Foundation

struct Find: Identifiable {
    let agent: Agent
    let kind: Kind
    let path: URL?
    let label: String
    var bytes: Int64 = 0

    var id: String { "\(agent.rawValue):\(kind.rawValue):\(label)" }

    init(agent: Agent, kind: Kind, path: URL) {
        self.agent = agent
        self.kind = kind
        self.path = path
        self.label = path.abbreviated
    }

    init(agent: Agent, kind: Kind, label: String, bytes: Int64) {
        self.agent = agent
        self.kind = kind
        self.path = nil
        self.label = label
        self.bytes = bytes
    }
}

extension URL {
    var abbreviated: String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path(percentEncoded: false)
        let path = path(percentEncoded: false).trimmingSuffix("/")
        return path.hasPrefix(home) ? "~/" + path.dropFirst(home.count) : path
    }

    var canonical: URL {
        resolvingSymlinksInPath().standardizedFileURL
    }

    var canonicalPath: String {
        canonical.path(percentEncoded: false).trimmingSuffix("/")
    }

    var exists: Bool {
        FileManager.default.fileExists(atPath: path(percentEncoded: false))
    }

    var children: [URL] {
        (try? FileManager.default.contentsOfDirectory(at: self, includingPropertiesForKeys: nil)) ?? []
    }

    var isWorktree: Bool {
        var isDirectory: ObjCBool = false
        let git = appending(path: ".git").path(percentEncoded: false)
        return FileManager.default.fileExists(atPath: git, isDirectory: &isDirectory) && !isDirectory.boolValue
    }
}

extension String {
    func trimmingSuffix(_ suffix: String) -> String {
        hasSuffix(suffix) ? String(dropLast(suffix.count)) : self
    }
}
