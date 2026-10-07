# Security Policy

## Supported versions

Only the latest release receives fixes.

| Version | Supported |
| ------- | --------- |
| Latest release | Yes |
| Older releases | No |

## Reporting a vulnerability

Please do not open a public issue. Use GitHub's private vulnerability reporting: go to the repository's **Security** tab and choose **Report a vulnerability** (or open <https://github.com/dasariprashant0/gloamlog/security/advisories/new>). Include the version, macOS version, steps to reproduce and the impact you expect. You will get a reply as soon as the maintainer can, usually within a week.

## Security model

- Gloamlog is local-only. It makes no network calls and sends no telemetry. Logs are plain markdown files on your disk.
- Release builds are ad-hoc signed and not notarised, so macOS Gatekeeper will warn on first launch. Verify you downloaded the zip from this repository's Releases page. You can also build from source with `bash app/build.sh` and inspect the code.
- The app registers as a login item so reminders can fire; remove it in System Settings, General, Login Items.

Reports about the lack of notarisation itself are a known limitation, not a vulnerability.
