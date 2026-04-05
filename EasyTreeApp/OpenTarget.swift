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
        IconCache.shared.icon(for: self)
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

private final class IconCache: @unchecked Sendable {
    nonisolated(unsafe) static let shared = IconCache()
    private var cache: [OpenTarget: NSImage] = [:]

    func icon(for target: OpenTarget) -> NSImage {
        if let cached = cache[target] {
            return cached
        }
        let image: NSImage
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: target.bundleID) {
            image = NSWorkspace.shared.icon(forFile: appURL.path)
        } else {
            image = NSWorkspace.shared.icon(for: .applicationBundle)
        }
        cache[target] = image
        return image
    }
}
