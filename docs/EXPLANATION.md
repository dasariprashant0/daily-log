# How it works (plain language)

1. **You open the app** (or it opens itself at login). A window shows today's page with five empty boxes.
2. **You fill in all five.** The Save button stays greyed out and shows "3/5 filled" until every box has text.
3. **You press Save.** The app writes one markdown file for the day to `~/Gloamlog/`, for example `~/Gloamlog/2026-10-06.md`. Each box becomes a `##` heading with your text under it.
4. **The sidebar** lists every past day with a tick if it was fully logged. Click one to read or edit it.
5. **The nag:** the app keeps running in the background after you close the window. Once a minute it checks three things: is it a weekday, is it past your reminder time, and is today unsaved? If all three are true it brings the window to the front. Close it without saving and it reappears on a later check.
6. **Reminder time** is the "Remind me at" picker at the bottom of the page (default 4:55pm).

## Good to know
- Everything is local. There is no account, sync or network access.
- Your Mac must be on and the app running for the reminder to fire (the app registers itself to start at login).
- Don't start a line of your own text with `## `, because the file format uses it to separate sections.
- To stop it: ⌘Q, and remove it under System Settings → General → Login Items.
- The app isn't notarised by Apple, so the first launch needs right-click → Open.

There is also an older script version (`daily-log.sh` + `daily-log.py`) that opens the same form in your browser instead of a native window.
