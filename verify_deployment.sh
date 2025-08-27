#!/bin/bash
# Script to verify the deployment of binaries

echo "Checking rayhunter-daemon..."
adb shell "if [ -f /data/rayhunter/rayhunter-daemon ]; then echo 'rayhunter-daemon exists'; ls -la /data/rayhunter/rayhunter-daemon; else echo 'rayhunter-daemon NOT FOUND'; fi"

echo ""
echo "Checking gps_jwt_pin..."
adb shell "if [ -f /data/rayhunter/tools/gps_jwt_pin ]; then echo 'gps_jwt_pin exists'; ls -la /data/rayhunter/tools/gps_jwt_pin; else echo 'gps_jwt_pin NOT FOUND'; fi"

echo ""
echo "Checking if daemon is running..."
adb shell "ps | grep rayhunter-daemon"

echo ""
echo "Checking system stats API..."
adb shell "wget -qO- http://127.0.0.1:8080/api/system-stats"
