#!/bin/bash

# Script to check logs on the device

echo "Checking Rayhunter daemon logs..."
adb shell rootshell -c "'logcat -d | grep rayhunter'"
