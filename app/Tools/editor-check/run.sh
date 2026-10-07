#!/bin/bash
# Integration check of the editor host against the REAL bundled editor. NOT part of the app.
# WKWebView needs a real WebKit process, which the macOS command-line sandbox blocks: run this from a normal terminal.
# Usage: app/Tools/editor-check/run.sh [path/to/index.html] [--bridge-only]
set -e
cd "$(dirname "$0")/../../.."
export TMPDIR="${TMPDIR:-/tmp}"
export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-$TMPDIR/dailylog-clang-cache}"
mkdir -p "$CLANG_MODULE_CACHE_PATH"
OUT="${EC_TMP:-$TMPDIR}/dailylog-editor-check"
SRC=$(find app/Core app/UI -name '*.swift' ! -name GloamlogApp.swift | sort)   # the app minus its @main entry point
swiftc -swift-version 5 -module-cache-path "$CLANG_MODULE_CACHE_PATH" -target "$(uname -m)-apple-macos13.0" \
  $SRC app/Tools/editor-check/*.swift -o "$OUT"
EC_TMP="${EC_TMP:-$TMPDIR}" "$OUT" "${1:-app/Resources/editor/index.html}" "${@:2}"
