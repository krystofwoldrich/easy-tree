import Foundation

public struct GitShell: Sendable {
    public let workingDirectory: URL
    public let gitPath: String

    public init(workingDirectory: URL, gitPath: String = "/usr/bin/git") {
        self.workingDirectory = workingDirectory
        self.gitPath = gitPath
    }

    @discardableResult
    public func run(_ arguments: String...) throws -> String {
        try run(arguments)
    }

    @discardableResult
    public func run(_ arguments: [String]) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: gitPath)
        process.arguments = arguments
        process.currentDirectoryURL = workingDirectory

        let pipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let errorOutput = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard process.terminationStatus == 0 else {
            let command = "git \(arguments.joined(separator: " "))"
            let combinedOutput = [output, errorOutput].filter { !$0.isEmpty }.joined(separator: "\n")
            throw EasyTreeError.gitCommandFailed(command: command, output: combinedOutput)
        }

        return output
    }
}
