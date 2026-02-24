# ClojureDart Skills - iOS Simulator Feedback Loop

Claude Code skill for ClojureDart/Flutter mobile development. Provides tools to close the feedback loop between code edits and visual/runtime verification on the iOS Simulator.

```
Edit .cljd → (hot reload) → Check build log → Screenshot → UI操作 → 繰り返し
```

## Install

```bash
./install.sh
```

This will:
1. Check dependencies (xcrun, sips, python3)
2. Symlink tools to `~/.local/bin/`
3. Register as a Claude Code skill at `~/.claude/skills/clojuredart-skills`

Make sure `~/.local/bin` is in your PATH:
```bash
export PATH="$HOME/.local/bin:$PATH"
```

## Uninstall

```bash
./uninstall.sh
```

## Dependencies

| Tool | Required | Source |
|------|----------|--------|
| `xcrun simctl` | Yes | Xcode Command Line Tools |
| `sips` | Yes | macOS built-in |
| `python3` | Yes | macOS built-in |
| `axe` | Optional | `brew tap cameroncooke/axe && brew install axe` |

Without AXe, screenshot/log/error tools work. AXe enables UI interaction (tap, swipe, type) and accessibility tree inspection.

## Tools

### Core (no AXe required)

| Tool | Purpose |
|------|---------|
| `cljd-screenshot` | Capture simulator screenshot (auto-resized) |
| `cljd-flutter` | Build wrapper with log capture (run in separate terminal) |
| `cljd-build-log` | Read/filter build logs |
| `cljd-device-log` | Read iOS device logs (print, runtime errors) |
| `cljd-devices` | List simulators |
| `cljd-errors` | Unified error check (build + device logs) |

### UI Interaction (requires AXe)

| Tool | Purpose |
|------|---------|
| `cljd-ui-tree` | Accessibility tree (find element coordinates) |
| `cljd-tap` | Tap at coordinates |
| `cljd-swipe` | Swipe (directional or coordinate-based) |
| `cljd-type` | Type text into focused field |
| `cljd-key` | Press hardware keys (home, lock) |

## Quick Start

1. Start a simulator:
   ```bash
   open -a Simulator
   ```

2. In a **separate terminal**, start the build:
   ```bash
   cljd-flutter --flavor dev
   ```

3. Check for errors:
   ```bash
   cljd-errors
   ```

4. Take a screenshot:
   ```bash
   cljd-screenshot
   # Output: /tmp/cljd_screenshot.png
   ```

5. (With AXe) Inspect and interact with UI:
   ```bash
   cljd-ui-tree --compact
   cljd-tap 200 400
   ```

## How It Works with Claude Code

When working in a ClojureDart project (has `pubspec.yaml` or `.cljd` files), the SKILL.md is automatically loaded. Claude Code can then:

1. Edit `.cljd` code
2. Wait for hot reload
3. Run `cljd-errors` to check for compile/runtime errors
4. Run `cljd-screenshot` and read the image to verify UI
5. Use `cljd-ui-tree` + `cljd-tap` to navigate the app
6. Fix issues and repeat

This closes the feedback loop that previously required manual verification.
