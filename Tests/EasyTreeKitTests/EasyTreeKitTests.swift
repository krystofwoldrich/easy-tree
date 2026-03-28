import Testing

@testable import EasyTreeKit

@Suite("EasyTreeKit Tests")
struct EasyTreeKitTests {
    @Test("Version is set")
    func versionIsSet() {
        #expect(!EasyTreeKit.version.isEmpty)
    }
}
