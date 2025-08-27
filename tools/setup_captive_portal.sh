#!/bin/bash

# Captive Portal Setup for Rayhunter Device
# Redirects all web traffic to http://192.168.1.1:8080/

echo "🌐 Setting up Captive Portal for Rayhunter Device..."
echo "=================================================="

# Configuration
PORTAL_IP="192.168.1.1"
PORTAL_PORT="8080"
PORTAL_URL="http://${PORTAL_IP}:${PORTAL_PORT}/"
INTERFACE="bridge0"  # Based on current dnsmasq config

# Check if ADB is available
if ! command -v adb &> /dev/null; then
    echo "❌ ADB not found. Please install Android Debug Bridge."
    exit 1
fi

# Check device connection
if ! adb devices | grep -q "device$"; then
    echo "❌ No device connected. Please connect your device via USB."
    exit 1
fi

echo "📱 Device: $(adb devices | grep 'device$' | head -1 | cut -f1)"
echo "🎯 Target: $PORTAL_URL"
echo ""

# 1. Create enhanced dnsmasq configuration for captive portal
echo "🔧 1. Creating enhanced dnsmasq configuration..."

cat > captive_portal_dnsmasq.conf << EOF
# Enhanced dnsmasq configuration for Captive Portal
# Based on existing configuration with captive portal additions

# Basic dnsmasq settings
domain-needed
resolv-file=/tmp/resolv_rmnet_data.conf
listen-address=127.0.0.1
dhcp-authoritative
stop-dns-rebind

# DHCP settings (from existing config)
dhcp-range=${INTERFACE},192.168.1.100,192.168.1.200,255.255.255.0,86400
dhcp-option-force=6,${PORTAL_IP}
dhcp-option-force=120,abcd.com

# Captive Portal DNS Spoofing
# Redirect all DNS queries to our portal
address=/#/${PORTAL_IP}

# Specific redirects for common domains
address=/google.com/${PORTAL_IP}
address=/www.google.com/${PORTAL_IP}
address=/facebook.com/${PORTAL_IP}
address=/www.facebook.com/${PORTAL_IP}
address=/youtube.com/${PORTAL_IP}
address=/www.youtube.com/${PORTAL_IP}
address=/amazon.com/${PORTAL_IP}
address=/www.amazon.com/${PORTAL_IP}
address=/apple.com/${PORTAL_IP}
address=/www.apple.com/${PORTAL_IP}
address=/microsoft.com/${PORTAL_IP}
address=/www.microsoft.com/${PORTAL_IP}
address=/netflix.com/${PORTAL_IP}
address=/www.netflix.com/${PORTAL_IP}
address=/twitter.com/${PORTAL_IP}
address=/www.twitter.com/${PORTAL_IP}
address=/instagram.com/${PORTAL_IP}
address=/www.instagram.com/${PORTAL_IP}

# Log DNS queries for debugging
log-queries
log-facility=/data/rayhunter/captive_portal.log

# Additional settings from original config
dhcp-leasefile=/data/dnsmasq.leases
addn-hosts=/data/hosts
pid-file=/data/dnsmasq.pid
EOF

# 2. Create HTTP redirect server
echo "🌐 2. Creating HTTP redirect server..."

cat > captive_portal_server.py << 'EOF'
#!/usr/bin/env python3
"""
Captive Portal HTTP Server for Rayhunter Device
Redirects all HTTP requests to the Rayhunter web interface
"""

import socket
import threading
import time
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse

class CaptivePortalHandler(BaseHTTPRequestHandler):
    """HTTP handler that redirects all requests to the captive portal"""
    
    PORTAL_URL = "http://192.168.1.1:8080/"
    
    def do_GET(self):
        """Handle GET requests - redirect to portal"""
        self.send_response(302)  # Found/Redirect
        self.send_header('Location', self.PORTAL_URL)
        self.send_header('Content-Type', 'text/html')
        self.end_headers()
        
        # Send a simple redirect page as fallback
        html = f"""
        <html>
        <head>
            <title>Redirecting to Rayhunter...</title>
            <meta http-equiv="refresh" content="0;url={self.PORTAL_URL}">
            <style>
                body {{ font-family: Arial, sans-serif; text-align: center; margin-top: 50px; }}
                .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                .logo {{ font-size: 24px; color: #333; margin-bottom: 20px; }}
                .message {{ color: #666; margin-bottom: 20px; }}
                .link {{ color: #007bff; text-decoration: none; }}
                .link:hover {{ text-decoration: underline; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="logo">🐋 Rayhunter Portal</div>
                <div class="message">Redirecting to cellular monitoring interface...</div>
                <p>If you are not redirected automatically, <a href="{self.PORTAL_URL}" class="link">click here</a>.</p>
            </div>
        </body>
        </html>
        """
        self.wfile.write(html.encode())
    
    def do_POST(self):
        """Handle POST requests - redirect to portal"""
        self.do_GET()
    
    def log_message(self, format, *args):
        """Custom logging to show redirects"""
        print(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] {self.client_address[0]} -> {self.PORTAL_URL}")

def start_captive_portal_server(port=80, host='0.0.0.0'):
    """Start the captive portal HTTP server"""
    try:
        server = HTTPServer((host, port), CaptivePortalHandler)
        print(f"🚀 Captive Portal HTTP Server started on {host}:{port}")
        print(f"📱 All HTTP requests will redirect to: {CaptivePortalHandler.PORTAL_URL}")
        print("Press Ctrl+C to stop")
        
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n🛑 Server stopped by user")
    except Exception as e:
        print(f"❌ Error starting server: {e}")

if __name__ == "__main__":
    import sys
    
    # Allow custom port
    port = 80
    if len(sys.argv) > 1:
        try:
            port = int(sys.argv[1])
        except ValueError:
            print("Usage: python3 captive_portal_server.py [port]")
            sys.exit(1)
    
    start_captive_portal_server(port)
EOF

# 3. Create iptables rules for HTTP redirection
echo "🔒 3. Creating iptables redirection rules..."

cat > captive_portal_iptables.sh << EOF
#!/bin/bash
# iptables rules for captive portal redirection

PORTAL_IP="${PORTAL_IP}"
PORTAL_PORT="${PORTAL_PORT}"
INTERFACE="${INTERFACE}"

echo "🔒 Setting up iptables rules for captive portal..."

# Redirect HTTP traffic to our portal
iptables -t nat -A PREROUTING -i \$INTERFACE -p tcp --dport 80 -j DNAT --to-destination \$PORTAL_IP:\$PORTAL_PORT
iptables -t nat -A PREROUTING -i \$INTERFACE -p tcp --dport 443 -j DNAT --to-destination \$PORTAL_IP:\$PORTAL_PORT

# Allow DNS traffic
iptables -A INPUT -i \$INTERFACE -p udp --dport 53 -j ACCEPT
iptables -A INPUT -i \$INTERFACE -p tcp --dport 53 -j ACCEPT

# Allow HTTP traffic to our portal
iptables -A INPUT -i \$INTERFACE -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -i \$INTERFACE -p tcp --dport \$PORTAL_PORT -j ACCEPT

echo "✅ iptables rules configured"
EOF

# 4. Create start/stop scripts
echo "📝 4. Creating management scripts..."

cat > start_captive_portal.sh << EOF
#!/bin/bash
# Start Captive Portal on Rayhunter Device

echo "🚀 Starting Captive Portal..."

# Check if Rayhunter daemon is running
if ! ps aux | grep -q "rayhunter-daemon"; then
    echo "❌ Rayhunter daemon not running. Please start it first."
    exit 1
fi

# Method 1: DNS spoofing (most seamless)
echo "📡 Setting up DNS spoofing..."
if [ -f "/data/rayhunter/captive_portal_dnsmasq.conf" ]; then
    # Stop existing dnsmasq
    pkill dnsmasq 2>/dev/null || true
    sleep 2
    
    # Start dnsmasq with captive portal config
    dnsmasq --conf-file=/data/rayhunter/captive_portal_dnsmasq.conf &
    echo \$! > /data/rayhunter/dnsmasq.pid
    echo "✅ DNS spoofing active"
else
    echo "❌ DNS configuration not found"
    exit 1
fi

# Method 2: HTTP redirect server (fallback)
echo "🌐 Starting HTTP redirect server..."
cd /data/rayhunter
python3 captive_portal_server.py 80 &
echo \$! > /data/rayhunter/http_server.pid
echo "✅ HTTP redirect server started"

# Method 3: iptables rules
echo "🔒 Setting up iptables rules..."
if [ -f "/data/rayhunter/captive_portal_iptables.sh" ]; then
    chmod +x /data/rayhunter/captive_portal_iptables.sh
    /data/rayhunter/captive_portal_iptables.sh
    echo "✅ iptables rules configured"
fi

echo ""
echo "🎉 Captive Portal Started Successfully!"
echo "📱 Users connecting to WiFi will be redirected to: ${PORTAL_URL}"
echo "🔍 To test: Connect a device to WiFi and try accessing any website"
echo ""
echo "📊 Active processes:"
ps aux | grep -E "(dnsmasq|captive_portal_server)" | grep -v grep
EOF

cat > stop_captive_portal.sh << EOF
#!/bin/bash
# Stop Captive Portal on Rayhunter Device

echo "🛑 Stopping Captive Portal..."

# Stop HTTP redirect server
if [ -f "/data/rayhunter/http_server.pid" ]; then
    PID=\$(cat /data/rayhunter/http_server.pid)
    if kill -0 \$PID 2>/dev/null; then
        kill \$PID
        echo "✅ HTTP redirect server stopped (PID: \$PID)"
    fi
    rm -f /data/rayhunter/http_server.pid
fi

# Stop captive portal dnsmasq
if [ -f "/data/rayhunter/dnsmasq.pid" ]; then
    PID=\$(cat /data/rayhunter/dnsmasq.pid)
    if kill -0 \$PID 2>/dev/null; then
        kill \$PID
        echo "✅ Captive portal dnsmasq stopped (PID: \$PID)"
    fi
    rm -f /data/rayhunter/dnsmasq.pid
fi

# Kill any remaining processes
pkill -f "captive_portal_server.py" 2>/dev/null || true

# Remove iptables rules (simplified)
echo "🔒 Removing iptables rules..."
iptables -t nat -D PREROUTING -i ${INTERFACE} -p tcp --dport 80 -j DNAT --to-destination ${PORTAL_IP}:${PORTAL_PORT} 2>/dev/null || true
iptables -t nat -D PREROUTING -i ${INTERFACE} -p tcp --dport 443 -j DNAT --to-destination ${PORTAL_IP}:${PORTAL_PORT} 2>/dev/null || true

# Restart original dnsmasq
echo "🔄 Restarting original dnsmasq..."
pkill dnsmasq 2>/dev/null || true
sleep 2
dnsmasq --conf-file=/data/dnsmasq.conf &
echo "✅ Original dnsmasq restarted"

echo ""
echo "✅ Captive Portal Stopped"
echo "📱 Users can now access the internet normally"
EOF

# 5. Deploy files to device
echo "📤 5. Deploying files to device..."

# Push configuration files
adb push captive_portal_dnsmasq.conf /tmp/
adb push captive_portal_server.py /tmp/
adb push captive_portal_iptables.sh /tmp/
adb push start_captive_portal.sh /tmp/
adb push stop_captive_portal.sh /tmp/

# Copy files to device directory
adb shell "/bin/rootshell -c 'mkdir -p /data/rayhunter/captive-portal'"
adb shell "/bin/rootshell -c 'cp /tmp/captive_portal_dnsmasq.conf /data/rayhunter/'"
adb shell "/bin/rootshell -c 'cp /tmp/captive_portal_server.py /data/rayhunter/'"
adb shell "/bin/rootshell -c 'cp /tmp/captive_portal_iptables.sh /data/rayhunter/'"
adb shell "/bin/rootshell -c 'cp /tmp/start_captive_portal.sh /data/rayhunter/'"
adb shell "/bin/rootshell -c 'cp /tmp/stop_captive_portal.sh /data/rayhunter/'"

# Make scripts executable
adb shell "/bin/rootshell -c 'chmod +x /data/rayhunter/*.sh'"
adb shell "/bin/rootshell -c 'chmod +x /data/rayhunter/captive_portal_server.py'"

# 6. Create status check script
echo "📊 6. Creating status check script..."

cat > check_captive_portal.sh << 'EOF'
#!/bin/bash
# Check Captive Portal Status

echo "📊 Captive Portal Status Check"
echo "=============================="

echo "🔍 Checking active processes:"
echo "DNS Server (dnsmasq):"
ps aux | grep dnsmasq | grep -v grep || echo "  ❌ Not running"

echo ""
echo "HTTP Redirect Server:"
ps aux | grep captive_portal_server | grep -v grep || echo "  ❌ Not running"

echo ""
echo "🌐 Network Services:"
echo "Port 80 (HTTP):"
netstat -tlnp | grep :80 || echo "  ❌ Not listening"

echo ""
echo "Port 8080 (Rayhunter):"
netstat -tlnp | grep :8080 || echo "  ❌ Not listening"

echo ""
echo "📱 Rayhunter Daemon:"
ps aux | grep rayhunter-daemon | grep -v grep || echo "  ❌ Not running"

echo ""
echo "🔒 iptables Rules:"
iptables -t nat -L PREROUTING | grep -E "(80|443)" || echo "  ❌ No redirect rules found"

echo ""
echo "📋 Quick Actions:"
echo "  Start: adb shell '/data/rayhunter/start_captive_portal.sh'"
echo "  Stop:  adb shell '/data/rayhunter/stop_captive_portal.sh'"
echo "  Test:  Connect device to WiFi and try accessing google.com"
EOF

adb push check_captive_portal.sh /tmp/
adb shell "/bin/rootshell -c 'cp /tmp/check_captive_portal.sh /data/rayhunter/'"
adb shell "/bin/rootshell -c 'chmod +x /data/rayhunter/check_captive_portal.sh'"

# Clean up local files
rm -f captive_portal_dnsmasq.conf captive_portal_server.py captive_portal_iptables.sh
rm -f start_captive_portal.sh stop_captive_portal.sh check_captive_portal.sh

echo ""
echo "✅ Captive Portal Setup Complete!"
echo ""
echo "📁 Files installed in: /data/rayhunter/"
echo "  - captive_portal_dnsmasq.conf (DNS configuration)"
echo "  - captive_portal_server.py (HTTP redirect server)"
echo "  - captive_portal_iptables.sh (iptables rules)"
echo "  - start_captive_portal.sh (start script)"
echo "  - stop_captive_portal.sh (stop script)"
echo "  - check_captive_portal.sh (status check)"
echo ""
echo "🚀 To start captive portal:"
echo "   adb shell '/data/rayhunter/start_captive_portal.sh'"
echo ""
echo "🛑 To stop captive portal:"
echo "   adb shell '/data/rayhunter/stop_captive_portal.sh'"
echo ""
echo "📊 To check status:"
echo "   adb shell '/data/rayhunter/check_captive_portal.sh'"
echo ""
echo "🧪 To test:"
echo "   1. Start the captive portal"
echo "   2. Connect a device to the WiFi network"
echo "   3. Try accessing any website (e.g., google.com)"
echo "   4. Should redirect to: ${PORTAL_URL}"
echo ""
echo "💡 The captive portal will redirect all web traffic to your Rayhunter interface!" 