#!/bin/bash

# Script to check the status of the rayhunter-daemon on the embedded Linux device
# Note: The daemon can only be started/restarted by rebooting the device

echo "Checking rayhunter-daemon status on device"
echo "========================================"
echo "Note: If daemon is not running, you need to reboot the device"
echo "      Use: adb shell rootshell -c \"'reboot'\""
echo ""

# Check if ADB is available
if ! command -v adb &> /dev/null; then
    echo "Error: ADB is required but not installed"
    exit 1
fi

# Check if device is connected
echo "Checking device connection..."
if ! adb devices | grep -q "device$"; then
    echo "Error: No device connected or device not authorized"
    echo "Please connect a device and ensure it's authorized for ADB"
    exit 1
fi

# Check if daemon is running (BusyBox compatible)
echo "Checking if daemon is running..."
PROCESS_INFO=$(adb shell rootshell -c "'ps | grep rayhunter-daemon | grep -v grep'")

if [[ -z "$PROCESS_INFO" ]]; then
    echo "❌ rayhunter-daemon is NOT running"
else
    echo "✅ rayhunter-daemon is running:"
    echo "$PROCESS_INFO"
    
    # Get more detailed info (BusyBox compatible)
    PID=$(echo "$PROCESS_INFO" | awk '{print $1}')
    echo ""
    echo "Process details:"
    adb shell rootshell -c "'cat /proc/$PID/status'" | grep -E "Name|State|Pid|PPid|VmSize|VmRSS"
fi

# Check system resources (BusyBox compatible)
echo ""
echo "System resources:"
adb shell rootshell -c "'free'"
echo ""
adb shell rootshell -c "'df | grep -E \"/data\"'"

# Check logs (BusyBox compatible)
echo ""
echo "Recent logs (last 10 lines):"
adb shell rootshell -c "'logcat -d | grep rayhunter | busybox tail -n 10'"
