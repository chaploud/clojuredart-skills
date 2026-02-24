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

**User runs this in a separate terminal** — not for Claude to invoke directly.
It wraps `clj -M:cljd flutter` and captures output to `/tmp/cljd_build.log`.

```bash
cljd-flutter --flavor dev
cljd-flutter --flavor dev -d "iPhone 17 Pro"
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

Output is prefixed with source: `[BUILD]`, `[DART]`, `[FLUTTER]`, `[DEVICE]`.

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

## Important Notes

- **Never use `--follow` or `-f` flags** with any log commands. They block indefinitely.
- **Screenshot images** are read via the `Read` tool — Claude can view PNG images directly.
- **AXe tools** (ui-tree, tap, swipe, type, key) require `axe` to be installed.
  If missing: `brew tap cameroncooke/axe && brew install axe`
- **Build log** requires the user to be running `cljd-flutter` in another terminal.
  If `/tmp/cljd_build.log` doesn't exist, ask the user to start it.
- **Wait after edits**: Hot reload takes 2-5 seconds. Don't check errors immediately.
- **Coordinate system**: AXe uses logical points (not pixels). The coordinates from
  `cljd-ui-tree` output can be used directly with `cljd-tap`.
