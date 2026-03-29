import EasyTreeKit
import SwiftUI

struct ContentView: View {
    @State private var store = WorkspaceStore()
    @State private var showError = false

    var body: some View {
        ScrollView {
            if store.workspaces.isEmpty {
                emptyState
            } else {
                workspaceList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("EasyTree")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    addWorkspace()
                } label: {
                    Label("Add Workspace", systemImage: "plus")
                }
                .disabled(store.isAddingWorkspace)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
        .onChange(of: store.errorMessage) {
            showError = store.errorMessage != nil
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tree.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No Workspaces")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Add a git repository to get started.")
                .font(.body)
                .foregroundStyle(.tertiary)
            Button("Add Workspace") {
                addWorkspace()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 120)
    }

    private var workspaceList: some View {
        LazyVStack(spacing: 12) {
            ForEach($store.workspaces) { $workspace in
                WorkspaceRow(
                    workspace: $workspace,
                    isBusy: store.busyWorkspaceIDs.contains(workspace.id),
                    onCreateWorktree: {
                        store.createWorktree(for: workspace)
                    },
                    onOpenWorktree: { worktree, target in
                        target.open(path: worktree.path)
                    },
                    onRemoveWorkspace: {
                        store.removeWorkspace(workspace)
                    },
                    onSave: {
                        store.save()
                    }
                )
            }
        }
        .padding(16)
    }

    private func addWorkspace() {
        let panel = NSOpenPanel()
        panel.title = "Select a Git Repository"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let url = panel.url else { return }
        store.addWorkspace(at: url)
    }

}

#Preview {
    ContentView()
}
