#!/bin/bash
# Compiles app/Core/*.swift + tests/main.swift and runs the assert-based tests. Run from anywhere.
# Needs Xcode Command Line Tools only. A harmless "xcrun cache" sandbox warning can be ignored.
set -e
cd "$(dirname "$0")/.."
export TMPDIR="${TMPDIR:-/tmp}"
export CLANG_MODULE_CACHE_PATH="$TMPDIR/dailylog-clang-cache"
mkdir -p "$CLANG_MODULE_CACHE_PATH"
OUT="$TMPDIR/dailylog-tests-bin"
swiftc -swift-version 5 -module-cache-path "$CLANG_MODULE_CACHE_PATH" \
  -target "$(uname -m)-apple-macos13.0" $(find app/Core -name '*.swift' | sort) tests/main.swift -o "$OUT"
"$OUT"
