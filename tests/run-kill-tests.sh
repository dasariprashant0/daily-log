#!/bin/bash
# Kill test: a child process saves pages through LogStore in a loop, the parent SIGKILLs it at a random 5-300 ms, 40 rounds,
# and checks that no day file is ever truncated, empty or rolled back, that at most one stray temp file exists and the next
# save removes it, and that backups are complete. Prints "40/40 rounds clean". Usage: tests/run-kill-tests.sh [--rounds N]
# Needs Xcode Command Line Tools only. Run it outside the Bash sandbox (it writes atomically into the system temp dir).
set -e
cd "$(dirname "$0")/.."
export TMPDIR="${TMPDIR:-/tmp}"
export CLANG_MODULE_CACHE_PATH="$TMPDIR/dailylog-clang-cache"
mkdir -p "$CLANG_MODULE_CACHE_PATH"
OUT="$TMPDIR/dailylog-kill-test-bin"
swiftc -swift-version 5 -module-cache-path "$CLANG_MODULE_CACHE_PATH" \
  -target "$(uname -m)-apple-macos13.0" $(find app/Core -name '*.swift' | sort) app/Tools/kill-test/main.swift -o "$OUT"
"$OUT" "$@"
