#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_ICON="$ROOT_DIR/assets/icon/app_icon2.jpg"
ICON_DIR="$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset"
ANDROID_ICON_DIR="$ROOT_DIR/android/app/src/main/res"

if [[ ! -f "$SOURCE_ICON" ]]; then
  echo "Missing source icon: $SOURCE_ICON" >&2
  exit 1
fi

mkdir -p "$ICON_DIR"

generate_icon() {
  local size="$1"
  local filename="$2"
  sips -s format png -z "$size" "$size" "$SOURCE_ICON" --out "$ICON_DIR/$filename" >/dev/null
}

generate_icon 20 "Icon-App-20x20@1x.png"
generate_icon 40 "Icon-App-20x20@2x.png"
generate_icon 60 "Icon-App-20x20@3x.png"
generate_icon 29 "Icon-App-29x29@1x.png"
generate_icon 58 "Icon-App-29x29@2x.png"
generate_icon 87 "Icon-App-29x29@3x.png"
generate_icon 40 "Icon-App-40x40@1x.png"
generate_icon 80 "Icon-App-40x40@2x.png"
generate_icon 120 "Icon-App-40x40@3x.png"
generate_icon 120 "Icon-App-60x60@2x.png"
generate_icon 180 "Icon-App-60x60@3x.png"
generate_icon 76 "Icon-App-76x76@1x.png"
generate_icon 152 "Icon-App-76x76@2x.png"
generate_icon 167 "Icon-App-83.5x83.5@2x.png"
generate_icon 1024 "Icon-App-1024x1024@1x.png"

generate_android_icon() {
  local size="$1"
  local density="$2"
  sips -s format png -z "$size" "$size" "$SOURCE_ICON" \
    --out "$ANDROID_ICON_DIR/mipmap-$density/ic_launcher.png" >/dev/null
}

generate_android_icon 48 "mdpi"
generate_android_icon 72 "hdpi"
generate_android_icon 96 "xhdpi"
generate_android_icon 144 "xxhdpi"
generate_android_icon 192 "xxxhdpi"

sips -s format png -z 512 512 "$SOURCE_ICON" \
  --out "$ROOT_DIR/assets/icon/play_store_icon.png" >/dev/null

echo "Generated iOS and Android launcher icons from $SOURCE_ICON"
