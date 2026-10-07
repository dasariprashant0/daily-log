#!/bin/bash
# Builds and runs the snapshot harness (never shipped). Usage: app/Tools/snapshot/run.sh [outdir] [--expanded]
set -e
cd "$(dirname "$0")/../.."
export TMPDIR="${TMPDIR:-/tmp}"
export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-$TMPDIR/dailylog-clang-cache}"
mkdir -p "$CLANG_MODULE_CACHE_PATH"
SRC=$(find Core UI -name '*.swift' ! -name GloamlogApp.swift | sort)   # the app minus its @main entry point
swiftc -swift-version 5 -module-cache-path "$CLANG_MODULE_CACHE_PATH" -target "$(uname -m)-apple-macos13.0" \
  $SRC Tools/snapshot/main.swift -o "$TMPDIR/dailylog-snapshot"
"$TMPDIR/dailylog-snapshot" "${1:-$TMPDIR/dl-snap}" "${@:2}"
