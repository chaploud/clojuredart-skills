# clojuredart-skills

[Claude Code](https://docs.anthropic.com/en/docs/claude-code) skill for [ClojureDart](https://github.com/nicot/cljd)/Flutter mobile development on macOS.

Closes the feedback loop between code edits and visual/runtime verification on iOS Simulator:

```
Edit .cljd → hot reload → Check errors → Screenshot → UI interaction → Repeat
```

Without this skill, Claude Code can edit your ClojureDart code but has no way to see what happened — build errors, UI appearance, and runtime crashes are invisible. These tools give it eyes and hands on the simulator.

## Requirements

- **macOS** (Apple Silicon or Intel)
- **Xcode** with Command Line Tools (`xcode-select --install`)
- **[ClojureDart](https://github.com/nicot/cljd)** project with `pubspec.yaml`

Recommended:
- **tmux** (`brew install tmux`) — enables `cljd-flutter --tmux` mode so the
  Flutter build process lives in a detached session that survives terminal
  crashes and can be driven by agents via `tmux send-keys` / `tmux capture-pane`.
  Without tmux the fallback foreground mode still works, but broken builds
  leave the terminal stuck.

Optional:
- **[AXe](https://github.com/cameroncooke/axe)** for UI interaction (tap, swipe, type, accessibility tree)
  ```bash
  brew tap cameroncooke/axe && brew install axe
  ```

All other dependencies (`xcrun simctl`, `sips`, `python3`) are included with macOS.

## Install

```bash
git clone https://github.com/nicot/clojuredart-skills.git
cd clojuredart-skills
./install.sh
```

This will:
1. Check dependencies
2. Symlink CLI tools to `~/.local/bin/`
3. Register as a Claude Code skill at `~/.claude/skills/clojuredart-skills`

Make sure `~/.local/bin` is in your PATH:
```bash
# Add to your ~/.zshrc or ~/.bashrc
export PATH="$HOME/.local/bin:$PATH"
```

## Uninstall

```bash
./uninstall.sh
```

## Tools

### Core (no AXe required)

| Tool | Description |
|------|-------------|
| `cljd-screenshot` | Capture simulator screenshot, auto-resized for token efficiency |
| `cljd-flutter` | Build wrapper — run in a separate terminal, captures logs to `/tmp/cljd_build.log` |
| `cljd-build-log` | Read and filter build logs (`--errors`, `--since "pattern"`) |
| `cljd-device-log` | Read iOS device logs — print statements, runtime errors |
| `cljd-devices` | List simulators (`--booted`, `--json`) |
| `cljd-errors` | Unified error check across build log + device log |
| `cljd-wait-reload` | Wait for hot reload/restart completion or compilation error |
| `cljd-hot-restart` | Trigger hot restart programmatically via command pipe |

### UI Interaction (requires AXe)

| Tool | Description |
|------|-------------|
| `cljd-ui-tree` | Accessibility tree — find elements and their coordinates (`--compact`, `--interactive`) |
| `cljd-tap` | Tap by coordinates or accessibility label with partial match (`--label "Login"`) |
| `cljd-swipe` | Swipe by direction (`up`/`down`/`left`/`right`) or coordinates |
| `cljd-type` | Type text into focused field |
| `cljd-key` | Press hardware keys (`home`, `lock`, `siri`, etc.) |

## Quick Start

```bash
# 1. Start a simulator
open -a Simulator

# 2. Start the build in a detached tmux session (recommended)
cljd-flutter --tmux --flavor dev
# Logs are still captured to /tmp/cljd_build.log. Attach with `tmux attach -t cljdf`
# if you want to watch interactively; detach with Ctrl-b d.

# 3. Check for errors
cljd-errors

# 4. Take a screenshot
cljd-screenshot
# => /tmp/cljd_screenshot.png

# 5. Inspect UI elements (requires AXe)
cljd-ui-tree --compact
# [Button] "Login" (x:100 y:200 w:80 h:40)
# [TextField] "Email" (x:50 y:300 w:200 h:44) value=""

# 6. Interact with the app
cljd-tap --label "Login"
cljd-swipe up
cljd-type "hello@example.com"

# 7. When the build breaks (CompileC errors, kernel_snapshot etc.)
tmux kill-session -t cljdf
clj -M:cljd clean && fvm flutter clean
cljd-flutter --tmux --flavor dev
```

## Usage with Claude Code

When your project contains `pubspec.yaml` or `.cljd` files, Claude Code automatically loads this skill via `SKILL.md`. The agent can then:

1. Edit `.cljd` code
2. Run `cljd-wait-reload` to confirm hot reload completed (or detect compilation errors)
3. Run `cljd-errors` to check for compile/runtime errors
4. Run `cljd-screenshot` and read the image to verify UI changes
5. Use `cljd-ui-tree` + `cljd-tap` to navigate the app
6. Fix issues and repeat

This gives Claude Code a full edit-verify-interact loop that previously required manual human verification at every step.

### Example: Claude Code fixing a UI bug

```
You:    "The login button is cut off on the right side, fix it"

Claude: *reads the .cljd file, adjusts padding*
        *runs cljd-wait-reload — Hot reload completed.*
        *runs cljd-errors — no errors*
        *runs cljd-screenshot — sees the button is now visible*
        "Fixed — I adjusted the horizontal padding from 8 to 16."
```

## Tool Details

### `cljd-screenshot`

```bash
cljd-screenshot                    # Resize to 800px height (default)
cljd-screenshot --scale 600        # Resize to 600px height
cljd-screenshot --full             # Keep original size
cljd-screenshot --output /tmp/x.png
```

Images are resized with `sips` (macOS built-in) to reduce token usage when Claude reads them.

### `cljd-build-log`

```bash
cljd-build-log                     # Last 50 lines (filtered)
cljd-build-log --errors            # Errors and warnings only
cljd-build-log --last 100          # Last 100 lines
cljd-build-log --since "Restarted application"
```

Requires `cljd-flutter` to be running in another terminal. Respects `.cljd-log-filter` (see Log Filtering below).

### `cljd-device-log`

```bash
cljd-device-log                    # Last 60 seconds
cljd-device-log --last 5m          # Last 5 minutes
cljd-device-log --level error      # Errors only
cljd-device-log --app "Runner"     # Filter by process name
```

App name is auto-detected from `pubspec.yaml` if present.

### `cljd-errors`

```bash
cljd-errors                        # Check both build log + device log
cljd-errors --build                # Build log only
cljd-errors --device               # Device log only
```

Error sources are prefixed: `[BUILD]`, `[DART]`, `[FLUTTER]`, `[RUNTIME]`, `[DEVICE]`, `[L10N]`.

Only checks from the last compilation start — old errors are not reported. Respects `.cljd-log-filter`.

### `cljd-wait-reload`

```bash
cljd-wait-reload                   # Wait up to 10s (default)
cljd-wait-reload --timeout 20      # Wait up to 20s
```

Detects already-completed reloads instantly by checking from the last compilation marker. Exit codes: 0 = reload detected, 1 = timeout, 2 = compilation error.

### `cljd-hot-restart`

Triggers a Flutter hot restart programmatically. Requires `cljd-flutter` to be running.

```bash
cljd-hot-restart                   # Restart and wait for completion (default 30s)
cljd-hot-restart --timeout 60      # Custom timeout
cljd-hot-restart --no-wait         # Fire and forget
```

This works by sending `R` to `cljd-flutter` via a named pipe (FIFO). Unlike hot reload (which happens automatically on file save), hot restart is needed when changes affect top-level definitions, `require`s, routing, or event handler registration.

### `cljd-ui-tree`

```bash
cljd-ui-tree                       # Full JSON tree
cljd-ui-tree --compact             # One line per element (recommended)
cljd-ui-tree --interactive         # Buttons and text fields only
```

`--compact` output:
```
[Button] "Login" (x:100 y:200 w:80 h:40)
[TextField] "Email" (x:50 y:300 w:200 h:44) value=""
[StaticText] "Welcome" (x:100 y:100 w:150 h:24)
```

### `cljd-tap`

```bash
cljd-tap 200 400                   # Tap at coordinates
cljd-tap --label "Login"           # Tap by accessibility label (partial match supported)
cljd-tap --id "login_button"       # Tap by accessibility identifier
```

`--label` first tries an exact match via AXe, then falls back to partial match by searching the accessibility tree for a label containing the given text.

### `cljd-swipe`

```bash
cljd-swipe up                      # Preset directions
cljd-swipe down
cljd-swipe left
cljd-swipe right
cljd-swipe 100 500 100 200         # Custom: from (100,500) to (100,200)
```

## Log Filtering

Build logs can be noisy with debug output. Create a `.cljd-log-filter` file in your project root (next to `pubspec.yaml`) to exclude matching lines from `cljd-build-log` and `cljd-errors` output.

Each line is a fixed string — any log line containing that string is excluded.

```
# .cljd-log-filter
flutter: [DEBUG] session/refresh-jwt
flutter: [DEBUG] Writing `session` to SharedPreferences
flutter: [DEBUG] Writing `user-id` to SharedPreferences
```

Since this file is project-specific and not typically committed, add it to your **global** gitignore:

```bash
echo '.cljd-log-filter' >> ~/.config/git/ignore
```

Or if you use `~/.gitignore_global`:

```bash
echo '.cljd-log-filter' >> ~/.gitignore_global
```

## How It Works

- **Screenshot**: `xcrun simctl io booted screenshot` + `sips --resampleHeight` for resize
- **Build log**: `tee` captures `clj -M:cljd flutter` output to `/tmp/cljd_build.log`
- **Hot restart**: FIFO (`/tmp/cljd_flutter_cmd`) merges external commands with terminal stdin into Flutter's stdin
- **Device log**: `xcrun simctl spawn booted log show` with predicate filtering
- **Error detection**: Scans from last compilation marker, checks build + device + l10n staleness
- **UI interaction**: [AXe](https://github.com/cameroncooke/axe) accessibility automation tool

## License

MIT
