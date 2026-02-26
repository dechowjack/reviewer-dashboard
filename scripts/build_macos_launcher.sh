#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="${APP_NAME:-Reviewer Ticket Dashboard}"
OUT_DIR="${OUT_DIR:-$ROOT_DIR/dist}"
APP_PATH="$OUT_DIR/$APP_NAME.app"
INSTALL_TO_APPS="${INSTALL_TO_APPS:-1}"
APP_URL="${APP_URL:-http://127.0.0.1:8000}"
LOG_PATH="${LOG_PATH:-/tmp/reviewer_ticket_dashboard.log}"

CUSTOM_ICON_ICNS="$ROOT_DIR/assets/icons/reviewer_dashboard.icns"
CUSTOM_ICON_PNG="$ROOT_DIR/assets/icons/reviewer_dashboard_1024.png"
ICON_SOURCE="${ICON_SOURCE:-$CUSTOM_ICON_ICNS}"
ICON_FILE_NAME="AppIcon"
if [[ -f "$ICON_SOURCE" ]]; then
  if [[ "$ICON_SOURCE" == *.png ]]; then
    ICON_FILE_NAME="AppIcon.png"
  else
    ICON_FILE_NAME="AppIcon"
  fi
elif [[ -f "$CUSTOM_ICON_PNG" ]]; then
  ICON_SOURCE="$CUSTOM_ICON_PNG"
  ICON_FILE_NAME="AppIcon.png"
else
  ICON_SOURCE="/System/Applications/Safari.app/Contents/Resources/AppIcon.icns"
  ICON_FILE_NAME="AppIcon"
fi
if [[ ! -f "$ICON_SOURCE" ]]; then
  ICON_SOURCE="/System/Applications/Utilities/Terminal.app/Contents/Resources/Terminal.icns"
  ICON_FILE_NAME="AppIcon"
fi

rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS" "$APP_PATH/Contents/Resources"

cat > "$APP_PATH/Contents/Info.plist" <<EOF2
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>launcher</string>
  <key>CFBundleIconFile</key>
  <string>$ICON_FILE_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>local.reviewer.ticket.dashboard</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>11.0</string>
</dict>
</plist>
EOF2

cat > "$APP_PATH/Contents/MacOS/launcher" <<EOF2
#!/usr/bin/env bash
set -euo pipefail

APP_URL="$APP_URL"
PROJECT_ROOT="$ROOT_DIR"
LOG_PATH="$LOG_PATH"
STARTUP_COMMAND="$ROOT_DIR/startup.command"

if command -v curl >/dev/null 2>&1 && curl -fsS "\${APP_URL}/" >/dev/null 2>&1; then
  open "\$APP_URL"
  exit 0
fi

if [[ ! -x "\$STARTUP_COMMAND" ]]; then
  echo "startup.command missing or not executable at \$STARTUP_COMMAND" >"\$LOG_PATH"
  exit 1
fi

open -a Terminal "\$STARTUP_COMMAND" >/dev/null

started=0
if command -v curl >/dev/null 2>&1; then
  for _ in {1..120}; do
    if curl -fsS "\${APP_URL}/" >/dev/null 2>&1; then
      started=1
      break
    fi
    sleep 0.25
  done
fi

if [[ "\$started" == "1" ]]; then
  open "\$APP_URL"
  exit 0
fi

if [[ -f "\$LOG_PATH" ]]; then
  open -a TextEdit "\$LOG_PATH" || true
fi
exit 1
EOF2

chmod +x "$APP_PATH/Contents/MacOS/launcher"

if [[ -f "$ICON_SOURCE" ]]; then
  if [[ "$ICON_SOURCE" == *.png ]]; then
    cp "$ICON_SOURCE" "$APP_PATH/Contents/Resources/AppIcon.png"
  else
    cp "$ICON_SOURCE" "$APP_PATH/Contents/Resources/AppIcon.icns"
  fi
fi

if [[ "$INSTALL_TO_APPS" == "1" ]]; then
  mkdir -p "$HOME/Applications"
  rm -rf "$HOME/Applications/$APP_NAME.app"
  cp -R "$APP_PATH" "$HOME/Applications/$APP_NAME.app"
  echo "Installed launcher to: $HOME/Applications/$APP_NAME.app"
  echo "Tip: drag it to your Dock."
else
  echo "Built launcher at: $APP_PATH"
fi
