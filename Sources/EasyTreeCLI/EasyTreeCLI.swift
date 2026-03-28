import ArgumentParser
import EasyTreeKit
import Foundation

@main
struct EasyTreeCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "easy-tree",
        abstract: "Simplify working with git worktrees.",
        version: EasyTreeKit.version,
        subcommands: [Create.self]
    )
}

extension EasyTreeCLI {
    struct Create: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Create a new git worktree with a random city name."
        )

        func run() throws {
            let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            let repo = try RepoInfo.detect(from: cwd)
            let manager = WorktreeManager(baseDirectory: EasyTreeKit.defaultBaseDirectory)

            print("Fetching latest from origin...")
            let worktree = try manager.create(repo: repo)

            print("Created worktree '\(worktree.name)' for '\(repo.name)'")
            print("  Branch: \(worktree.branch)")
            print("  Path:   \(worktree.path.path)")
        }
    }
}
