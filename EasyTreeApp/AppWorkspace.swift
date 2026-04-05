import EasyTreeKit
import Foundation

struct AppWorktree: Identifiable, Codable {
    var id: String { name }
    let name: String
    let path: String
    let branch: String
    var primaryTarget: OpenTarget
    var secondaryTarget: OpenTarget
    var archived: Bool

    init(
        name: String,
        path: String,
        branch: String,
        primaryTarget: OpenTarget = .vscode,
        secondaryTarget: OpenTarget = .iterm,
        archived: Bool = false
    ) {
        self.name = name
        self.path = path
        self.branch = branch
        self.primaryTarget = primaryTarget
        self.secondaryTarget = secondaryTarget
        self.archived = archived
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        path = try container.decode(String.self, forKey: .path)
        branch = try container.decode(String.self, forKey: .branch)
        primaryTarget = try container.decodeIfPresent(OpenTarget.self, forKey: .primaryTarget) ?? .vscode
        secondaryTarget = try container.decodeIfPresent(OpenTarget.self, forKey: .secondaryTarget) ?? .iterm
        archived = try container.decodeIfPresent(Bool.self, forKey: .archived) ?? false
    }

    var displayPath: String { shortenHomePath(path) }
}

private func shortenHomePath(_ path: String) -> String {
    let home = FileManager.default.homeDirectoryForCurrentUser.path
    if path.hasPrefix(home) {
        return "~" + path.dropFirst(home.count)
    }
    return path
}

struct ExternalWorktree: Identifiable {
    var id: String { path }
    let path: String
    let branch: String
    let name: String

    var displayPath: String { shortenHomePath(path) }
}

struct AppWorkspace: Identifiable, Codable {
    var id: String { path }
    let path: String
    let repoName: String
    var currentBranch: String
    var worktrees: [AppWorktree]
    var primaryTarget: OpenTarget
    var secondaryTarget: OpenTarget

    /// External worktrees detected via git but not managed by EasyTree. Not persisted.
    var externalWorktrees: [ExternalWorktree] {
        get { _externalWorktrees ?? [] }
        set { _externalWorktrees = newValue }
    }

    private var _externalWorktrees: [ExternalWorktree]?

    private enum CodingKeys: String, CodingKey {
        case path, repoName, currentBranch, worktrees, primaryTarget, secondaryTarget
    }

    init(
        path: String,
        repoName: String,
        currentBranch: String = "",
        worktrees: [AppWorktree] = [],
        primaryTarget: OpenTarget = .vscode,
        secondaryTarget: OpenTarget = .iterm
    ) {
        self.path = path
        self.repoName = repoName
        self.currentBranch = currentBranch
        self.worktrees = worktrees
        self.primaryTarget = primaryTarget
        self.secondaryTarget = secondaryTarget
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        path = try container.decode(String.self, forKey: .path)
        repoName = try container.decode(String.self, forKey: .repoName)
        currentBranch = try container.decodeIfPresent(String.self, forKey: .currentBranch) ?? ""
        worktrees = try container.decode([AppWorktree].self, forKey: .worktrees)
        primaryTarget = try container.decodeIfPresent(OpenTarget.self, forKey: .primaryTarget) ?? .vscode
        secondaryTarget = try container.decodeIfPresent(OpenTarget.self, forKey: .secondaryTarget) ?? .iterm
    }

    var displayPath: String { shortenHomePath(path) }
}
