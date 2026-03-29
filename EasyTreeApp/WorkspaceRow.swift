import SwiftUI

struct WorkspaceRow: View {
    @Binding var workspace: AppWorkspace
    let isBusy: Bool
    let showArchived: Bool
    let onCreateWorktree: () -> Void
    let onOpenWorktree: (AppWorktree, OpenTarget) -> Void
    let onOpenWorkspace: (OpenTarget) -> Void
    let onRemoveWorkspace: () -> Void
    let onSave: () -> Void

    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            workspaceHeader
            if isExpanded {
                worktreeList
            }
        }
        .glassEffect(.regular, in: .rect(cornerRadius: 12, style: .continuous))
    }

    private var workspaceHeader: some View {
        HStack {
            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                .frame(width: 16)
                .foregroundStyle(.secondary)

            Image(systemName: "folder.fill")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(workspace.repoName)
                    .font(.headline)
                Text(workspace.displayPath)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                if !workspace.currentBranch.isEmpty {
                    Text(workspace.currentBranch)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            OpenSplitButton(target: $workspace.primaryTarget, onSave: onSave) { target in
                onOpenWorkspace(target)
            }
            OpenSplitButton(target: $workspace.secondaryTarget, onSave: onSave) { target in
                onOpenWorkspace(target)
            }

            Menu {
                Button(role: .destructive) {
                    onRemoveWorkspace()
                } label: {
                    Label("Remove Workspace", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .buttonStyle(.borderless)
            .menuIndicator(.hidden)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation { isExpanded.toggle() }
        }
    }

    private var worktreeList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()
                .padding(.horizontal, 12)

            createWorktreeRow

            ForEach($workspace.worktrees) { $worktree in
                if showArchived || !worktree.archived {
                    WorktreeItem(
                        worktree: $worktree,
                        onSave: onSave,
                        onArchive: {
                            withAnimation {
                                worktree.archived = !worktree.archived
                                onSave()
                            }
                        }
                    ) { target in
                        onOpenWorktree(worktree, target)
                    }
                }
            }
        }
    }

    private var createWorktreeRow: some View {
        HStack {
            Color.clear
                .frame(width: 16, height: 1)

            if isBusy {
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 16)

                Text("Creating worktree...")
                    .font(.body)
                    .foregroundStyle(.secondary)
            } else {
                Image("GitBranch")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.quaternary)
                    .frame(width: 16)

                Text("New worktree")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Create") {
                onCreateWorktree()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .disabled(isBusy)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}

struct WorktreeItem: View {
    @Binding var worktree: AppWorktree
    let onSave: () -> Void
    let onArchive: () -> Void
    let onOpen: (OpenTarget) -> Void

    @State private var isHovered = false

    var body: some View {
        HStack {
            Button {
                onArchive()
            } label: {
                Image(systemName: worktree.archived ? "arrow.uturn.backward" : "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help(worktree.archived ? "Unarchive worktree" : "Archive worktree")
            .frame(width: 16)
            .opacity(isHovered ? 1 : 0)

            Image("GitBranch")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(worktree.archived ? .quaternary : .secondary)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(worktree.name)
                    .font(.body)
                    .foregroundStyle(worktree.archived ? .secondary : .primary)
                Text(worktree.branch)
                    .font(.caption)
                    .foregroundStyle(worktree.archived ? .quaternary : .secondary)
            }

            Spacer()

            if !worktree.archived {
                OpenSplitButton(target: $worktree.primaryTarget, onSave: onSave) { target in
                    onOpen(target)
                }
                OpenSplitButton(target: $worktree.secondaryTarget, onSave: onSave) { target in
                    onOpen(target)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
    }
}

struct OpenSplitButton: View {
    @Binding var target: OpenTarget
    let onSave: () -> Void
    let action: (OpenTarget) -> Void

    var body: some View {
        HStack(spacing: 0) {
            Menu {
                ForEach(OpenTarget.allCases) { option in
                    Button {
                        target = option
                        onSave()
                    } label: {
                        Label {
                            Text(option.rawValue)
                        } icon: {
                            AppIconView(target: option, size: 16)
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    AppIconView(target: target, size: 14)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .contentShape(Rectangle())
            }
            .menuIndicator(.hidden)

            Divider()
                .frame(height: 14)

            Button {
                action(target)
            } label: {
                Text("Open")
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
            }
        }
        .buttonStyle(.plain)
        .background(.fill.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        .controlSize(.small)
    }
}

struct AppIconView: View {
    let target: OpenTarget
    let size: CGFloat

    var body: some View {
        Image(nsImage: target.icon)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
    }
}
