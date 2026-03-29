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

    init(baseDirectory: URL = EasyTreeKit.defaultBaseDirectory) {
        self.baseDirectory = baseDirectory
        self.storeFile = baseDirectory.appendingPathComponent("workspaces.json")
        load()
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

                await MainActor.run {
                    guard !self.workspaces.contains(where: { $0.path == repo.rootURL.path }) else {
                        self.errorMessage = "Workspace '\(repo.name)' is already added."
                        self.busyWorkspaceIDs.remove("__adding__")
                        return
                    }

                    var workspace = AppWorkspace(
                        path: repo.rootURL.path,
                        repoName: repo.name,
                        worktrees: []
                    )
                    self.workspaces.append(workspace)
                    self.busyWorkspaceIDs.remove("__adding__")
                    self.busyWorkspaceIDs.insert(workspace.id)
                    self.save()
                }

                let worktree = try self.createWorktreeSync(repo: repo, baseDirectory: baseDir)

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

        Task.detached {
            do {
                let repo = try RepoInfo.detect(from: URL(fileURLWithPath: workspacePath))
                let worktree = try self.createWorktreeSync(repo: repo, baseDirectory: baseDir)

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
        workspaces.removeAll { $0.id == workspace.id }
        save()
    }

    func removeWorktree(_ worktree: AppWorktree, from workspace: AppWorkspace) {
        guard let index = workspaces.firstIndex(where: { $0.id == workspace.id }) else { return }
        workspaces[index].worktrees.removeAll { $0.id == worktree.id }
        save()
    }

    nonisolated private func createWorktreeSync(
        repo: RepoInfo,
        baseDirectory: URL
    ) throws -> AppWorktree {
        let config = try ConfigManager(baseDirectory: baseDirectory).load()
        let manager = WorktreeManager(baseDirectory: baseDirectory, config: config)
        let worktree = try manager.create(repo: repo)
        return AppWorktree(
            name: worktree.name,
            path: worktree.path.path,
            branch: worktree.branch
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
