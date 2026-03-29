import EasyTreeKit
import SwiftUI

@main
struct EasyTreeApp: App {
    @StateObject private var updaterViewModel = UpdaterViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 400, minHeight: 600)
        }
        .defaultSize(width: 400, height: 600)
        .windowStyle(.automatic)
        .windowToolbarStyle(.automatic)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    updaterViewModel.checkForUpdates()
                }
                .disabled(!updaterViewModel.canCheckForUpdates)
            }
            CommandGroup(after: .appSettings) {
                Button("Settings...") {
                    openConfig()
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }

    private func openConfig() {
        let configURL = EasyTreeKit.defaultBaseDirectory.appendingPathComponent("config.json")
        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: configURL.path) {
            try? fileManager.createDirectory(
                at: EasyTreeKit.defaultBaseDirectory,
                withIntermediateDirectories: true
            )
            try? Data("{\n}\n".utf8).write(to: configURL)
        }

        NSWorkspace.shared.open(
            [configURL],
            withApplicationAt: NSWorkspace.shared.urlForApplication(
                withBundleIdentifier: "com.apple.TextEdit"
            )!,
            configuration: NSWorkspace.OpenConfiguration()
        )
    }
}
