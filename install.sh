#!/usr/bin/env bash
set -euo pipefail

# install.sh - Install clojuredart-skills tools and Claude Code skill

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="$HOME/.local/bin"
SKILL_DIR="$HOME/.claude/skills"
SKILL_LINK="$SKILL_DIR/clojuredart-skills"

echo "=== ClojureDart Skills Installer ==="
echo ""

# 1. Check dependencies
echo "Checking dependencies..."
MISSING=()

if ! command -v xcrun &>/dev/null; then
  MISSING+=("xcrun (install Xcode Command Line Tools: xcode-select --install)")
fi

if ! command -v sips &>/dev/null; then
  MISSING+=("sips (should be included with macOS)")
fi

if ! command -v python3 &>/dev/null; then
  MISSING+=("python3 (should be included with macOS)")
fi

if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "ERROR: Missing required dependencies:" >&2
  for dep in "${MISSING[@]}"; do
    echo "  - $dep" >&2
  done
  exit 1
fi

echo "  xcrun: OK"
echo "  sips: OK"
echo "  python3: OK"

if command -v axe &>/dev/null; then
  echo "  axe: OK (UI interaction tools available)"
else
  echo "  axe: NOT FOUND (UI interaction tools will show install instructions)"
  echo "       Install: brew tap cameroncooke/axe && brew install axe"
fi

echo ""

# 2. Create ~/.local/bin if needed
mkdir -p "$BIN_DIR"

# 3. Symlink all tools
echo "Installing tools to $BIN_DIR..."
TOOLS=(
  cljd-screenshot
  cljd-flutter
  cljd-build-log
  cljd-device-log
  cljd-devices
  cljd-errors
  cljd-ui-tree
  cljd-tap
  cljd-swipe
  cljd-type
  cljd-key
  cljd-wait-reload
  cljd-hot-restart
)

for tool in "${TOOLS[@]}"; do
  SRC="$SCRIPT_DIR/bin/$tool"
  DST="$BIN_DIR/$tool"

  # Make executable
  chmod +x "$SRC"

  # Remove existing link/file
  rm -f "$DST"

  # Create symlink
  ln -s "$SRC" "$DST"
  echo "  $tool -> $DST"
done

echo ""

# 4. Create Claude Code skill symlink
echo "Installing Claude Code skill..."
mkdir -p "$SKILL_DIR"
rm -f "$SKILL_LINK"
ln -s "$SCRIPT_DIR" "$SKILL_LINK"
echo "  $SKILL_LINK -> $SCRIPT_DIR"

echo ""

# 5. Verify PATH
if ! echo "$PATH" | tr ':' '\n' | grep -qx "$BIN_DIR"; then
  echo "WARNING: $BIN_DIR is not in your PATH."
  echo "Add to your shell profile:"
  echo '  export PATH="$HOME/.local/bin:$PATH"'
  echo ""
fi

echo "Installation complete!"
echo ""
echo "Quick start:"
echo "  1. Start iOS Simulator: open -a Simulator"
echo "  2. In a separate terminal: cljd-flutter --flavor dev"
echo "  3. Check errors: cljd-errors"
echo "  4. Take screenshot: cljd-screenshot"
