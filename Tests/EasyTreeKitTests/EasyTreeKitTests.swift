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

@Suite("CityNames Tests")
struct CityNamesTests {
    @Test("City list is not empty")
    func cityListNotEmpty() {
        #expect(!CityNames.all.isEmpty)
    }

    @Test("City list has at least 400 entries")
    func cityListSize() {
        #expect(CityNames.all.count >= 400)
    }

    @Test("All city names are lowercase")
    func allLowercase() {
        for city in CityNames.all {
            #expect(city == city.lowercased(), "City '\(city)' is not lowercase")
        }
    }

    @Test("All city names are unique")
    func allUnique() {
        let unique = Set(CityNames.all)
        #expect(unique.count == CityNames.all.count, "Duplicate city names found")
    }

    @Test("City names contain no spaces")
    func noSpaces() {
        for city in CityNames.all {
            #expect(!city.contains(" "), "City '\(city)' contains a space")
        }
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

    @Test("Claim name returns a city name")
    func claimNameReturnsCity() throws {
        let temp = try makeTempDirectory()
        defer { cleanup(temp) }

        let registry = NameRegistry(baseDirectory: temp)
        let name = try registry.claimName()
        #expect(!name.isEmpty)
    }

    @Test("Claimed names are tracked")
    func claimedNamesAreTracked() throws {
        let temp = try makeTempDirectory()
        defer { cleanup(temp) }

        let registry = NameRegistry(baseDirectory: temp)
        let name = try registry.claimName()
        let usedNames = try registry.usedNames()
        #expect(usedNames[name] == 1)
    }

    @Test("Multiple claims produce different names")
    func multipleClaimsAreDifferent() throws {
        let temp = try makeTempDirectory()
        defer { cleanup(temp) }

        let registry = NameRegistry(baseDirectory: temp)
        let name1 = try registry.claimName()
        let name2 = try registry.claimName()
        #expect(name1 != name2)
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
