import EasyTreeKit
import Foundation

struct AppWorktree: Identifiable, Codable {
    var id: String { name }
    let name: String
    let path: String
    let branch: String
    var primaryTarget: OpenTarget
    var secondaryTarget: OpenTarget

    init(
        name: String,
        path: String,
        branch: String,
        primaryTarget: OpenTarget = .vscode,
        secondaryTarget: OpenTarget = .iterm
    ) {
        self.name = name
        self.path = path
        self.branch = branch
        self.primaryTarget = primaryTarget
        self.secondaryTarget = secondaryTarget
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        path = try container.decode(String.self, forKey: .path)
        branch = try container.decode(String.self, forKey: .branch)
        primaryTarget = try container.decodeIfPresent(OpenTarget.self, forKey: .primaryTarget) ?? .vscode
        secondaryTarget = try container.decodeIfPresent(OpenTarget.self, forKey: .secondaryTarget) ?? .iterm
    }
}

struct AppWorkspace: Identifiable, Codable {
    var id: String { path }
    let path: String
    let repoName: String
    var worktrees: [AppWorktree]
}
