import Foundation

struct Worktrees {
    private let claudeProjects = Set(URL.home(".claude/projects").children.map(\.lastPathComponent))
    private let cursorProjects = Set(URL.home(".cursor/projects").children.map(\.lastPathComponent))
    private let grokProjects = Set(URL.home(".grok/projects").children.map(\.lastPathComponent))
    private let codexProjects = Set(Worktrees.codexRepos)

    func discover() -> [Find] {
        let repos = Set(Self.claudeRepos + Self.codexRepos + Self.cursorRepos + Self.grokWorktreeRepos)
        let commonDirs = Set(repos.compactMap(Self.commonGitDir))
        let worktrees = Array(Set(commonDirs.flatMap(Self.worktrees)))

        var owners = [Agent?](repeating: nil, count: worktrees.count)
        let lock = NSLock()
        DispatchQueue.concurrentPerform(iterations: worktrees.count) { index in
            let agent = owner(of: worktrees[index])
            lock.withLock { owners[index] = agent }
        }
        return zip(worktrees, owners).compactMap { worktree, agent in
            agent.map { Find(agent: $0, kind: .worktrees, path: worktree) }
        }
    }

    private func owner(of worktree: URL) -> Agent? {
        let path = worktree.path(percentEncoded: false)
        let name = worktree.lastPathComponent.lowercased()

        if path.contains("/.claude/") || name.contains("claude") { return .claude }
        if path.contains("/.cursor/") { return .cursor }
        if path.contains("/.codex/") { return .codex }
        if path.contains("/.grok/") { return .grok }

        let dashed = path.replacing(/[^A-Za-z0-9]/, with: "-")
        if claudeProjects.contains(dashed) { return .claude }
        if cursorProjects.contains(String(dashed.dropFirst())) { return .cursor }
        if codexProjects.contains(path) { return .codex }
        if grokProjects.contains(String(path.dropFirst()).replacing("/", with: "-")) { return .grok }
        return Self.coauthor(of: worktree)
    }

    private static func coauthor(of worktree: URL) -> Agent? {
        let path = worktree.path(percentEncoded: false)
        guard let base = defaultBranch(of: path) else { return nil }
        let credits = Shell.run("/usr/bin/git", ["-C", path, "log", "HEAD", "--not", base, "-200",
                                                 "--format=%(trailers:key=Co-authored-by,valueonly)%ae"], timeout: 10) ?? ""
        let votes = credits.split(separator: "\n").compactMap { line in
            Agent.allCases.first { $0.claims(String(line)) }
        }
        let tally = Dictionary(grouping: votes, by: { $0 }).mapValues(\.count)
        return tally.max { $0.value < $1.value }?.key
    }

    private static func defaultBranch(of path: String) -> String? {
        let remoteHead = Shell.run("/usr/bin/git", ["-C", path, "symbolic-ref", "--short", "refs/remotes/origin/HEAD"], timeout: 5)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let candidates = [remoteHead, "origin/main", "origin/master", "main", "master"].compactMap { $0 }.filter { !$0.isEmpty }
        return candidates.first { branch in
            Shell.run("/usr/bin/git", ["-C", path, "rev-parse", "--verify", "--quiet", branch], timeout: 5)?.isEmpty == false
        }
    }

    private static var claudeRepos: [String] {
        guard let data = try? Data(contentsOf: .home(".claude.json")),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let projects = json["projects"] as? [String: Any]
        else { return [] }
        return Array(projects.keys)
    }

    private static var codexRepos: [String] {
        guard let config = try? String(contentsOf: .home(".codex/config.toml"), encoding: .utf8) else { return [] }
        return config.matches(of: /\[projects\."([^"]+)"\]/).map { String($0.output.1) }
    }

    private static var cursorRepos: [String] {
        URL.appSupport("Cursor/User/workspaceStorage").children.compactMap { workspace in
            guard let data = try? Data(contentsOf: workspace.appending(path: "workspace.json")),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let folder = json["folder"] as? String,
                  let url = URL(string: folder), url.isFileURL
            else { return nil }
            return url.path(percentEncoded: false)
        }
    }

    private static var grokWorktreeRepos: [String] {
        URL.home(".grok/worktrees").children.flatMap(\.children).map { $0.path(percentEncoded: false) }
    }

    private static func commonGitDir(of repo: String) -> URL? {
        let git = URL(filePath: repo).appending(path: ".git")
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: git.path(percentEncoded: false), isDirectory: &isDirectory) else { return nil }
        if isDirectory.boolValue { return git.canonical }

        guard let pointer = try? String(contentsOf: git, encoding: .utf8),
              let line = pointer.split(separator: "\n").first(where: { $0.hasPrefix("gitdir:") })
        else { return nil }
        let gitdir = URL(filePath: line.dropFirst("gitdir:".count).trimmingCharacters(in: .whitespaces))
        return gitdir.deletingLastPathComponent().deletingLastPathComponent().canonical
    }

    private static func worktrees(in commonDir: URL) -> [URL] {
        commonDir.appending(path: "worktrees").children.compactMap { entry in
            guard let gitdir = try? String(contentsOf: entry.appending(path: "gitdir"), encoding: .utf8) else { return nil }
            let worktree = URL(filePath: gitdir.trimmingCharacters(in: .whitespacesAndNewlines)).deletingLastPathComponent()
            return worktree.exists ? worktree.canonical : nil
        }
    }
}
