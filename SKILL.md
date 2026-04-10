---
name: clojuredart-skills
description: >-
  iOS Simulator feedback loop for ClojureDart/Flutter development.
  Screenshot capture, build/device log reading, error detection,
  and UI interaction via AXe. Enables edit-reload-verify cycle.
globs:
  - "**/pubspec.yaml"
  - "**/*.cljd"
user-invocable: false
---

# ClojureDart iOS Simulator Feedback Loop

## Dependency Check

Check that core tools are available before use:

```
!which cljd-screenshot cljd-build-log cljd-errors cljd-devices
```

If not found, install from `~/Documents/MyProducts/clojuredart-skills/`:
```
!cd ~/Documents/MyProducts/clojuredart-skills && ./install.sh
```

## Development Feedback Loop

After editing `.cljd` files, follow this cycle to verify changes:

1. **Wait 2-5 seconds** after saving for hot reload to process
2. **Check for errors**: `cljd-errors`
3. **If errors found**: read the error details, fix the code, go to step 1
4. **If no errors**: take a screenshot and verify visually
   ```bash
   cljd-screenshot
   ```
   Then read the image:
   ```
   Read /tmp/cljd_screenshot.png
   ```
5. **If UI interaction needed**: get the UI tree, then tap/swipe/type
   ```bash
   cljd-ui-tree --compact
   cljd-tap X Y
   ```
6. **If runtime issues**: check device logs
   ```bash
   cljd-device-log --last 30s
   ```
7. **Repeat** from step 1

## Tools Reference

### Screenshot (`cljd-screenshot`)

Captures the booted iOS Simulator screen. Resizes for token efficiency.

```bash
cljd-screenshot                    # 800px height (default)
cljd-screenshot --scale 600        # 600px height
cljd-screenshot --full             # Original size
cljd-screenshot --output /tmp/x.png
```

Output path is printed to stdout. Use `Read` tool to view the image:
```
Read /tmp/cljd_screenshot.png
```

### Build Log (`cljd-build-log`)

Reads the build log captured by `cljd-flutter`. The user must be running
`cljd-flutter` in a separate terminal for logs to be available.

```bash
cljd-build-log                     # Last 50 lines
cljd-build-log --errors            # Errors and warnings only
cljd-build-log --last 100          # Last 100 lines
cljd-build-log --since "Restarted application"
```

If no build log exists, tell the user to run `cljd-flutter --flavor dev`
in a separate terminal.

### Build Wrapper (`cljd-flutter`)

Wraps `clj -M:cljd flutter` and captures output to `/tmp/cljd_build.log`.
Also unsets `CC` / `CXX` / `LD` / `AR` / `AS` from the inherited environment
before launching, to prevent host compiler env vars (e.g. a user-installed
`gcc-15`) from leaking into Xcode's CompileC phase and breaking pod native
code compilation.

**Preferred: tmux mode.** The wrapper can launch itself inside a detached
tmux session so that (a) the Flutter process survives the terminal the user
started it from, (b) humans can `tmux attach` to inspect interactively, and
(c) Claude can drive it remotely via `tmux send-keys` / `tmux capture-pane`.

```bash
cljd-flutter --tmux --flavor dev          # Start in detached tmux session 'cljdf'
cljd-flutter --tmux-replace --flavor dev  # Kill existing session, then start fresh
cljd-flutter --tmux-stop                  # Stop the session
cljd-flutter --tmux-attach                # Attach for interactive inspection
```

Inside tmux you can send keystrokes to Flutter's stdin without attaching:

```bash
tmux send-keys -t cljdf 'R' Enter         # Hot restart
tmux send-keys -t cljdf 'r' Enter         # Hot reload
tmux send-keys -t cljdf 'w' Enter         # Dump widget tree
tmux capture-pane -t cljdf -p | tail -40  # Snapshot current pane output
tmux has-session -t cljdf                 # Check if running
```

This makes Claude fully able to recover from broken builds autonomously
(kill + clean + restart) without asking the user to click around.

**Fallback: foreground mode (current terminal).** Still supported, and still
captures logs to `/tmp/cljd_build.log`, but if the Flutter subprocess crashes
the terminal is blocked and Claude can't restart it. The wrapper prints a
hint suggesting `--tmux` when run outside tmux.

```bash
cljd-flutter --flavor dev
cljd-flutter --flavor dev -d "iPhone 17 Pro"
CLJD_FLUTTER_TMUX_HINT=0 cljd-flutter --flavor dev   # Silence the hint
```

### Device Log (`cljd-device-log`)

Reads iOS Simulator system logs (print statements, runtime errors).

```bash
cljd-device-log                    # Last 60 seconds
cljd-device-log --last 5m          # Last 5 minutes
cljd-device-log --level error      # Errors only
cljd-device-log --app "Runner"     # Filter by app name
```

App name is auto-detected from `pubspec.yaml` when possible.

### Error Detection (`cljd-errors`)

Unified error check across build log and device log. Start here when
checking if something went wrong.

```bash
cljd-errors                        # Check both sources
cljd-errors --build                # Build log only
cljd-errors --device               # Device log only
```

Output is prefixed with source: `[BUILD]`, `[DART]`, `[FLUTTER]`, `[RUNTIME]`, `[DEVICE]`, `[L10N]`.

### Wait for Reload (`cljd-wait-reload`)

Blocks until Flutter hot reload/restart completes. Monitors the build log.

```bash
cljd-wait-reload                   # Wait up to 10s (default)
cljd-wait-reload --timeout 20      # Wait up to 20s
```

Detects already-completed reloads instantly (checks from last compilation marker).
Exit codes: 0 = reload detected, 1 = timeout, 2 = compilation error.
Use after editing `.cljd` files instead of `sleep`.

### Hot Restart (`cljd-hot-restart`)

Triggers a Flutter hot restart programmatically via the command pipe.
Requires `cljd-flutter` to be running in a separate terminal.

```bash
cljd-hot-restart                   # Restart and wait for completion (default 30s)
cljd-hot-restart --timeout 60      # Custom timeout
cljd-hot-restart --no-wait         # Fire and forget
```

Exit codes: 0 = restart completed, 1 = timeout, 2 = error.
Use when changes require hot restart (new `require`, top-level `def`s, `setup!`, routing).

### Simulator List (`cljd-devices`)

```bash
cljd-devices                       # All simulators
cljd-devices --booted              # Booted only
cljd-devices --json                # JSON output
```

### UI Tree (`cljd-ui-tree`) — requires AXe

Get the accessibility tree to find element coordinates for tapping.

```bash
cljd-ui-tree                       # Full tree
cljd-ui-tree --compact             # One line per element (recommended)
cljd-ui-tree --interactive         # Buttons and text fields only
```

`--compact` output format:
```
[Button] "Login" (x:100 y:200 w:80 h:40)
[TextField] "Email" (x:50 y:300 w:200 h:44) value=""
```

Use the x,y coordinates with `cljd-tap` to interact with elements.

### Tap (`cljd-tap`) — requires AXe

```bash
cljd-tap 200 400                   # Tap at (200, 400)
cljd-tap --label "Login"           # Tap by accessibility label
cljd-tap --id "login_button"       # Tap by accessibility identifier
```

Prefer `--label` when the element has a clear label — more reliable than coordinates.

### Swipe (`cljd-swipe`) — requires AXe

```bash
cljd-swipe up                      # Preset direction
cljd-swipe down
cljd-swipe left
cljd-swipe right
cljd-swipe 100 500 100 200         # Custom: from (100,500) to (100,200)
```

### Type (`cljd-type`) — requires AXe

```bash
cljd-type "hello@example.com"      # Type into focused field
```

Tap a text field first with `cljd-tap` to focus it.

### Key (`cljd-key`) — requires AXe

```bash
cljd-key home                      # Home button
cljd-key lock                      # Lock screen
```

## Log Filtering

Place a `.cljd-log-filter` file in the project root (next to `pubspec.yaml`).
Each line is a fixed string — log lines containing it are excluded from
`cljd-build-log` and `cljd-errors` output.

```
flutter: [DEBUG] session/refresh-jwt
flutter: [DEBUG] Writing `session` to SharedPreferences
```

## Agent Playbook: Driving `cljd-flutter` Over tmux

When the user runs `cljd-flutter --tmux --flavor dev`, the agent can
autonomously manage the Flutter process without blocking on human input.
This is the preferred path because a broken build would otherwise leave
the current terminal stuck.

### Health check

```bash
tmux has-session -t cljdf && echo running || echo not running
```

Treat a missing session as "nothing to drive" and ask the user (or start
a new one if the task allows it) to launch `cljd-flutter --tmux --flavor dev`.

### Read the current pane output

```bash
tmux capture-pane -t cljdf -p | tail -60
```

This is the authoritative "what is Flutter saying right now?" view. Prefer
this over `cljd-build-log` for the very latest in-progress state.
`cljd-build-log` is still the right place for searchable history.

### Inject keystrokes (send to Flutter stdin)

```bash
tmux send-keys -t cljdf 'r' Enter     # Hot reload
tmux send-keys -t cljdf 'R' Enter     # Hot restart
tmux send-keys -t cljdf 'w' Enter     # Dump widget tree
tmux send-keys -t cljdf 'p' Enter     # Toggle debugPaintSize
tmux send-keys -t cljdf 'q' Enter     # Quit flutter run
```

### Recovery playbook — "the build is broken and I can't reach it"

```bash
# 1. Stop the dead session (ignore error if already gone).
tmux kill-session -t cljdf 2>/dev/null || true

# 2. Clean caches that commonly cause breakage.
clj -M:cljd clean
fvm flutter clean      # or: flutter clean

# 3. Start a fresh tmux session.
cljd-flutter --tmux --flavor dev

# 4. Wait for the first build to finish, then verify.
#    cljd-flutter inside tmux tees to /tmp/cljd_build.log as usual.
cljd-wait-reload --timeout 120 || cljd-errors
```

Do NOT retry the same build repeatedly without cleaning first if the
error is a CompileC / kernel_snapshot / Podfile-level issue — those are
almost always stale state, not source bugs, and a clean rebuild resolves
them without code changes.

### Debugging workflow tip

To "step through" an issue without losing context:

```bash
tmux capture-pane -t cljdf -p -S -500 > /tmp/pane.txt  # last 500 lines
```

This gives the agent a full transcript to grep through, without being
noisy about ANSI escapes or needing to attach.

## Important Notes

- **Never use `--follow` or `-f` flags** with any log commands. They block indefinitely.
- **Screenshot images** are read via the `Read` tool — Claude can view PNG images directly.
- **AXe tools** (ui-tree, tap, swipe, type, key) require `axe` to be installed.
  If missing: `brew tap cameroncooke/axe && brew install axe`
- **Build log** requires the user to be running `cljd-flutter` in another terminal.
  If `/tmp/cljd_build.log` doesn't exist, ask the user to start it.
- **Wait after edits**: Hot reload takes 2-5 seconds. Don't check errors immediately.
- **Hot restart required**: When changes affect top-level `def`s, event handler
  registration (`setup!`), routing, or new `require`s, hot reload is insufficient.
  Use `cljd-hot-restart` to trigger a hot restart programmatically:
  ```bash
  cljd-hot-restart
  ```
  If the command pipe is not available (cljd-flutter started without FIFO support),
  fall back to asking the user to press `R` in the cljd-flutter terminal.
- **Coordinate system**: AXe uses logical points (not pixels). The coordinates from
  `cljd-ui-tree` output can be used directly with `cljd-tap`.
- **Host compiler env vars (CC / CXX)**: `cljd-flutter` unsets these before
  launching. If you see Xcode CompileC errors like
  `gcc-15: error: unrecognized command-line option '-target'`, the cause is
  almost always `CC` pointing at a non-clang compiler that's been inherited
  from the parent shell (nix-darwin, direnv, home-manager, etc.). The wrapper
  handles this, but if you invoke `clj -M:cljd flutter` or `fvm flutter build`
  directly, you must `env -u CC -u CXX ...` yourself.
