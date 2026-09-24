import Foundation

enum Kind: String, CaseIterable {
    case worktrees
    case history
    case vm
    case docker
    case caches
    case temp
    case skills
    case cli
    case app
    case logs
    case state

    var title: String {
        switch self {
        case .worktrees: "Worktrees"
        case .history:   "Sessions & history"
        case .vm:        "VM images"
        case .docker:    "Docker"
        case .caches:    "Caches"
        case .temp:      "Temp files"
        case .skills:    "Skills & plugins"
        case .cli:       "CLI versions"
        case .app:       "App bundle"
        case .logs:      "Logs"
        case .state:     "Settings & state"
        }
    }
}
