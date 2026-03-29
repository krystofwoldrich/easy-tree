import Combine
import Foundation
import Sparkle

@MainActor
final class UpdaterViewModel: ObservableObject {
    private var updaterController: SPUStandardUpdaterController?

    @Published var canCheckForUpdates = false

    private var cancellable: AnyCancellable?

    init() {
        // Only start Sparkle if SUFeedURL is properly configured
        guard let feedURL = Bundle.main.infoDictionary?["SUFeedURL"] as? String,
            !feedURL.isEmpty,
            !feedURL.contains("$(")
        else {
            return
        }

        let controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        updaterController = controller

        cancellable = controller.updater.publisher(for: \.canCheckForUpdates)
            .receive(on: RunLoop.main)
            .sink { [weak self] value in
                self?.canCheckForUpdates = value
            }
    }

    func checkForUpdates() {
        updaterController?.checkForUpdates(nil)
    }
}
