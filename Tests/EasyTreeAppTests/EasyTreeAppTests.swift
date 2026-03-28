import Testing

@testable import EasyTreeKit

@Suite("EasyTreeApp Tests")
struct EasyTreeAppTests {
    @Test("App can access library")
    func appCanAccessLibrary() {
        #expect(!EasyTreeKit.version.isEmpty)
    }
}
