import Foundation

public struct Worktree: Sendable {
    /// The city name used for this worktree.
    public let name: String

    /// Absolute path to the worktree directory.
    public let path: URL

    /// The branch name checked out in the worktree.
    public let branch: String

    public init(name: String, path: URL, branch: String) {
        self.name = name
        self.path = path
        self.branch = branch
    }
}
