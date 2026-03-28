import Foundation

public struct NameRegistry: Sendable {
    private let filePath: URL

    public init(baseDirectory: URL) {
        self.filePath = baseDirectory.appendingPathComponent("used-names.json")
    }

    /// Claims a random unique name from the given naming set. Appends -vN if already used.
    public func claimName(from namingSet: NamingSet) throws -> String {
        var usedNames = try loadUsedNames()

        let shuffled = namingSet.names.shuffled()
        for name in shuffled where usedNames[name] == nil {
            usedNames[name] = 1
            try saveUsedNames(usedNames)
            return name
        }

        // All base names used — pick a random one and append -vN
        let name = shuffled[0]
        let count = usedNames[name, default: 0] + 1
        usedNames[name] = count
        let versionedName = "\(name)-v\(count)"
        try saveUsedNames(usedNames)
        return versionedName
    }

    public func usedNames() throws -> [String: Int] {
        try loadUsedNames()
    }

    private func loadUsedNames() throws -> [String: Int] {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: filePath.path) else {
            return [:]
        }

        let data = try Data(contentsOf: filePath)
        return try JSONDecoder().decode([String: Int].self, from: data)
    }

    private func saveUsedNames(_ names: [String: Int]) throws {
        let fileManager = FileManager.default
        let directory = filePath.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(names)
        try data.write(to: filePath, options: .atomic)
    }
}
