#!/bin/bash
# Builds "Daily Log.app" + DailyLog.zip (shareable). Needs Xcode Command Line Tools only (no Xcode, no SwiftPM).
# A harmless "xcrun cache file" sandbox warning can be ignored. Usage: ./build.sh
set -e
cd "$(dirname "$0")"
export TMPDIR="${TMPDIR:-/tmp}"
export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-$TMPDIR/dailylog-clang-cache}"
mkdir -p "$CLANG_MODULE_CACHE_PATH"
APP="Daily Log.app"
rm -rf "$APP" DailyLog.zip
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

swiftc -O -parse-as-library -swift-version 5 -module-cache-path "$CLANG_MODULE_CACHE_PATH" \
  -target "$(uname -m)-apple-macos13.0" Core/*.swift UI/*.swift -o "$APP/Contents/MacOS/DailyLog"

cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>Daily Log</string>
<key>CFBundleDisplayName</key><string>Daily Log</string>
<key>CFBundleIdentifier</key><string>local.dailylog.app</string>
<key>CFBundleExecutable</key><string>DailyLog</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.2.0</string>
<key>CFBundleVersion</key><string>0.2.0</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>LSApplicationCategoryType</key><string>public.app-category.productivity</string>
<key>NSPrincipalClass</key><string>NSApplication</string>
<key>NSHighResolutionCapable</key><true/>
<key>NSUserNotificationAlertStyle</key><string>none</string>
</dict></plist>
PLIST

codesign --force --sign - "$APP"          # ad-hoc: runs locally, not notarised
ditto -c -k --keepParent "$APP" DailyLog.zip
echo "Built: $PWD/$APP and $PWD/DailyLog.zip"
