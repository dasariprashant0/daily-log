#!/bin/bash
# Builds and runs the snapshot harness (never shipped). Usage: app/Tools/snapshot/run.sh [outdir] [--expanded]
set -e
cd "$(dirname "$0")/../.."
export TMPDIR="${TMPDIR:-/tmp}"
export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-$TMPDIR/dailylog-clang-cache}"
mkdir -p "$CLANG_MODULE_CACHE_PATH"
UI=$(ls UI/*.swift | grep -v GloamlogApp.swift)
swiftc -swift-version 5 -module-cache-path "$CLANG_MODULE_CACHE_PATH" -target "$(uname -m)-apple-macos13.0" \
  Core/*.swift $UI Tools/snapshot/main.swift -o "$TMPDIR/dailylog-snapshot"
"$TMPDIR/dailylog-snapshot" "${1:-$TMPDIR/dl-snap}" "${@:2}"
