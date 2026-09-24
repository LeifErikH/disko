import Foundation

struct Nest {
    let path: URL
    let fallback: Kind
    let rules: [(prefix: String, kind: Kind)]

    func kind(of name: String) -> Kind {
        let name = name.lowercased()
        return rules.first { name.hasPrefix($0.prefix) }?.kind ?? fallback
    }
}

struct Spot {
    let path: URL
    let kind: Kind
}

enum Agent: String, CaseIterable, Identifiable {
    case claude, cursor, codex, grok

    var id: String { rawValue }

    var title: String {
        switch self {
        case .claude: "Claude"
        case .cursor: "Cursor"
        case .codex:  "Codex"
        case .grok:   "Grok"
        }
    }

    var outline: [[CGPoint]] {
        switch self {
        case .claude: GlyphOutline.claude
        case .cursor: GlyphOutline.cursor
        case .codex:  GlyphOutline.openai
        case .grok:   GlyphOutline.grok
        }
    }

    var opticalScale: CGFloat {
        switch self {
        case .claude, .cursor: 0.97
        case .codex: 0.94
        case .grok: 1.0
        }
    }

    var tokens: [String] {
        switch self {
        case .claude: ["claude", "anthropic"]
        case .cursor: ["cursor", "todesktop.230313mzl4w4u92"]
        case .codex:  ["codex"]
        case .grok:   ["grok", "x.ai", "xai."]
        }
    }

    func claims(_ name: String) -> Bool {
        let name = name.lowercased()
        return tokens.contains { name.contains($0) }
    }

    var nests: [Nest] {
        switch self {
        case .claude:
            [
                Nest(path: .home(".claude"), fallback: .state, rules: [
                    ("projects", .history), ("file-history", .history), ("history", .history),
                    ("todos", .history), ("transcripts", .history), ("teams", .history), ("uploads", .history),
                    ("shell-snapshots", .temp), ("session-env", .temp),
                    ("skills", .skills), ("plugins", .skills), ("agents", .skills), ("commands", .skills),
                    ("cache", .caches), ("statsig", .caches), ("telemetry", .caches), ("paste-cache", .caches),
                    ("debug", .logs), ("worktrees", .worktrees),
                ]),
                Nest(path: .appSupport("Claude"), fallback: .state, rules: [
                    ("vm_bundles", .vm), ("claude-code-vm", .vm),
                    ("claude-code-sessions", .history), ("local-agent-mode-sessions", .history),
                    ("claude-code", .cli),
                    ("cache", .caches), ("code cache", .caches), ("gpucache", .caches), ("dawn", .caches),
                    ("shared dictionary", .caches), ("crashpad", .logs), ("logs", .logs),
                ]),
            ]
        case .cursor:
            [
                Nest(path: .home(".cursor"), fallback: .state, rules: [
                    ("chats", .history), ("projects", .history),
                    ("worktrees", .worktrees),
                    ("extensions", .skills), ("plugins", .skills), ("skills", .skills),
                    ("statsig", .caches), ("cache", .caches),
                ]),
                Nest(path: .appSupport("Cursor"), fallback: .state, rules: [
                    ("user", .history),
                    ("cacheddata", .caches), ("cachedprofilesdata", .caches), ("cache", .caches),
                    ("code cache", .caches), ("gpucache", .caches), ("dawn", .caches),
                    ("logs", .logs), ("crashpad", .logs),
                ]),
            ]
        case .codex:
            [
                Nest(path: .home(".codex"), fallback: .state, rules: [
                    ("sessions", .history), ("archived_sessions", .history), ("thread_history", .history),
                    ("history", .history), ("generated_images", .history),
                    ("worktrees", .worktrees),
                    ("logs", .logs), ("log", .logs),
                    (".tmp", .temp), ("tmp", .temp),
                    ("cache", .caches), ("models_cache", .caches),
                    ("plugins", .skills), ("skills", .skills),
                ]),
            ]
        case .grok:
            [
                Nest(path: .home(".grok"), fallback: .state, rules: [
                    ("sessions", .history), ("memory", .history), ("memtrace", .history), ("projects", .history),
                    ("worktrees", .worktrees),
                    ("marketplace-cache", .caches), ("downloads", .caches), ("cache", .caches),
                    ("logs", .logs),
                    ("bundled", .cli), ("vendor", .cli), ("bin", .cli),
                ]),
            ]
        }
    }

    var bundles: [URL] {
        switch self {
        case .codex:
            ["Resources", "Frameworks", "PlugIns"].map { URL(filePath: "/Applications/ChatGPT.app/Contents").appending(path: $0) }
        case .claude, .cursor, .grok:
            []
        }
    }

    var spots: [Spot] {
        switch self {
        case .claude:
            [
                Spot(path: .home(".claude.json"), kind: .state),
                Spot(path: .home(".local/share/claude"), kind: .cli),
                Spot(path: .home(".local/state/claude"), kind: .state),
                Spot(path: .home(".cache/claude"), kind: .caches),
                Spot(path: .home(".npm-global/lib/node_modules/@anthropic-ai"), kind: .cli),
                Spot(path: URL(filePath: "/opt/homebrew/lib/node_modules/@anthropic-ai"), kind: .cli),
                Spot(path: URL(filePath: "/usr/local/lib/node_modules/@anthropic-ai"), kind: .cli),
            ]
        case .cursor:
            [
                Spot(path: .home(".local/share/cursor-agent"), kind: .cli),
                Spot(path: .appSupport("Caches/cursor-updater"), kind: .caches),
            ]
        case .codex:
            [
                Spot(path: .appSupport("com.openai.codex"), kind: .state),
                Spot(path: URL(filePath: "/opt/homebrew/lib/node_modules/@openai/codex"), kind: .cli),
                Spot(path: URL(filePath: "/usr/local/lib/node_modules/@openai/codex"), kind: .cli),
            ]
        case .grok:
            [
                Spot(path: .home(".local/share/grok"), kind: .cli),
                Spot(path: .home(".cache/grok"), kind: .caches),
            ]
        }
    }
}

extension URL {
    static func home(_ path: String) -> URL {
        FileManager.default.homeDirectoryForCurrentUser.appending(path: path)
    }

    static func appSupport(_ path: String) -> URL {
        home("Library/Application Support").appending(path: path)
    }
}
