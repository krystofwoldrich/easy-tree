import Foundation
import Testing

@testable import EasyTreeKit

@Suite("EasyTreeKit Tests")
struct EasyTreeKitTests {
    @Test("Version is set")
    func versionIsSet() {
        #expect(!EasyTreeKit.version.isEmpty)
    }

    @Test("Default base directory points to home")
    func defaultBaseDirectory() {
        let base = EasyTreeKit.defaultBaseDirectory
        #expect(base.lastPathComponent == ".easy-tree")
    }
}

@Suite("NamingSet Tests")
struct NamingSetTests {
    @Test("All naming sets have entries", arguments: NamingSet.allCases)
    func namingSetNotEmpty(namingSet: NamingSet) {
        #expect(!namingSet.names.isEmpty)
    }

    @Test("All naming sets have at least 150 entries", arguments: NamingSet.allCases)
    func namingSetMinimumSize(namingSet: NamingSet) {
        #expect(namingSet.names.count >= 150, "\(namingSet) has only \(namingSet.names.count) entries")
    }

    @Test("All names are lowercase", arguments: NamingSet.allCases)
    func allLowercase(namingSet: NamingSet) {
        for name in namingSet.names {
            #expect(name == name.lowercased(), "'\(name)' in \(namingSet) is not lowercase")
        }
    }

    @Test("All names are unique within set", arguments: NamingSet.allCases)
    func allUniqueWithinSet(namingSet: NamingSet) {
        let unique = Set(namingSet.names)
        #expect(unique.count == namingSet.names.count, "Duplicate names found in \(namingSet)")
    }

    @Test("Names contain no spaces", arguments: NamingSet.allCases)
    func noSpaces(namingSet: NamingSet) {
        for name in namingSet.names {
            #expect(!name.contains(" "), "'\(name)' in \(namingSet) contains a space")
        }
    }

    @Test("Cities has at least 400 entries")
    func citiesSize() {
        #expect(NamingSet.cities.names.count >= 400)
    }
}

@Suite("NameRegistry Tests")
struct NameRegistryTests {
    private func makeTempDirectory() throws -> URL {
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent("easy-tree-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        return temp
    }

    private func cleanup(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    @Test("Claim name returns a name", arguments: NamingSet.allCases)
    func claimNameReturnsName(namingSet: NamingSet) throws {
        let temp = try makeTempDirectory()
        defer { cleanup(temp) }

        let registry = NameRegistry(baseDirectory: temp)
        let name = try registry.claimName(from: namingSet)
        #expect(!name.isEmpty)
    }

    @Test("Claimed names are tracked")
    func claimedNamesAreTracked() throws {
        let temp = try makeTempDirectory()
        defer { cleanup(temp) }

        let registry = NameRegistry(baseDirectory: temp)
        let name = try registry.claimName(from: .cities)
        let usedNames = try registry.usedNames()
        #expect(usedNames[name] == 1)
    }

    @Test("Multiple claims produce different names")
    func multipleClaimsAreDifferent() throws {
        let temp = try makeTempDirectory()
        defer { cleanup(temp) }

        let registry = NameRegistry(baseDirectory: temp)
        let name1 = try registry.claimName(from: .cities)
        let name2 = try registry.claimName(from: .cities)
        #expect(name1 != name2)
    }

    @Test("Names from different sets are tracked in same registry")
    func crossSetTracking() throws {
        let temp = try makeTempDirectory()
        defer { cleanup(temp) }

        let registry = NameRegistry(baseDirectory: temp)
        let city = try registry.claimName(from: .cities)
        let river = try registry.claimName(from: .rivers)
        let usedNames = try registry.usedNames()
        #expect(usedNames[city] == 1)
        #expect(usedNames[river] == 1)
    }
}

@Suite("Config Tests")
struct ConfigTests {
    private func makeTempDirectory() throws -> URL {
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent("easy-tree-config-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        return temp
    }

    @Test("Default config has nil values")
    func defaultConfig() {
        let config = Config()
        #expect(config.gitPath == nil)
        #expect(config.resolvedGitPath == "/usr/bin/git")
        #expect(config.namingSet == nil)
        #expect(config.resolvedNamingSet == .cities)
    }

    @Test("Config with custom values")
    func customConfig() {
        let config = Config(gitPath: "/opt/homebrew/bin/git", namingSet: .mountains)
        #expect(config.resolvedGitPath == "/opt/homebrew/bin/git")
        #expect(config.resolvedNamingSet == .mountains)
    }

    @Test("Load returns default when no file exists")
    func loadDefaultWhenMissing() throws {
        let temp = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: temp) }

        let manager = ConfigManager(baseDirectory: temp)
        let config = try manager.load()
        #expect(config.gitPath == nil)
        #expect(config.namingSet == nil)
    }

    @Test("Save and load round-trips")
    func saveAndLoad() throws {
        let temp = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: temp) }

        let manager = ConfigManager(baseDirectory: temp)
        let original = Config(gitPath: "/usr/local/bin/git", namingSet: .rivers)
        try manager.save(original)

        let loaded = try manager.load()
        #expect(loaded.gitPath == "/usr/local/bin/git")
        #expect(loaded.namingSet == .rivers)
    }
}

@Suite("RepoInfo Tests")
struct RepoInfoTests {
    @Test("Detect throws for non-git directory")
    func detectThrowsForNonGitDirectory() {
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent("not-a-repo-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temp) }

        #expect(throws: EasyTreeError.self) {
            try RepoInfo.detect(from: temp)
        }
    }
}
