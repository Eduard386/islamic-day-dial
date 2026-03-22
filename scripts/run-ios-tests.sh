#!/usr/bin/env bash
# Run iOS unit tests. Uses IOS_TEST_DESTINATION env for custom destination (e.g. CI).
set -e
cd "$(dirname "$0")/../apps/apple-watch"
DEST="${IOS_TEST_DESTINATION:-platform=iOS Simulator,name=iPhone 16,OS=18.3.1}"
xcodebuild test -scheme IslamicDayDial -destination "$DEST" -quiet
