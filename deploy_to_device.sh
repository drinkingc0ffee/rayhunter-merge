#!/bin/bash

# Deploy script for Rayhunter daemon to embedded device
# This script will build the daemon, copy it to the device, and reboot

echo "Rayhunter Daemon Deployment Script"
echo "=================================="

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

# Build the daemon using Docker
echo "Building daemon for target architecture using Docker..."
docker exec -it orbic-aug-25-25-container cargo build --release --target="armv7-unknown-linux-musleabihf" --bin rayhunter-daemon
if [ $? -ne 0 ]; then
    echo "Build failed. Exiting."
    exit 1
fi

# Get the built binary path from Docker container
echo "Copying binary from Docker container..."
docker cp orbic-aug-25-25-container:/workdir/target/armv7-unknown-linux-musleabihf/release/rayhunter-daemon ./rayhunter-daemon
if [ $? -ne 0 ]; then
    echo "Failed to copy binary from Docker container. Exiting."
    exit 1
fi

# Set the binary path
BINARY_PATH="./rayhunter-daemon"
if [ ! -f "$BINARY_PATH" ]; then
    echo "Error: Built binary not found at $BINARY_PATH"
    exit 1
fi

# Calculate MD5 for verification
echo "Calculating MD5 of built binary..."
BINARY_MD5=$(md5sum "$BINARY_PATH" | awk '{print $1}')
echo "Binary MD5: $BINARY_MD5"

# Copy binary to device
echo "Copying binary to device..."
adb push "$BINARY_PATH" /tmp/rayhunter-daemon
if [ $? -ne 0 ]; then
    echo "Failed to copy binary to device"
    exit 1
fi

# Move binary to final location with rootshell
echo "Moving binary to final location..."
adb shell rootshell -c "'mount -o rw,remount /'"
adb shell rootshell -c "'cp /tmp/rayhunter-daemon /data/rayhunter/rayhunter-daemon'"
adb shell rootshell -c "'chmod 755 /data/rayhunter/rayhunter-daemon'"
adb shell rootshell -c "'rm /tmp/rayhunter-daemon'"

# Verify MD5 on device
echo "Verifying binary MD5 on device..."
DEVICE_MD5=$(adb shell rootshell -c "'md5sum /data/rayhunter/rayhunter-daemon'" | awk '{print $1}')
echo "Device MD5: $DEVICE_MD5"

if [ "$BINARY_MD5" != "$DEVICE_MD5" ]; then
    echo "Warning: MD5 mismatch between built binary and device binary"
    echo "Built:  $BINARY_MD5"
    echo "Device: $DEVICE_MD5"
    read -p "Continue with reboot anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Deployment aborted"
        exit 1
    fi
fi

# Create debug HTML file for testing
echo "Creating debug HTML file..."
cat > debug_sse_minimal.html << 'EOL'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SSE Debug - Minimal</title>
    <style>
        body { font-family: sans-serif; margin: 20px; }
        .status { display: inline-block; width: 12px; height: 12px; border-radius: 50%; margin-right: 8px; }
        .connected { background-color: green; }
        .disconnected { background-color: red; }
        .connecting { background-color: orange; }
        .alert { padding: 10px; margin: 10px 0; border-left: 4px solid #ccc; }
        .high { border-left-color: red; background-color: #ffeeee; }
        .medium { border-left-color: orange; background-color: #fff8ee; }
        .low { border-left-color: yellow; background-color: #ffffee; }
        pre { background-color: #f0f0f0; padding: 10px; overflow-x: auto; }
    </style>
</head>
<body>
    <h1>SSE Debug - Minimal Test</h1>
    
    <div>
        <h2>Connection: <span id="status-text">Disconnected</span> <span id="status" class="status disconnected"></span></h2>
        <button id="connect">Connect</button>
        <button id="disconnect" disabled>Disconnect</button>
        <button id="test-high">Test High</button>
        <button id="test-medium">Test Medium</button>
        <button id="test-low">Test Low</button>
        <button id="clear">Clear</button>
    </div>
    
    <div id="alerts"></div>
    
    <div>
        <h3>Log</h3>
        <pre id="log"></pre>
    </div>

    <script>
        const statusEl = document.getElementById('status');
        const statusTextEl = document.getElementById('status-text');
        const connectBtn = document.getElementById('connect');
        const disconnectBtn = document.getElementById('disconnect');
        const testHighBtn = document.getElementById('test-high');
        const testMediumBtn = document.getElementById('test-medium');
        const testLowBtn = document.getElementById('test-low');
        const clearBtn = document.getElementById('clear');
        const alertsEl = document.getElementById('alerts');
        const logEl = document.getElementById('log');
        
        let eventSource = null;
        let alerts = [];
        
        function updateStatus(status) {
            statusEl.className = `status ${status}`;
            statusTextEl.textContent = status.charAt(0).toUpperCase() + status.slice(1);
            connectBtn.disabled = status === 'connected';
            disconnectBtn.disabled = status !== 'connected';
        }
        
        function log(msg) {
            const time = new Date().toLocaleTimeString();
            logEl.textContent += `[${time}] ${msg}\n`;
            logEl.scrollTop = logEl.scrollHeight;
        }
        
        function renderAlerts() {
            if (alerts.length === 0) {
                alertsEl.innerHTML = '<p>No alerts</p>';
                return;
            }
            
            alertsEl.innerHTML = '';
            alerts.forEach(alert => {
                const el = document.createElement('div');
                el.className = `alert ${alert.event_type.toLowerCase()}`;
                
                const time = new Date(alert.timestamp).toLocaleString();
                el.innerHTML = `
                    <div><strong>${alert.event_type}</strong> <span>${time}</span></div>
                    <div>${alert.message}</div>
                    <pre>${JSON.stringify(alert, null, 2)}</pre>
                `;
                
                alertsEl.appendChild(el);
            });
        }
        
        function connect() {
            if (eventSource) {
                eventSource.close();
            }
            
            updateStatus('connecting');
            log('Connecting to SSE endpoint...');
            
            eventSource = new EventSource('/api/attack-alerts');
            
            eventSource.onopen = () => {
                updateStatus('connected');
                log('Connected!');
            };
            
            eventSource.onmessage = (event) => {
                log(`Received: ${event.data}`);
                try {
                    const alert = JSON.parse(event.data);
                    alerts.unshift(alert);
                    renderAlerts();
                } catch (error) {
                    log(`Parse error: ${error.message}`);
                }
            };
            
            eventSource.onerror = () => {
                updateStatus('disconnected');
                log('Connection error');
            };
        }
        
        function disconnect() {
            if (eventSource) {
                eventSource.close();
                eventSource = null;
                updateStatus('disconnected');
                log('Disconnected');
            }
        }
        
        function sendTestAlert(severity) {
            log(`Sending test ${severity} alert...`);
            
            fetch('/api/debug/display-state', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    "WarningDetected": { "event_type": severity }
                })
            })
            .then(response => response.text())
            .then(data => log(`Response: ${data}`))
            .catch(error => log(`Error: ${error.message}`));
        }
        
        connectBtn.addEventListener('click', connect);
        disconnectBtn.addEventListener('click', disconnect);
        testHighBtn.addEventListener('click', () => sendTestAlert('High'));
        testMediumBtn.addEventListener('click', () => sendTestAlert('Medium'));
        testLowBtn.addEventListener('click', () => sendTestAlert('Low'));
        clearBtn.addEventListener('click', () => {
            alerts = [];
            renderAlerts();
            log('Alerts cleared');
        });
        
        renderAlerts();
        log('Page loaded');
    </script>
</body>
</html>
EOL

# Push debug HTML file to device
echo "Copying debug HTML file to device..."
adb push debug_sse_minimal.html /tmp/debug_sse_minimal.html
adb shell rootshell -c "'mkdir -p /data/rayhunter/web'"
adb shell rootshell -c "'cp /tmp/debug_sse_minimal.html /data/rayhunter/web/debug_sse_minimal.html'"
adb shell rootshell -c "'chmod 644 /data/rayhunter/web/debug_sse_minimal.html'"
adb shell rootshell -c "'rm /tmp/debug_sse_minimal.html'"

# Create test script on device
echo "Creating test script on device..."
cat > test_attack_alert.sh << 'EOL'
#!/bin/sh

echo "Cell Attack Alert System Test"
echo "============================"
echo ""
echo "This script will send a test alert to the running Rayhunter daemon"
echo ""

# Send test HIGH severity alert
echo "Sending test High severity alert..."
wget --quiet --output-document=- --header="Content-Type: application/json" \
  --post-data='{"WarningDetected":{"event_type":"High"}}' \
  http://localhost:8080/api/debug/display-state \
  && echo -e "\nHigh severity alert sent successfully"

sleep 2

# Send test MEDIUM severity alert
echo "Sending test Medium severity alert..."
wget --quiet --output-document=- --header="Content-Type: application/json" \
  --post-data='{"WarningDetected":{"event_type":"Medium"}}' \
  http://localhost:8080/api/debug/display-state \
  && echo -e "\nMedium severity alert sent successfully"

sleep 2

# Send test LOW severity alert
echo "Sending test Low severity alert..."
wget --quiet --output-document=- --header="Content-Type: application/json" \
  --post-data='{"WarningDetected":{"event_type":"Low"}}' \
  http://localhost:8080/api/debug/display-state \
  && echo -e "\nLow severity alert sent successfully"

echo ""
echo "Check your web UI for alerts and browser notifications"
echo "============================"
EOL

# Push test script to device
echo "Copying test script to device..."
chmod +x test_attack_alert.sh
adb push test_attack_alert.sh /tmp/test_attack_alert.sh
adb shell rootshell -c "'cp /tmp/test_attack_alert.sh /data/rayhunter/test_attack_alert.sh'"
adb shell rootshell -c "'chmod 755 /data/rayhunter/test_attack_alert.sh'"
adb shell rootshell -c "'rm /tmp/test_attack_alert.sh'"

# Reboot the device
echo "Rebooting device..."
adb shell rootshell -c "'reboot'"

echo "Deployment complete! Device is rebooting."
echo "After reboot, you can access:"
echo "- Main UI: http://DEVICE_IP:8080/index.html"
echo "- Debug UI: http://DEVICE_IP:8080/fs/debug_sse_minimal.html"
echo "- Test script: adb shell rootshell -c '\"/data/rayhunter/test_attack_alert.sh\"'"
