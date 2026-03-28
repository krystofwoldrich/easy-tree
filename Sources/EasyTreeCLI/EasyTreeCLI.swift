import ArgumentParser
import EasyTreeKit

@main
struct EasyTreeCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "easy-tree",
        abstract: "Simplify working with git worktrees.",
        version: EasyTreeKit.version
    )

    func run() throws {
        print("easy-tree v\(EasyTreeKit.version)")
    }
}
