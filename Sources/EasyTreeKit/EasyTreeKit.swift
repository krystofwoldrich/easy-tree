import Foundation

public enum EasyTreeKit {
    public static let version = "0.1.0"

    /// The default base directory: ~/.easy-tree/
    public static var defaultBaseDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".easy-tree")
    }
}
