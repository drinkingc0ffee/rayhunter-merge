#!/bin/bash
# Script to run the debug daemon

# Kill any existing daemon
adb shell "rootshell pkill -9 rayhunter-daemon"

# Push the updated daemon to /tmp
adb push target/armv7-unknown-linux-musleabihf/release/rayhunter-daemon /tmp/rayhunter-daemon-debug

# Run the daemon from /tmp
adb shell "rootshell chmod 755 /tmp/rayhunter-daemon-debug && rootshell /tmp/rayhunter-daemon-debug /data/rayhunter/config.toml &"

# Check if the daemon is running
sleep 2
adb shell "ps | grep rayhunter"
