#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$ROOT_DIR/assets/icons"
mkdir -p "$OUT_DIR"

PNG_1024="$OUT_DIR/reviewer_dashboard_1024.png"
ICONSET_DIR="$OUT_DIR/reviewer_dashboard.iconset"
ICNS_OUT="$OUT_DIR/reviewer_dashboard.icns"
ICO_OUT="$OUT_DIR/reviewer_dashboard.ico"
SOURCE_PNG="$OUT_DIR/source.png"

if [[ -f "$SOURCE_PNG" ]]; then
  magick "$SOURCE_PNG" -background none -gravity center -resize 900x900 -extent 1024x1024 "PNG32:$PNG_1024"
else
  # Simple custom icon: board + ticket columns + chat bubble.
  magick -size 1024x1024 xc:none \
    -fill '#0b1220' -draw "roundrectangle 80,80 944,944 220,220" \
    -fill '#111b34' -draw "roundrectangle 105,105 919,919 180,180" \
    -fill '#22314d' -draw "roundrectangle 180,250 500,840 55,55" \
    -fill '#1b293f' -draw "roundrectangle 530,250 850,840 55,55" \
    -fill '#60a5fa' -draw "roundrectangle 210,290 470,335 24,24" \
    -fill '#34d399' -draw "roundrectangle 560,290 820,335 24,24" \
    -fill '#e5e7eb' -draw "roundrectangle 210,370 470,450 20,20" \
    -draw "roundrectangle 210,475 470,555 20,20" \
    -draw "roundrectangle 210,580 470,660 20,20" \
    -fill '#cbd5e1' -draw "roundrectangle 560,370 820,450 20,20" \
    -draw "roundrectangle 560,475 820,555 20,20" \
    -draw "roundrectangle 560,580 820,660 20,20" \
    -fill '#f59e0b' -draw "roundrectangle 380,115 760,290 75,75" \
    -fill '#1f2937' -draw "roundrectangle 420,155 720,250 50,50" \
    -fill '#f9fafb' -draw "roundrectangle 470,187 678,215 14,14" \
    -draw "roundrectangle 470,225 620,248 14,14" \
    "PNG32:$PNG_1024"
fi

rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

for size in 16 32 128 256 512; do
  sips -z "$size" "$size" "$PNG_1024" --out "$ICONSET_DIR/icon_${size}x${size}.png" >/dev/null
  double=$((size * 2))
  sips -z "$double" "$double" "$PNG_1024" --out "$ICONSET_DIR/icon_${size}x${size}@2x.png" >/dev/null
done

if iconutil -c icns "$ICONSET_DIR" -o "$ICNS_OUT"; then
  echo "Generated: $ICNS_OUT"
else
  echo "Warning: iconutil failed; PNG icon is still available for launcher fallback."
fi

if magick "$PNG_1024" \
  -define icon:auto-resize=16,24,32,48,64,128,256 \
  "$ICO_OUT"
then
  echo "Generated: $ICO_OUT"
else
  echo "Warning: failed to generate Windows .ico asset."
fi

echo "Generated: $PNG_1024"
