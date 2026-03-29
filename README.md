<p align="center">
  <img src="assets/icon.png" width="128" height="128" alt="EasyTree icon">
</p>

<h1 align="center">EasyTree</h1>

<p align="center">
  Simplify working with git worktrees.
</p>

EasyTree creates and manages git worktrees so you don't have to remember the commands. Each worktree gets a random city name (or river, park, mountain) for easy identification. Worktrees are stored in `~/.easy-tree/{repo}/{name}`.

<p align="center">
  <img src="assets/app-screenshot.png" width="500" alt="EasyTree app screenshot">
</p>

## Components

### EasyTreeKit (Swift Package)

The core library that handles:

- Git repository detection (works from subdirectories and inside worktrees)
- Worktree creation with `git fetch` + new branch from remote HEAD
- Unique name generation from 500+ world cities, rivers, national parks, or mountains
- Name registry to prevent duplicates across all repositories
- Configuration via `~/.easy-tree/config.json`

```swift
import EasyTreeKit

let repo = try RepoInfo.detect(from: cwd)
let manager = WorktreeManager(baseDirectory: EasyTreeKit.defaultBaseDirectory)
let worktree = try manager.create(repo: repo)
```

### easy-tree (CLI)

A command-line tool built on swift-argument-parser.

```bash
# Create a new worktree and cd into it
cd "$(easy-tree create)"

# Check version
easy-tree --version
```

The `create` command prints status messages to stderr and the worktree path to stdout, making it composable with shell commands.

### EasyTree (macOS App)

A SwiftUI app with Liquid Glass design for managing worktrees visually.

- Add git repositories as workspaces
- Create worktrees with one click
- Open worktrees directly in VSCode, Cursor, Zed, iTerm, Ghostty, Terminal, or Finder
- Per-worktree configurable open targets with dual buttons

## Configuration

Create `~/.easy-tree/config.json` to customize behavior:

```json
{
  "gitPath": "/opt/homebrew/bin/git",
  "namingSet": "mountains"
}
```

| Key | Values | Default |
|-----|--------|---------|
| `gitPath` | Path to git binary | `/usr/bin/git` |
| `namingSet` | `cities`, `rivers`, `parks`, `mountains` | `cities` |

## Building

Requires Swift 6.2+ and macOS 26.

```bash
# Build library and CLI
swift build

# Run tests
swift test

# Run CLI
swift run easy-tree create

# Build macOS app (requires xcodegen)
xcodegen generate
open EasyTree.xcworkspace
```

## Project Structure

```
easy-tree/
├── Package.swift              # SPM: EasyTreeKit + easy-tree CLI
├── project.yml                # XcodeGen spec for macOS app
├── EasyTree.xcworkspace       # Workspace with package + app
├── Sources/
│   ├── EasyTreeKit/           # Core library
│   └── EasyTreeCLI/           # CLI executable
├── EasyTreeApp/               # macOS SwiftUI app
├── Tests/
│   ├── EasyTreeKitTests/
│   ├── EasyTreeCLITests/
│   └── EasyTreeAppTests/
└── assets/                    # README images
```

## License

MIT
