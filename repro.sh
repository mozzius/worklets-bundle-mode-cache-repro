#!/usr/bin/env bash
# Reproduces the Bundle Mode cache bug without a device: it only requests bundles from Metro.
#
#   1. Start Metro with a private, empty cache and request a bundle (fills the cache).
#   2. Delete the generated .worklets files, as a second checkout or a reinstall would leave them.
#   3. Start Metro again with the same cache and request the same bundle.
#
# Step 3 fails with ENOENT on react-native-worklets/.worklets/<hash>.js.
set -euo pipefail
cd "$(dirname "$0")"

PORT=${PORT:-8099}
PLATFORM=${PLATFORM:-ios}
export TMPDIR="$PWD/.metro-tmp"   # Metro's FileStore lives in $TMPDIR/metro-cache
rm -rf "$TMPDIR" && mkdir -p "$TMPDIR"
WORKLETS_DIR=node_modules/react-native-worklets/.worklets
URL="http://localhost:$PORT/index.bundle?platform=$PLATFORM&dev=true&minify=false"

bundle() {
  npx expo start --port "$PORT" </dev/null >"$TMPDIR/metro-$1.log" 2>&1 &
  local pid=$!
  until curl -s "localhost:$PORT/status" | grep -q running; do sleep 1; done
  # Retry a few times: on a cold start the first request can also fail, because Metro's
  # watcher hasn't seen the .worklets files the plugin just wrote (a separate race).
  local code attempt
  for attempt in 1 2 3 4 5; do
    code=$(curl -s -o "$TMPDIR/bundle-$1.js" -w '%{http_code}' "$URL")
    echo "$1, attempt $attempt: HTTP $code"
    [ "$code" = 200 ] && break
    sleep 2
  done
  if [ "$code" != 200 ]; then head -c 600 "$TMPDIR/bundle-$1.js"; echo; fi
  kill "$pid"; wait "$pid" 2>/dev/null || true
}

bundle first
echo "worklet files written: $(ls "$WORKLETS_DIR" | grep -c '\.js$')"
find "$WORKLETS_DIR" -name '*.js' -delete
echo "deleted them; Metro cache kept"
bundle second
