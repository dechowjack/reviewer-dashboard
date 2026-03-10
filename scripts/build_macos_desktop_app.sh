#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="${APP_NAME:-Reviewer Ticket Dashboard}"
OUT_DIR="${OUT_DIR:-$ROOT_DIR/dist}"
BUILD_WORK_DIR="${ROOT_DIR}/.pyinstaller-build"

if ! command -v pyinstaller >/dev/null 2>&1; then
  echo "pyinstaller is required. Install with: pip install pyinstaller"
  exit 1
fi

ICON_PATH="${ROOT_DIR}/assets/icons/reviewer_dashboard.icns"
if [[ ! -f "$ICON_PATH" ]]; then
  ICON_PATH="${ROOT_DIR}/assets/icons/reviewer_dashboard_1024.png"
fi
if [[ ! -f "$ICON_PATH" ]]; then
  ICON_PATH=""
fi

rm -rf "$BUILD_WORK_DIR"
mkdir -p "$BUILD_WORK_DIR" "$OUT_DIR"

pyinstaller \
  ${ICON_PATH:+--icon "$ICON_PATH"} \
  --name "$APP_NAME" \
  --distpath "$OUT_DIR" \
  --workpath "$BUILD_WORK_DIR" \
  --add-data "$ROOT_DIR/app/static:app/static" \
  --add-data "$ROOT_DIR/app/templates:app/templates" \
  --collect-submodules app \
  --hidden-import webview \
  --clean \
  --noconfirm \
  --windowed \
  "$ROOT_DIR/app/desktop.py"

echo "Built desktop app: $OUT_DIR/$APP_NAME.app"
