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
            let baseDir = EasyTreeKit.defaultBaseDirectory
            let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            let repo = try RepoInfo.detect(from: cwd)
            let config = try ConfigManager(baseDirectory: baseDir).load()
            let manager = WorktreeManager(baseDirectory: baseDir, config: config)

            printErr("Fetching latest from origin...")
            let worktree = try manager.create(repo: repo)

            printErr("Created worktree '\(worktree.name)' for '\(repo.name)'")
            printErr("  Branch: \(worktree.branch)")
            printErr("  Path:   \(worktree.path.path)")

            // Print path to stdout for shell integration (cd "$(easy-tree create)")
            print(worktree.path.path)
        }
    }

}

private func printErr(_ message: String) {
    FileHandle.standardError.write(Data((message + "\n").utf8))
}
