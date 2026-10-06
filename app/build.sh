#!/bin/bash
# Builds "Daily Log.app" + DailyLog.zip (shareable). Needs Xcode Command Line Tools. Usage: ./build.sh
set -e
cd "$(dirname "$0")"
APP="Daily Log.app"
rm -rf "$APP" DailyLog.zip
mkdir -p "$APP/Contents/MacOS"

swiftc -O -parse-as-library -swift-version 5 -target "$(uname -m)-apple-macos13.0" DailyLog.swift -o "$APP/Contents/MacOS/DailyLog"

cat > "$APP/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>Daily Log</string>
<key>CFBundleDisplayName</key><string>Daily Log</string>
<key>CFBundleIdentifier</key><string>local.dailylog.app</string>
<key>CFBundleExecutable</key><string>DailyLog</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>NSPrincipalClass</key><string>NSApplication</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
EOF

codesign --force --sign - "$APP"          # ad-hoc: runs locally, not notarised
ditto -c -k --keepParent "$APP" DailyLog.zip
echo "Built: $PWD/$APP and $PWD/DailyLog.zip"
