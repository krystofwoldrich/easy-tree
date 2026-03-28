import Foundation

public struct WorktreeManager: Sendable {
    private let baseDirectory: URL
    private let nameRegistry: NameRegistry
    private let config: Config

    public init(baseDirectory: URL, config: Config = Config()) {
        self.baseDirectory = baseDirectory
        self.nameRegistry = NameRegistry(baseDirectory: baseDirectory)
        self.config = config
    }

    /// Creates a new worktree for the given repository.
    ///
    /// 1. Runs `git fetch` to get latest remote data
    /// 2. Detects the remote HEAD branch
    /// 3. Picks a unique random city name
    /// 4. Creates a new branch named after the city from remote HEAD
    /// 5. Creates the worktree at `~/.easy-tree/{repo-name}/{city-name}`
    public func create(repo: RepoInfo) throws -> Worktree {
        let git = GitShell(workingDirectory: repo.rootURL, gitPath: config.resolvedGitPath)

        // 1. Fetch latest
        try git.run("fetch", "--quiet")

        // 2. Detect remote HEAD
        let remoteBranch = try detectRemoteHead(git: git)

        // 3. Pick unique name
        let treeName = try nameRegistry.claimName(from: config.resolvedNamingSet)

        // 4. Determine worktree path
        let worktreePath = baseDirectory
            .appendingPathComponent(repo.name)
            .appendingPathComponent(treeName)

        // 5. Create directory structure
        let fileManager = FileManager.default
        let parentDir = worktreePath.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: parentDir.path) {
            try fileManager.createDirectory(at: parentDir, withIntermediateDirectories: true)
        }

        // 6. Create the worktree with a new branch based on remote HEAD
        try git.run(
            "worktree", "add",
            "-b", treeName,
            worktreePath.path,
            remoteBranch
        )

        return Worktree(
            name: treeName,
            path: worktreePath,
            branch: treeName
        )
    }

    /// Detects the remote HEAD branch (e.g., "origin/main" or "origin/master").
    private func detectRemoteHead(git: GitShell) throws -> String {
        // Try symbolic-ref first (most reliable)
        if let ref = try? git.run("symbolic-ref", "refs/remotes/origin/HEAD") {
            let branch = ref.trimmingCharacters(in: .whitespacesAndNewlines)
            if !branch.isEmpty {
                return branch
            }
        }

        // Fallback: parse `git remote show origin` for HEAD branch
        if let output = try? git.run("remote", "show", "origin") {
            for line in output.components(separatedBy: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("HEAD branch:") {
                    let branchName = trimmed.replacingOccurrences(of: "HEAD branch:", with: "")
                        .trimmingCharacters(in: .whitespaces)
                    return "origin/\(branchName)"
                }
            }
        }

        throw EasyTreeError.cannotDetectRemoteHead
    }
}
