import EasyTreeKit
import Foundation
import Observation

@Observable
@MainActor
final class WorkspaceStore {
    var workspaces: [AppWorkspace] = []
    var errorMessage: String?
    var busyWorkspaceIDs: Set<String> = []

    private let baseDirectory: URL
    private let storeFile: URL
    private var headWatchers: [String: HeadWatcher] = [:]

    init(baseDirectory: URL = EasyTreeKit.defaultBaseDirectory) {
        self.baseDirectory = baseDirectory
        self.storeFile = baseDirectory.appendingPathComponent("workspaces.json")
        load()
        refreshAllBranches()
        startWatchingAll()
    }

    var isAddingWorkspace: Bool {
        busyWorkspaceIDs.contains("__adding__")
    }

    func addWorkspace(at url: URL) {
        let baseDir = baseDirectory
        busyWorkspaceIDs.insert("__adding__")

        Task.detached {
            do {
                let repo = try RepoInfo.detect(from: url)

                let config = try ConfigManager(baseDirectory: baseDir).load()
                let branch =
                    (try? GitShell(workingDirectory: repo.rootURL)
                        .run("rev-parse", "--abbrev-ref", "HEAD")) ?? ""
                let primary = config.primaryOpen.flatMap { OpenTarget.from($0) } ?? .vscode
                let secondary = config.secondaryOpen.flatMap { OpenTarget.from($0) } ?? .iterm

                await MainActor.run {
                    guard !self.workspaces.contains(where: { $0.path == repo.rootURL.path }) else {
                        self.errorMessage = "Workspace '\(repo.name)' is already added."
                        self.busyWorkspaceIDs.remove("__adding__")
                        return
                    }

                    let workspace = AppWorkspace(
                        path: repo.rootURL.path,
                        repoName: repo.name,
                        currentBranch: branch,
                        primaryTarget: primary,
                        secondaryTarget: secondary
                    )
                    self.workspaces.append(workspace)
                    self.busyWorkspaceIDs.remove("__adding__")
                    self.busyWorkspaceIDs.insert(workspace.id)
                    self.save()
                    self.startWatching(workspace)
                }

                let worktree = try self.createWorktreeSync(
                    repo: repo,
                    baseDirectory: baseDir,
                    primaryTarget: primary,
                    secondaryTarget: secondary
                )

                await MainActor.run {
                    if let index = self.workspaces.firstIndex(where: { $0.path == repo.rootURL.path }) {
                        self.workspaces[index].worktrees.append(worktree)
                        self.busyWorkspaceIDs.remove(self.workspaces[index].id)
                        self.save()
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.busyWorkspaceIDs.remove("__adding__")
                }
            }
        }
    }

    func createWorktree(for workspace: AppWorkspace) {
        guard !busyWorkspaceIDs.contains(workspace.id) else { return }
        busyWorkspaceIDs.insert(workspace.id)

        let workspacePath = workspace.path
        let workspaceID = workspace.id
        let baseDir = baseDirectory
        let primary = workspace.primaryTarget
        let secondary = workspace.secondaryTarget

        Task.detached {
            do {
                let repo = try RepoInfo.detect(from: URL(fileURLWithPath: workspacePath))
                let worktree = try self.createWorktreeSync(
                    repo: repo,
                    baseDirectory: baseDir,
                    primaryTarget: primary,
                    secondaryTarget: secondary
                )

                await MainActor.run {
                    if let index = self.workspaces.firstIndex(where: { $0.id == workspaceID }) {
                        self.workspaces[index].worktrees.append(worktree)
                        self.save()
                    }
                    self.busyWorkspaceIDs.remove(workspaceID)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.busyWorkspaceIDs.remove(workspaceID)
                }
            }
        }
    }

    func removeWorkspace(_ workspace: AppWorkspace) {
        headWatchers.removeValue(forKey: workspace.id)
        workspaces.removeAll { $0.id == workspace.id }
        save()
    }

    func removeWorktree(_ worktree: AppWorktree, from workspace: AppWorkspace) {
        guard let index = workspaces.firstIndex(where: { $0.id == workspace.id }) else { return }
        workspaces[index].worktrees.removeAll { $0.id == worktree.id }
        save()
    }

    // MARK: - Branch Watching

    private func refreshAllBranches() {
        for workspace in workspaces {
            refreshBranch(for: workspace)
        }
    }

    private func refreshBranch(for workspace: AppWorkspace) {
        let workspacePath = workspace.path
        let workspaceID = workspace.id

        Task.detached {
            let branch =
                (try? GitShell(workingDirectory: URL(fileURLWithPath: workspacePath))
                    .run("rev-parse", "--abbrev-ref", "HEAD")) ?? ""

            await MainActor.run {
                if let index = self.workspaces.firstIndex(where: { $0.id == workspaceID }) {
                    guard self.workspaces[index].currentBranch != branch else { return }
                    self.workspaces[index].currentBranch = branch
                    self.save()
                }
            }
        }
    }

    private func startWatchingAll() {
        for workspace in workspaces {
            startWatching(workspace)
        }
    }

    private func startWatching(_ workspace: AppWorkspace) {
        let headPath = workspace.path + "/.git/HEAD"
        let workspaceID = workspace.id

        headWatchers[workspaceID] = HeadWatcher(path: headPath) { [weak self] in
            Task { @MainActor in
                guard let self,
                    let workspace = self.workspaces.first(where: { $0.id == workspaceID })
                else { return }
                self.refreshBranch(for: workspace)
            }
        }
    }

    // MARK: - Persistence

    nonisolated private func createWorktreeSync(
        repo: RepoInfo,
        baseDirectory: URL,
        primaryTarget: OpenTarget,
        secondaryTarget: OpenTarget
    ) throws -> AppWorktree {
        let config = try ConfigManager(baseDirectory: baseDirectory).load()
        let manager = WorktreeManager(baseDirectory: baseDirectory, config: config)
        let worktree = try manager.create(repo: repo)
        return AppWorktree(
            name: worktree.name,
            path: worktree.path.path,
            branch: worktree.branch,
            primaryTarget: primaryTarget,
            secondaryTarget: secondaryTarget
        )
    }

    private func load() {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: storeFile.path) else { return }

        do {
            let data = try Data(contentsOf: storeFile)
            workspaces = try JSONDecoder().decode([AppWorkspace].self, from: data)
        } catch {
            errorMessage = "Failed to load workspaces: \(error.localizedDescription)"
        }
    }

    func save() {
        do {
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: baseDirectory.path) {
                try fileManager.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
            }
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(workspaces)
            try data.write(to: storeFile, options: .atomic)
        } catch {
            errorMessage = "Failed to save workspaces: \(error.localizedDescription)"
        }
    }
}

// MARK: - File Watcher

private final class HeadWatcher: @unchecked Sendable {
    private var source: DispatchSourceFileSystemObject?
    private let fileDescriptor: Int32

    init(path: String, onChange: @escaping () -> Void) {
        fileDescriptor = open(path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .rename, .delete],
            queue: .global(qos: .utility)
        )

        source.setEventHandler { onChange() }
        source.setCancelHandler { [fileDescriptor] in close(fileDescriptor) }
        source.resume()
        self.source = source
    }

    deinit {
        source?.cancel()
    }
}
