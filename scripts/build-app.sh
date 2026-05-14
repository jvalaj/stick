#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Stick"
EXECUTABLE_NAME="StickyNotes"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
DMG_STAGING_DIR="$DIST_DIR/dmg"
DMG_RW="$DIST_DIR/$APP_NAME-rw.dmg"
DMG_FINAL="$DIST_DIR/$APP_NAME.dmg"
ICON_FILE="$ROOT_DIR/packaging/assets/Stick.icns"
DMG_BACKGROUND="$ROOT_DIR/packaging/assets/dmg-background.png"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

cd "$ROOT_DIR"

rm -rf "$APP_DIR" "$DMG_STAGING_DIR" "$DIST_DIR/$APP_NAME.zip" "$DMG_RW" "$DMG_FINAL"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

swift build -c release
cp "$ROOT_DIR/.build/release/$EXECUTABLE_NAME" "$MACOS_DIR/$APP_NAME"
cp "$ICON_FILE" "$RESOURCES_DIR/Stick.icns"

cat > "$CONTENTS_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>Stick</string>
  <key>CFBundleIdentifier</key>
  <string>com.jvalaj.stick</string>
  <key>CFBundleIconFile</key>
  <string>Stick</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>Stick</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>26.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

chmod +x "$MACOS_DIR/$APP_NAME"

codesign --force --deep --sign - "$APP_DIR"

(
  cd "$DIST_DIR"
  ditto -c -k --keepParent "$APP_NAME.app" "$APP_NAME.zip"
)

mkdir -p "$DMG_STAGING_DIR"
cp -R "$APP_DIR" "$DMG_STAGING_DIR/$APP_NAME.app"
hdiutil create \
  -volname "$APP_NAME" \
  -size 20m \
  -ov \
  -fs HFS+ \
  "$DMG_RW" >/dev/null

MOUNT_DIR="$(mktemp -d)"
hdiutil attach "$DMG_RW" -readwrite -noverify -noautoopen -mountpoint "$MOUNT_DIR" >/dev/null
cp -R "$DMG_STAGING_DIR/$APP_NAME.app" "$MOUNT_DIR/$APP_NAME.app"
ln -s /Applications "$MOUNT_DIR/Applications"
mkdir -p "$MOUNT_DIR/.background"
cp "$DMG_BACKGROUND" "$MOUNT_DIR/.background/background.png"
chflags hidden "$MOUNT_DIR/.background" || true
osascript <<APPLESCRIPT >/dev/null
tell application "Finder"
  set dmgFolder to POSIX file "$MOUNT_DIR" as alias
  set backgroundFile to POSIX file "$MOUNT_DIR/.background/background.png" as alias
  open dmgFolder
  set containerWindow to container window of dmgFolder
  set current view of containerWindow to icon view
  set toolbar visible of containerWindow to false
  set statusbar visible of containerWindow to false
  set bounds of containerWindow to {100, 100, 760, 500}
  set viewOptions to the icon view options of containerWindow
  set arrangement of viewOptions to not arranged
  set icon size of viewOptions to 144
  set background picture of viewOptions to backgroundFile
  set position of item "$APP_NAME.app" of dmgFolder to {170, 205}
  set position of item "Applications" of dmgFolder to {490, 205}
  close containerWindow
  open dmgFolder
  update dmgFolder without registering applications
  delay 1
end tell
APPLESCRIPT
cp "$ICON_FILE" "$MOUNT_DIR/.VolumeIcon.icns"
SetFile -a C "$MOUNT_DIR"
hdiutil detach "$MOUNT_DIR" -quiet
rmdir "$MOUNT_DIR"
rm -rf "$DMG_STAGING_DIR"
hdiutil convert "$DMG_RW" -format UDZO -imagekey zlib-level=9 -o "$DMG_FINAL" >/dev/null
rm -f "$DMG_RW"

echo "Built $APP_DIR"
echo "Built $DIST_DIR/$APP_NAME.zip"
echo "Built $DMG_FINAL"
