#!/bin/bash
# Usage: ./run.sh [android|ios|web]  (default: android)
set -e
PLATFORM="${1:-android}"

# Prints a numbered menu from "id\tname" lines and echoes the chosen id.
# Auto-picks with no prompt when there's only one.
pick_device() {
  local list="$1"
  if [ -z "$list" ]; then
    echo "No $PLATFORM device found. Connect one or start an emulator/simulator." >&2
    exit 1
  fi

  local count
  count=$(echo "$list" | wc -l | tr -d ' ')
  if [ "$count" -eq 1 ]; then
    echo "$list" | cut -f1
    return
  fi

  echo "Available $PLATFORM devices:" >&2
  local i=1
  while IFS=$'\t' read -r id name; do
    echo "  $i) $name" >&2
    i=$((i + 1))
  done <<< "$list"
  read -r -p "Pick a device [1-$((i - 1))]: " choice </dev/tty
  local device_id
  device_id=$(echo "$list" | sed -n "${choice}p" | cut -f1)
  if [ -z "$device_id" ]; then
    echo "Invalid choice." >&2
    exit 1
  fi
  echo "$device_id"
}

case "$PLATFORM" in
  web)
    exec flutter run -d chrome --web-port=3000 --debug
    ;;
  ios)
    # flutter devices only reports currently-booted simulators; simctl lists
    # every simulator regardless of state. A shutdown one still has to be
    # booted explicitly first — flutter run does NOT boot it for you.
    LIST=$(xcrun simctl list devices available 2>/dev/null | sed -nE 's/^[[:space:]]+(.*) \(([0-9A-Fa-f-]+)\) \((Booted|Shutdown)\).*/\2\t\1 [\3]/p')
    DEVICE_ID=$(pick_device "$LIST")
    if ! xcrun simctl list devices booted 2>/dev/null | grep -q "$DEVICE_ID"; then
      echo "Booting simulator..."
      open -a Simulator >/dev/null 2>&1 || true
      xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true
      xcrun simctl bootstatus "$DEVICE_ID" >/dev/null 2>&1 || true
    fi
    exec flutter run -d "$DEVICE_ID"
    ;;
  android)
    LIST=$(flutter devices --machine 2>/dev/null | python3 -c "
import json, sys
devs = json.load(sys.stdin)
match = [d for d in devs if d['targetPlatform'].startswith('android')]
for d in match:
    print(f\"{d['id']}\t{d['name']}\")
")
    DEVICE_ID=$(pick_device "$LIST")
    exec flutter run -d "$DEVICE_ID"
    ;;
  *)
    echo "Usage: ./run.sh [android|ios|web]"
    exit 1
    ;;
esac
