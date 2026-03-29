import SwiftUI

@main
struct EasyTreeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 400, minHeight: 600)
        }
        .defaultSize(width: 400, height: 600)
        .windowStyle(.automatic)
        .windowToolbarStyle(.automatic)
    }
}
