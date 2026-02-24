#!/usr/bin/env bash
set -euo pipefail

# uninstall.sh - Remove clojuredart-skills tools and Claude Code skill

BIN_DIR="$HOME/.local/bin"
SKILL_LINK="$HOME/.claude/skills/clojuredart-skills"

echo "=== ClojureDart Skills Uninstaller ==="
echo ""

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
)

echo "Removing tools from $BIN_DIR..."
for tool in "${TOOLS[@]}"; do
  DST="$BIN_DIR/$tool"
  if [[ -L "$DST" || -f "$DST" ]]; then
    rm -f "$DST"
    echo "  Removed $tool"
  fi
done

echo ""

echo "Removing Claude Code skill link..."
if [[ -L "$SKILL_LINK" ]]; then
  rm -f "$SKILL_LINK"
  echo "  Removed $SKILL_LINK"
else
  echo "  Not found (already removed)"
fi

echo ""

# Clean up temp files
echo "Cleaning up temp files..."
rm -f /tmp/cljd_screenshot.png /tmp/cljd_screenshot_raw.png
rm -f /tmp/cljd_build.log /tmp/cljd_flutter.pid
echo "  Done"

echo ""
echo "Uninstallation complete."
