import Foundation

public struct RepoInfo: Sendable {
    /// Name of the repository directory (e.g., "my-app").
    public let name: String

    /// Absolute URL to the main repository root (not a worktree).
    public let rootURL: URL

    /// Detects the git repository from the given directory.
    /// Walks up the directory tree to find `.git`.
    /// If inside a worktree, resolves to the main repository root.
    public static func detect(from directory: URL) throws -> Self {
        let repoRoot = try findGitRoot(from: directory)
        let mainRoot = try resolveMainRepoRoot(gitRoot: repoRoot)
        let name = mainRoot.lastPathComponent
        return Self(name: name, rootURL: mainRoot)
    }

    /// Walks up from the given directory to find a `.git` file or directory.
    private static func findGitRoot(from directory: URL) throws -> URL {
        let fileManager = FileManager.default
        var current = directory.standardizedFileURL

        while current.path != "/" {
            let gitPath = current.appendingPathComponent(".git")
            if fileManager.fileExists(atPath: gitPath.path) {
                return current
            }
            current = current.deletingLastPathComponent()
        }

        throw EasyTreeError.notAGitRepository(directory)
    }

    /// If `.git` is a file (worktree), resolve to the main repository root.
    /// If `.git` is a directory (main repo), return as-is.
    private static func resolveMainRepoRoot(gitRoot: URL) throws -> URL {
        let gitPath = gitRoot.appendingPathComponent(".git")
        let fileManager = FileManager.default

        var isDirectory: ObjCBool = false
        fileManager.fileExists(atPath: gitPath.path, isDirectory: &isDirectory)

        if isDirectory.boolValue {
            // We're in the main repository
            return gitRoot
        }

        // .git is a file — we're in a worktree
        // Content looks like: "gitdir: /path/to/main-repo/.git/worktrees/tree-name"
        let content = try String(contentsOf: gitPath, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard content.hasPrefix("gitdir: ") else {
            throw EasyTreeError.notAGitRepository(gitRoot)
        }

        let gitDir = String(content.dropFirst("gitdir: ".count))
        // gitDir is something like /path/to/main-repo/.git/worktrees/tree-name
        // Walk up to find the .git directory, then its parent is the main repo
        var gitDirURL = URL(fileURLWithPath: gitDir).standardizedFileURL

        // Walk up until we find a path that ends with .git
        while gitDirURL.path != "/" {
            if gitDirURL.lastPathComponent == ".git" {
                return gitDirURL.deletingLastPathComponent()
            }
            gitDirURL = gitDirURL.deletingLastPathComponent()
        }

        throw EasyTreeError.notAGitRepository(gitRoot)
    }
}
