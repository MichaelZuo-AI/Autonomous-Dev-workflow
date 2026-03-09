#!/bin/bash
set -e

DEVICE_ID=$(xcrun simctl list devices | grep "iPhone 15 Pro" | grep Booted | awk -F'[()]' '{print $2}')

if [ -z "$DEVICE_ID" ]; then
  echo "❌ No booted iPhone 15 Pro found. Boot a simulator first:"
  echo "   xcrun simctl boot 'iPhone 15 Pro'"
  exit 1
fi

SCREENSHOT_PATH="/tmp/smoke-$(date +%s).png"
xcrun simctl screenshot "$DEVICE_ID" "$SCREENSHOT_PATH"
echo "✅ Screenshot saved: $SCREENSHOT_PATH"
