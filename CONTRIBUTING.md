# Contributing to Gloamlog

Thanks for helping. Gloamlog is a small, local-only macOS app, and the aim is to keep it that way.

## Build

Needs macOS 13+ and Xcode Command Line Tools (`xcode-select --install`).

```bash
bash app/build.sh
```

This produces `app/Gloamlog.app` and `app/Gloamlog.zip`.

## Test

```bash
bash tests/run-tests.sh
```

Run it before every PR. New logic in `app/Core/` should come with a test.

## Project layout

See [docs/FILE_STRUCTURE.md](docs/FILE_STRUCTURE.md). Design background is in [docs/PRD.md](docs/PRD.md), [docs/TRD.md](docs/TRD.md) and [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Constraints

- **macOS 13+** is the deployment target. Do not use APIs newer than that without an availability check.
- **No Swift macros.** The app must build with Command Line Tools alone (plain `swiftc`, no Xcode project, no SwiftPM macro targets). CI runs on runners that have full Xcode, so a macro would compile there but break local builds. Do not rely on CI to catch it.
- **No network, no telemetry, no crash reporting.** Nothing leaves the user's machine. PRs that add network calls will not be merged.
- **No third-party dependencies.** Apple frameworks and the Swift standard library only.
- Logs stay plain markdown at `~/Gloamlog/YYYY-MM-DD.md` (or the user's chosen folder).

## Pull request checklist

- [ ] `bash app/build.sh` succeeds
- [ ] `bash tests/run-tests.sh` passes
- [ ] New behaviour has a test, or the PR says why not
- [ ] No macros, no new dependencies, no network access
- [ ] Docs updated if behaviour or structure changed
- [ ] `CHANGELOG.md` has an entry for user-visible changes

## Commit style

Short imperative subject, 72 characters or fewer, for example `Fix streak count across skipped days`. Use [Conventional Commits](https://www.conventionalcommits.org/) prefixes (`feat:`, `fix:`, `docs:`, `test:`, `ci:`, `chore:`) if you like; they are welcome but not required. Explain the why in the body when it is not obvious. One logical change per commit.

## Reporting bugs and ideas

Use the issue templates. For security problems, see [SECURITY.md](SECURITY.md) and do not open a public issue.

By contributing you agree your work is licensed under the [MIT License](LICENSE). Please follow the [Code of Conduct](CODE_OF_CONDUCT.md).
