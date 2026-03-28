import Foundation

public struct Config: Codable, Sendable {
    public var gitPath: String?
    public var namingSet: NamingSet?

    public init(gitPath: String? = nil, namingSet: NamingSet? = nil) {
        self.gitPath = gitPath
        self.namingSet = namingSet
    }

    /// Resolved git executable path — uses config override or falls back to /usr/bin/git.
    public var resolvedGitPath: String {
        gitPath ?? "/usr/bin/git"
    }

    /// Resolved naming set — uses config override or falls back to cities.
    public var resolvedNamingSet: NamingSet {
        namingSet ?? .cities
    }
}

public struct ConfigManager: Sendable {
    private let filePath: URL

    public init(baseDirectory: URL) {
        self.filePath = baseDirectory.appendingPathComponent("config.json")
    }

    public func load() throws -> Config {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: filePath.path) else {
            return Config()
        }

        let data = try Data(contentsOf: filePath)
        return try JSONDecoder().decode(Config.self, from: data)
    }

    public func save(_ config: Config) throws {
        let fileManager = FileManager.default
        let directory = filePath.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(config)
        try data.write(to: filePath, options: .atomic)
    }
}
