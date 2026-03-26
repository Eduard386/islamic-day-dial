#!/usr/bin/env bash
# Run iOS unit tests. Uses IOS_TEST_DESTINATION env for custom destination (e.g. CI).
set -euo pipefail

cd "$(dirname "$0")/../apps/apple-watch"

if [[ -n "${IOS_TEST_DESTINATION:-}" ]]; then
  DESTINATIONS=("$IOS_TEST_DESTINATION")
else
  DESTINATIONS=(
    "platform=iOS Simulator,name=iPhone 17,arch=arm64"
    "platform=iOS Simulator,name=iPhone 16,arch=arm64"
    "platform=iOS Simulator,name=iPhone 17 Pro,arch=arm64"
    "platform=iOS Simulator,name=iPhone SE (3rd generation),arch=arm64"
  )
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

is_launch_failure() {
  local log_file="$1"
  grep -Eq \
    "Simulator device failed to launch|Failed to install or launch the test runner|SBMainWorkspace|Launchd job spawn failed|RequestDenied|launch-failed" \
    "$log_file"
}

reset_simulators() {
  xcrun simctl shutdown all >/dev/null 2>&1 || true
}

run_tests_for_destination() {
  local destination="$1"
  local log_file="$2"
  xcodebuild test -scheme IslamicDayDial -destination "$destination" -quiet >"$log_file" 2>&1
}

for index in "${!DESTINATIONS[@]}"; do
  DEST="${DESTINATIONS[$index]}"

  for attempt in 1 2; do
    LOG_FILE="$TMP_DIR/ios-tests-${index}-${attempt}.log"
    echo "Running iOS tests on $DEST (attempt $attempt)..." >&2

    if run_tests_for_destination "$DEST" "$LOG_FILE"; then
      cat "$LOG_FILE"
      exit 0
    fi

    if ! is_launch_failure "$LOG_FILE"; then
      cat "$LOG_FILE" >&2
      exit 1
    fi

    if [[ "$attempt" == "1" ]]; then
      echo "Simulator launch failed on $DEST. Resetting simulator state and retrying once..." >&2
      reset_simulators
      sleep 2
    fi
  done

  if (( index < ${#DESTINATIONS[@]} - 1 )); then
    echo "Simulator launch kept failing on $DEST. Trying fallback destination..." >&2
    reset_simulators
    sleep 2
  fi
done

cat "$LOG_FILE" >&2
exit 1
