import AppKit
import Foundation
import SwiftUI

enum OpenTarget: String, CaseIterable, Identifiable, Codable {
    case vscode = "VSCode"
    case cursor = "Cursor"
    case zed = "Zed"
    case iterm = "iTerm"
    case ghostty = "Ghostty"
    case terminal = "Terminal"
    case finder = "Finder"

    var id: String { rawValue }

    static func from(_ string: String) -> Self? {
        allCases.first { $0.rawValue.lowercased() == string.lowercased() }
    }

    var bundleID: String {
        switch self {
        case .vscode: "com.microsoft.VSCode"
        case .cursor: "com.todesktop.230313mzl4w4u92"
        case .zed: "dev.zed.Zed"
        case .iterm: "com.googlecode.iterm2"
        case .ghostty: "com.mitchellh.ghostty"
        case .terminal: "com.apple.Terminal"
        case .finder: "com.apple.finder"
        }
    }

    var icon: NSImage {
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            return NSWorkspace.shared.icon(forFile: appURL.path)
        }
        return NSWorkspace.shared.icon(for: .applicationBundle)
    }

    func open(path: String) {
        let url = URL(fileURLWithPath: path)
        if self == .finder {
            NSWorkspace.shared.open(url)
            return
        }
        openWithBundleID(bundleID, url: url)
    }

    private func openWithBundleID(_ bundleID: String, url: URL) {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            NSWorkspace.shared.open(url)
            return
        }
        NSWorkspace.shared.open(
            [url],
            withApplicationAt: appURL,
            configuration: NSWorkspace.OpenConfiguration()
        )
    }
}
