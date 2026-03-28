import Foundation

public struct NameRegistry: Sendable {
    private let filePath: URL

    public init(baseDirectory: URL) {
        self.filePath = baseDirectory.appendingPathComponent("used-names.json")
    }

    /// Claims a random unique city name. Appends -vN if already used.
    public func claimName() throws -> String {
        var usedNames = try loadUsedNames()

        // Shuffle cities and try to find an unused base name
        let shuffled = CityNames.all.shuffled()
        for city in shuffled where usedNames[city] == nil {
            usedNames[city] = 1
            try saveUsedNames(usedNames)
            return city
        }

        // All base names used — pick a random one and append -vN
        let city = shuffled[0]
        let count = usedNames[city, default: 0] + 1
        usedNames[city] = count
        let versionedName = "\(city)-v\(count)"
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
