#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="${APP_NAME:-Reviewer Ticket Dashboard}"
OUT_DIR="${OUT_DIR:-$ROOT_DIR/dist}"
APP_PATH="${APP_PATH:-$OUT_DIR/$APP_NAME.app}"
DMG_NAME="${DMG_NAME:-$APP_NAME.dmg}"
DMG_PATH="${OUT_DIR}/${DMG_NAME}"
WORK_DIR="${WORK_DIR:-$ROOT_DIR/.dmg-work}"

if [[ ! -d "$APP_PATH" ]]; then
  echo "Missing app bundle at: $APP_PATH"
  echo "Run: make desktop-build"
  exit 1
fi

if ! command -v hdiutil >/dev/null 2>&1; then
  echo "hdiutil is required to build .dmg (macOS only)."
  exit 1
fi

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

STAGING_DIR="$WORK_DIR/staging"
mkdir -p "$STAGING_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

rm -f "$DMG_PATH"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDBZ \
  "$DMG_PATH"

rm -rf "$WORK_DIR"
echo "Built macOS DMG: $DMG_PATH"
echo "Distribute this file for easy drag-and-drop install."
