import Foundation

public enum EasyTreeError: LocalizedError {
    case notAGitRepository(URL)
    case gitCommandFailed(command: String, output: String)
    case cannotDetectRemoteHead
    case allCityNamesExhausted
    case fileSystemError(String)

    public var errorDescription: String? {
        switch self {
        case .notAGitRepository(let url):
            "Not a git repository: \(url.path)"
        case .gitCommandFailed(let command, let output):
            "Git command failed: \(command)\n\(output)"
        case .cannotDetectRemoteHead:
            "Cannot detect remote HEAD. Ensure the repository has a remote 'origin'."
        case .allCityNamesExhausted:
            "All city names have been used. This is extremely unlikely."
        case .fileSystemError(let message):
            "File system error: \(message)"
        }
    }
}
