import Testing

@testable import EasyTreeKit

@Suite("EasyTreeCLI Tests")
struct EasyTreeCLITests {
    @Test("CLI uses library version")
    func cliUsesLibraryVersion() {
        #expect(EasyTreeKit.version == "0.1.0")
    }
}
