#!/bin/bash
# Daily log nagger. Usage: daily-log.sh [install]
# Opens a Notion-style page (daily-log.py) in the browser; every box is required.
DIR="$HOME/daily-log"; FILE="$DIR/$(date +%F).md"; PLIST="$HOME/Library/LaunchAgents/com.user.dailylog.plist"
HOUR=16; MIN=55  # Mon-Fri, 24h clock; ponytail: fixed time, change here

if [ "$1" = install ]; then
  mkdir -p "$DIR" "$(dirname "$PLIST")"; cp "$0" "$DIR/daily-log.sh"; cp "$(dirname "$0")/daily-log.py" "$DIR/"; chmod +x "$DIR/daily-log.sh"
  cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>Label</key><string>com.user.dailylog</string>
<key>ProgramArguments</key><array><string>$DIR/daily-log.sh</string></array>
<key>StartCalendarInterval</key><array>
$(for d in 1 2 3 4 5; do echo "<dict><key>Weekday</key><integer>$d</integer><key>Hour</key><integer>$HOUR</integer><key>Minute</key><integer>$MIN</integer></dict>"; done)
</array>
</dict></plist>
EOF
  launchctl unload "$PLIST" 2>/dev/null; launchctl load "$PLIST"
  echo "Installed: runs Mon-Fri at $HOUR:$MIN, logs in $DIR"; exit
fi

exec /usr/bin/python3 "$DIR/daily-log.py"  # opens the page; exits if today is already logged
