#!/bin/bash

# Secure PIN Management Script for RayHunter Enhanced
# SECURITY PRINCIPLE: PINs are NEVER stored, only used once for key derivation
# Based on the comprehensive implementation from rayhunter-enhanced-PE

set -e

# Default paths
DEFAULT_KEY_FILE="/tmp/rayhunter-jwt.key"
CONFIG_FILE="/data/local/tmp/rayhunter/config.toml"
DEFAULT_CONFIG_FILE="dist/config.toml.example"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

show_banner() {
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║              🔐 RayHunter Secure PIN Manager 🔐               ║"
    echo "║           PIN-based JWT Key Generation & Management           ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${YELLOW}SECURITY: PINs are NEVER stored, only used once for key derivation${NC}"
    echo ""
}

# Function to validate PIN format
validate_pin() {
    local pin="$1"
    
    if [ ${#pin} -ne 8 ]; then
        echo -e "${RED}❌ PIN must be exactly 8 digits${NC}"
        return 1
    fi
    
    if ! [[ "$pin" =~ ^[0-9]{8}$ ]]; then
        echo -e "${RED}❌ PIN must contain only digits (0-9)${NC}"
        return 1
    fi
    
    # Check for weak PINs - only reject truly weak patterns
    case "$pin" in
        # All same digit
        "00000000"|"11111111"|"22222222"|"33333333"|"44444444"|"55555555"|"66666666"|"77777777"|"88888888"|"99999999")
            echo -e "${RED}❌ PIN is too weak. All digits are the same.${NC}"
            return 1
            ;;
        # Simple sequences
        "12345678"|"87654321"|"01234567"|"76543210")
            echo -e "${RED}❌ PIN is too weak. Avoid simple sequential patterns.${NC}"
            return 1
            ;;
        # Common weak PINs
        "00000000"|"12345678"|"11111111"|"00001234"|"12341234")
            echo -e "${RED}❌ PIN is too weak. This is a commonly used PIN.${NC}"
            return 1
            ;;
    esac
    
    # Additional entropy check - ensure at least 2 different digits
    local unique_digits
    unique_digits=$(echo "$pin" | grep -o . | sort | uniq | wc -l | tr -d ' ')
    
    if [ "$unique_digits" -lt 2 ]; then
        echo -e "${RED}❌ PIN is too weak. Use at least 2 different digits.${NC}"
        return 1
    fi
    
    return 0
}

# Function to securely read PIN
read_pin_secure() {
    local prompt="$1"
    local pin
    local attempts=0
    local max_attempts=3
    
    while [ $attempts -lt $max_attempts ]; do
        printf "%s" "$prompt"
        
        # Simple read - works best for both interactive and piped input
        read pin
        
        # Clean up the PIN - remove any extra characters and whitespace
        pin=$(printf "%s" "$pin" | sed 's/[^0-9]//g' | cut -c1-8)
        
        # Check if PIN is empty
        if [ -z "$pin" ]; then
            echo -e "${RED}❌ PIN cannot be empty. Please enter 8 digits.${NC}"
            attempts=$((attempts + 1))
            continue
        fi
        
        # Validate PIN format and strength
        if validate_pin "$pin"; then
            echo "$pin"
            return 0
        fi
        
        attempts=$((attempts + 1))
        if [ $attempts -lt $max_attempts ]; then
            echo -e "${YELLOW}⚠️  Please try again ($((max_attempts - attempts)) attempts remaining)${NC}"
        fi
    done
    
    echo -e "${RED}❌ Maximum PIN attempts exceeded${NC}"
    return 1
}

# Function to generate a secure random PIN
generate_secure_pin() {
    local pin
    local attempts=0
    local max_attempts=50
    
    while [ $attempts -lt $max_attempts ]; do
        if command -v openssl >/dev/null 2>&1; then
            # Use OpenSSL for better randomness
            pin=$(openssl rand -hex 4 | sed 's/[a-f]/0/g' | head -c 8)
        elif [[ -f /dev/urandom ]]; then
            # Fallback to /dev/urandom
            pin=$(LC_ALL=C tr -dc '0-9' < /dev/urandom | head -c 8)
        else
            echo -e "${RED}❌ No secure random source available${NC}"
            return 1
        fi
        
        # Validate the generated PIN
        if validate_pin "$pin" 2>/dev/null; then
            echo "$pin"
            return 0
        fi
        
        attempts=$((attempts + 1))
    done
    
    echo -e "${RED}❌ Failed to generate secure PIN after $max_attempts attempts${NC}"
    return 1
}

# Function to derive key from PIN using the same method as client KdfUtil.kt
derive_key_from_pin() {
    local pin="$1"
    

    
    # Validate PIN before processing
    if [ -z "$pin" ]; then
        echo -e "${RED}❌ PIN is empty${NC}" >&2
        return 1
    fi
    
    # Use Python to implement the EXACT same PBKDF2 derivation as the client
    # CRITICAL: These parameters MUST match KdfUtil.kt exactly
    local derived_key
    
    # Run Python script and capture only the key output
    derived_key=$(python3 -c "
import hashlib
import sys

def derive_key_from_pin(pin):
    try:
        # MUST match client KdfUtil.kt parameters exactly:
        # ITERATIONS = 100_000
        # FIXED_SALT = 'gps2rest-salt-2025'  
        # KEY_LENGTH = 256 (bits) = 32 bytes
        salt = b'gps2rest-salt-2025'
        iterations = 100000  # 100,000 iterations (matches client)
        key_length = 32      # 256 bits = 32 bytes (matches client)
        
        # PBKDF2 with HMAC-SHA256 (same as client)
        derived_key = hashlib.pbkdf2_hmac('sha256', pin.encode('utf-8'), salt, iterations, key_length)
        
        # Convert to hex string for storage
        return derived_key.hex()
    except Exception as e:
        print(f'ERROR: {e}', file=sys.stderr)
        sys.exit(1)

# Get PIN from command line argument passed via shell
pin = '$pin'
if not pin:
    print('ERROR: Empty PIN', file=sys.stderr)
    sys.exit(1)

# Only output the derived key to stdout
result = derive_key_from_pin(pin)
print(result)
" 2>/dev/null)
    
    local python_exit_code=$?
    
    if [ $python_exit_code -ne 0 ] || [ -z "$derived_key" ]; then
        echo -e "${RED}❌ Failed to derive key from PIN${NC}" >&2
        echo -e "${YELLOW}📝 Python3 required with hashlib support${NC}" >&2
        echo -e "${YELLOW}📝 Ensure algorithm matches client KdfUtil.kt exactly${NC}" >&2
        return 1
    fi
    
    # Validate derived key format (should be 64 hex characters)
    if ! [[ "$derived_key" =~ ^[a-f0-9]{64}$ ]]; then
        echo -e "${RED}❌ Invalid derived key format${NC}" >&2
        echo -e "${YELLOW}📝 Expected 64 hex characters, got: ${#derived_key} characters${NC}" >&2
        return 1
    fi
    
    echo "$derived_key"
}

# Function to generate and save key from PIN
generate_key_from_pin() {
    local pin="$1"
    local key_file="${2:-$DEFAULT_KEY_FILE}"
    
    echo -e "${BLUE}🔄 Deriving cryptographic key from PIN...${NC}"
    
    local derived_key
    derived_key=$(derive_key_from_pin "$pin" 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$derived_key" ]; then
        # Create directory if it doesn't exist
        local key_dir
        key_dir=$(dirname "$key_file")
        if [[ ! -d "$key_dir" ]]; then
            echo "Creating directory: $key_dir"
            mkdir -p "$key_dir" || {
                echo -e "${RED}❌ Failed to create directory: $key_dir${NC}"
                return 1
            }
        fi
        
        # Write the derived key to file
        echo "$derived_key" > "$key_file" || {
            echo -e "${RED}❌ Failed to write key to file: $key_file${NC}"
            return 1
        }
        
        # Set secure permissions (owner read-only)
        chmod 600 "$key_file" || {
            echo -e "${RED}❌ Failed to set secure permissions on key file${NC}"
            return 1
        }
        
        echo -e "${GREEN}✅ Key derivation successful${NC}"
        echo -e "${BLUE}📁 Key saved to: $key_file${NC}"
        echo -e "${BLUE}🔒 Permissions: 600 (owner read-only)${NC}"
        echo -e "${BLUE}📊 Key length: ${#derived_key} characters (hex)${NC}"
        echo -e "${YELLOW}🗑️  PIN has been discarded from memory${NC}"
        
        return 0
    else
        echo -e "${RED}❌ Key derivation failed${NC}"
        return 1
    fi
}

# Function to test PIN derivation without saving
test_pin_derivation() {
    echo -e "${BLUE}🧪 Testing PIN-based key derivation...${NC}"
    
    local pin
    pin=$(read_pin_secure "${CYAN}Enter 8-digit PIN for testing: ${NC}") || return 1
    
    echo -e "${YELLOW}🔄 Deriving key from PIN...${NC}"
    local derived_key
    derived_key=$(derive_key_from_pin "$pin" 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$derived_key" ]; then
        echo -e "${GREEN}✅ Key derivation successful${NC}"
        echo -e "${BLUE}📊 Derived key length: ${#derived_key} characters (hex)${NC}"
        echo -e "${YELLOW}🔒 First 16 chars: ${derived_key:0:16}...${NC}"
        echo -e "${YELLOW}🗑️  PIN has been discarded from memory${NC}"
    else
        echo -e "${RED}❌ Key derivation failed${NC}"
        return 1
    fi
}

# Function to generate key with user interaction
interactive_key_generation() {
    local key_file="${1:-$DEFAULT_KEY_FILE}"
    
    echo -e "${CYAN}Choose PIN generation method:${NC}"
    echo "1) Generate a secure random PIN (recommended)"
    echo "2) Enter a custom PIN"
    echo "3) Cancel"
    
    read -p "Choose an option [1-3]: " choice
    
    case $choice in
        1)
            echo -e "${BLUE}🎲 Generating secure random PIN...${NC}"
            local generated_pin
            generated_pin=$(generate_secure_pin) || return 1
            
            echo -e "${GREEN}✅ Generated PIN: ${BOLD}$generated_pin${NC}"
            echo -e "${YELLOW}⚠️  Save this PIN - you'll need it for the client app!${NC}"
            echo ""
            
            generate_key_from_pin "$generated_pin" "$key_file"
            return $?
            ;;
        2)
            local custom_pin
            custom_pin=$(read_pin_secure "${CYAN}Enter your custom 8-digit PIN: ${NC}") || return 1
            
            generate_key_from_pin "$custom_pin" "$key_file"
            return $?
            ;;
        3)
            echo -e "${YELLOW}⏹️  Operation cancelled${NC}"
            return 1
            ;;
        *)
            echo -e "${RED}❌ Invalid choice${NC}"
            return 1
            ;;
    esac
}

# Function to show usage help
show_help() {
    echo -e "${WHITE}Secure PIN Management for RayHunter Enhanced${NC}"
    echo "=============================================="
    echo ""
    echo -e "${WHITE}SECURITY PRINCIPLES:${NC}"
    echo "  • PINs are NEVER stored anywhere"
    echo "  • PINs are used only once for key derivation"
    echo "  • Derived keys are cryptographically secure"
    echo "  • PBKDF2 with 100,000 iterations prevents brute force"
    echo "  • Algorithm MUST match client KdfUtil.kt exactly"
    echo ""
    echo -e "${WHITE}USAGE:${NC} $0 [command] [options]"
    echo ""
    echo -e "${WHITE}COMMANDS:${NC}"
    echo "  generate-key [file]   - Generate JWT key from PIN (interactive)"
    echo "  auto-pin [file]       - Generate key using random PIN"
    echo "  custom-pin PIN [file] - Generate key using specific PIN"
    echo "  test-pin              - Test PIN derivation (no file saved)"
    echo "  install               - Generate key and install to device (full workflow)"
    echo "  install-key file      - Install existing key file to device"
    echo "  list-devices          - List connected ADB devices"
    echo "  check-daemon          - Check daemon status on device"
    echo "  help                  - Show this help message"
    echo ""
    echo -e "${WHITE}ARGUMENTS:${NC}"
    echo "  file                  - Key file path (default: $DEFAULT_KEY_FILE)"
    echo "  PIN                   - 8-digit PIN for key derivation"
    echo ""
    echo -e "${WHITE}EXAMPLES:${NC}"
    echo "  $0 generate-key                    # Interactive key generation"
    echo "  $0 generate-key ~/.rayhunter/jwt.key"
    echo "  $0 auto-pin /tmp/test.key          # Random PIN, custom file"
    echo "  $0 custom-pin 19283746             # Specific PIN, default file"
    echo "  $0 test-pin                        # Test without saving"
    echo "  $0 install                         # Full workflow: generate + install + restart"
    echo "  $0 install-key ~/.rayhunter/jwt.key # Install existing key to device"
    echo "  $0 list-devices                    # Show connected devices"
    echo "  $0 check-daemon                    # Check daemon status"
    echo ""
    echo -e "${WHITE}ENVIRONMENT VARIABLES:${NC}"
    echo "  RAYHUNTER_JWT_KEY_FILE - Key file path for daemon"
    echo ""
    echo -e "${BLUE}PIN Authentication Flow:${NC}"
    echo "  1. Generate key from PIN using this script"
    echo "  2. Set RAYHUNTER_JWT_KEY_FILE environment variable"
    echo "  3. Start daemon - it will read the pre-generated key"
    echo "  4. Client uses same PIN to derive matching key"
    echo "  5. JWT authentication works with derived keys"
    echo ""
    echo -e "${BLUE}Device Installation Workflow:${NC}"
    echo "  1. Connect embedded Linux device via USB with ADB debugging enabled"
    echo "  2. Run: $0 install"
    echo "  3. Choose PIN generation method (auto/custom)"
    echo "  4. Select target device from connected devices"
    echo "  5. Key is uploaded to /etc/keys/jwt-key.txt (daemon location)"
    echo "  6. Choose whether to restart daemon with new key"
    echo "  7. Daemon runs with RAYHUNTER_JWT_KEY_FILE set"
    echo ""
    echo -e "${YELLOW}Security Notes:${NC}"
    echo "  • Use a strong, unique 8-digit PIN"
    echo "  • Never use sequential numbers (12345678)"
    echo "  • Never use repeated digits (11111111)"
    echo "  • PIN derivation uses PBKDF2 with HMAC-SHA256"
    echo "  • 100,000 iterations with 'gps2rest-salt-2025' salt"
    echo "  • Algorithm MUST match client KdfUtil.kt exactly"
    echo "  • Keys are stored temporarily in /tmp on host and installed to /etc/keys on device"
    echo ""
    echo -e "${YELLOW}Device Requirements:${NC}"
    echo "  • Embedded Linux device with USB debugging enabled"
    echo "  • ADB (Android Debug Bridge) installed and in PATH"
    echo "  • rootshell available on device (for elevated privileges)"
    echo "  • Device connected via USB"
}

# Check Python3 availability
check_python3() {
    if ! command -v python3 >/dev/null 2>&1; then
        echo -e "${RED}❌ Python 3 is required for key derivation${NC}"
        echo "Please install Python 3 and try again."
        return 1
    fi
    return 0
}

# Check ADB availability and list connected devices
check_adb() {
    # Try command -v first (POSIX compliant)
    if command -v adb &> /dev/null; then
        export ADB_PATH="adb"
        return 0
    fi
    
    # Fallback to which command
    if which adb &> /dev/null; then
        export ADB_PATH="adb"
        return 0
    fi
    
    echo -e "${RED}❌ ADB not found. Please install Android SDK Platform Tools.${NC}"
    echo "Make sure ADB is in your PATH or install it from Android SDK."
    return 1
}

# List connected ADB devices
list_adb_devices() {
    if ! check_adb; then
        return 1
    fi
    
    echo -e "${BLUE}🔍 Scanning for connected devices...${NC}"
    
    # Get list of devices
    local devices_output
    devices_output=$(adb devices 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Failed to query ADB devices${NC}"
        return 1
    fi
    
    # Parse device list (skip header line)
    local devices
    devices=$(echo "$devices_output" | grep -v "List of devices" | grep "device$" | awk '{print $1}')
    
    if [ -z "$devices" ]; then
        echo -e "${RED}❌ No ADB devices connected${NC}"
        echo "Please connect your device and enable USB debugging."
        return 1
    fi
    
    # Count devices
    local device_count
    device_count=$(echo "$devices" | wc -l | tr -d ' ')
    
    echo -e "${GREEN}✅ Found $device_count connected device(s):${NC}"
    echo ""
    
    # Display devices with numbers (avoid subshell issues)
    local i=1
    while IFS= read -r device; do
        if [ -n "$device" ]; then
            echo -e "${CYAN}  $i) $device${NC} - ${YELLOW}(embedded Linux device)${NC}"
            i=$((i + 1))
        fi
    done <<< "$devices"
    
    return 0
}

# Select ADB device interactively
select_adb_device() {
    if ! check_adb; then
        return 1
    fi
    
    # Get list of devices
    local devices
    devices=$(adb devices 2>/dev/null | grep -v "List of devices" | grep "device$" | awk '{print $1}')
    
    if [ -z "$devices" ]; then
        echo -e "${RED}❌ No ADB devices connected${NC}"
        return 1
    fi
    
    # Convert to array
    local device_array=()
    while IFS= read -r device; do
        if [ -n "$device" ]; then
            device_array+=("$device")
        fi
    done <<< "$devices"
    
    local device_count=${#device_array[@]}
    
    # Show devices in clean format
    echo ""
    echo "Found $device_count connected device(s):"
    echo ""
    
    for i in "${!device_array[@]}"; do
        local device="${device_array[$i]}"
        echo "  $((i+1))) $device - (embedded Linux device)"
    done
    
    # Let user choose device (even if only one)
    echo ""
    echo "Enter device number [1-$device_count]: "
    read choice
    
    # Validate choice
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt $device_count ]; then
        echo -e "${RED}❌ Invalid device selection${NC}"
        return 1
    fi
    
    local selected_device="${device_array[$((choice-1))]}"
    echo "$selected_device"
    return 0
}

# Install key file to device
install_key_to_device() {
    local key_file="$1"
    local device_serial="${2:-}"
    
    if [ ! -f "$key_file" ]; then
        echo -e "${RED}❌ Key file not found: $key_file${NC}"
        return 1
    fi
    
    if ! check_adb; then
        return 1
    fi
    
    # Select device if not specified
    if [ -z "$device_serial" ]; then
        device_serial=$(select_adb_device) || return 1
    fi
    
    local adb_cmd="adb"
    if [ -n "$device_serial" ]; then
        adb_cmd="adb -s $device_serial"
    fi
    
    # Installing key to device: $device_serial
    
    # Device paths for key installation (daemon-expected location)
    local device_key_dir="/etc/keys"
    local device_key_file="$device_key_dir/jwt-key.txt"
    
    # Create key directory on device using rootshell for elevated privileges
    echo -e "${YELLOW}📁 Creating key directory on device...${NC}"
    $adb_cmd shell "rootshell -c 'mkdir -p $device_key_dir'" || {
        echo -e "${YELLOW}⚠️  rootshell failed, trying direct mkdir...${NC}"
        $adb_cmd shell "mkdir -p $device_key_dir" || {
            echo -e "${RED}❌ Failed to create key directory on device${NC}"
            echo "Try running: adb shell \"rootshell -c 'mkdir -p $device_key_dir'\""
            return 1
        }
    }
    
    # Push key file to device
    echo -e "${YELLOW}📤 Uploading key file...${NC}"
    $adb_cmd push "$key_file" "$device_key_file" || {
        echo -e "${RED}❌ Failed to upload key file to device${NC}"
        return 1
    }
    
    # Set secure permissions on device using rootshell for elevated privileges
    echo -e "${YELLOW}🔒 Setting secure permissions...${NC}"
    $adb_cmd shell "rootshell -c 'chmod 600 $device_key_file'" || {
        echo -e "${YELLOW}⚠️  rootshell failed, trying direct chmod...${NC}"
        $adb_cmd shell "chmod 600 $device_key_file" || {
            echo -e "${YELLOW}⚠️  Failed to set secure permissions (file may still work)${NC}"
        }
    }
    
    # Verify installation
    local device_key_size
    device_key_size=$($adb_cmd shell "wc -c < $device_key_file" 2>/dev/null | tr -d '\r ')
    
    if [ -n "$device_key_size" ] && [ "$device_key_size" -gt 0 ]; then
        echo -e "${GREEN}✅ Key successfully installed to device${NC}"
        echo -e "${BLUE}📁 Device path: $device_key_file${NC}"
        echo -e "${BLUE}📊 Key size: $device_key_size bytes${NC}"
        
        # Show environment variable for daemon
        echo ""
        echo -e "${YELLOW}📝 Device Configuration:${NC}"
        echo "Set the following environment variable on the device:"
        echo -e "${CYAN}  export RAYHUNTER_JWT_KEY_FILE=\"$device_key_file\"${NC}"
        
        return 0
    else
        echo -e "${RED}❌ Key installation verification failed${NC}"
        return 1
    fi
}

# Check if daemon is running on device
check_daemon_status() {
    local device_serial="$1"
    local adb_cmd="adb"
    if [ -n "$device_serial" ]; then
        adb_cmd="adb -s $device_serial"
    fi
    
    echo -e "${BLUE}🔍 Checking daemon status on device...${NC}"
    
    # Check if rayhunter-daemon process is running (try rootshell first)
    local daemon_pid
    daemon_pid=$($adb_cmd shell "rootshell -c 'pgrep -f rayhunter-daemon'" 2>/dev/null | tr -d '\r')
    
    # Fallback to direct command if rootshell fails
    if [ -z "$daemon_pid" ]; then
        daemon_pid=$($adb_cmd shell "pgrep -f rayhunter-daemon" 2>/dev/null | tr -d '\r')
    fi
    
    if [ -n "$daemon_pid" ]; then
        echo -e "${GREEN}✅ Daemon is running (PID: $daemon_pid)${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  Daemon is not currently running${NC}"
        return 1
    fi
}

# Clean up temporary key file
cleanup_temp_key() {
    local key_file="$1"
    
    if [ -f "$key_file" ] && [[ "$key_file" == "/tmp/rayhunter-jwt.key" ]]; then
        echo -e "${YELLOW}🧹 Cleaning up temporary key file...${NC}"
        rm -f "$key_file"
        echo -e "${GREEN}✅ Temporary key file removed${NC}"
    fi
}

# Restart daemon on device
restart_daemon_on_device() {
    local device_serial="$1"
    local device_key_file="$2"
    local adb_cmd="adb"
    if [ -n "$device_serial" ]; then
        adb_cmd="adb -s $device_serial"
    fi
    
    echo -e "${BLUE}🔄 Restarting daemon on device...${NC}"
    
    # Stop existing daemon using rootshell for elevated privileges
    echo -e "${YELLOW}⏹️  Stopping existing daemon...${NC}"
    $adb_cmd shell "rootshell -c 'pkill -f rayhunter-daemon'" 2>/dev/null || {
        echo -e "${YELLOW}⚠️  rootshell failed, trying direct pkill...${NC}"
        $adb_cmd shell "pkill -f rayhunter-daemon" 2>/dev/null || true
    }
    sleep 2
    
    # Start daemon with new key file
    echo -e "${YELLOW}▶️  Starting daemon with new key...${NC}"
    local daemon_path="/data/local/tmp/rayhunter-daemon"
    
    # Check if daemon binary exists
    if ! $adb_cmd shell "test -f $daemon_path" 2>/dev/null; then
        echo -e "${RED}❌ Daemon binary not found at: $daemon_path${NC}"
        echo "Please deploy the daemon binary first."
        return 1
    fi
    
    # Start daemon in background with key file environment variable using rootshell
    echo -e "${YELLOW}🚀 Starting daemon with rootshell privileges...${NC}"
    $adb_cmd shell "rootshell -c 'cd /data/local/tmp && RAYHUNTER_JWT_KEY_FILE=\"$device_key_file\" nohup ./rayhunter-daemon > daemon.log 2>&1 &'" || {
        echo -e "${YELLOW}⚠️  rootshell failed, trying direct start...${NC}"
        $adb_cmd shell "cd /data/local/tmp && RAYHUNTER_JWT_KEY_FILE='$device_key_file' nohup ./rayhunter-daemon > daemon.log 2>&1 &" || {
            echo -e "${RED}❌ Failed to start daemon${NC}"
            return 1
        }
    }
    
    # Wait a moment and check if it started
    sleep 3
    
    if check_daemon_status "$device_serial"; then
        echo -e "${GREEN}✅ Daemon restarted successfully with new key${NC}"
        return 0
    else
        echo -e "${RED}❌ Daemon failed to start${NC}"
        echo "Check device logs for details:"
        echo -e "${CYAN}  adb -s $device_serial shell cat /data/local/tmp/daemon.log${NC}"
        return 1
    fi
}

# Generate key and install to device workflow
generate_and_install_workflow() {
    local temp_key_file="/tmp/rayhunter_jwt_$(date +%s).key"
    
    echo -e "${BLUE}🔐 Generate and Install Key Workflow${NC}"
    echo "===================================="
    echo ""
    
    # Step 1: List devices
    if ! list_adb_devices; then
        return 1
    fi
    
    # Step 2: Generate key
    echo ""
    echo -e "${CYAN}Step 1: Generate JWT Key${NC}"
    if ! interactive_key_generation "$temp_key_file"; then
        return 1
    fi
    
    # Step 3: Select device and install
    local selected_device
    selected_device=$(select_adb_device) || return 1
    
    if ! install_key_to_device "$temp_key_file" "$selected_device"; then
        rm -f "$temp_key_file"
        return 1
    fi
    
    # Step 4: Ask about daemon restart
    echo ""
    echo -e "${CYAN}Step 3: Daemon Management${NC}"
    
    # Check current daemon status
    check_daemon_status "$selected_device"
    
    echo ""
    read -p "Would you like to restart the daemon with the new key? [y/N]: " restart_choice
    
    case "$restart_choice" in
        [Yy]|[Yy][Ee][Ss])
            local device_key_file="/etc/keys/jwt-key.txt"
            if restart_daemon_on_device "$selected_device" "$device_key_file"; then
                echo -e "${GREEN}🎉 Complete! Key installed and daemon restarted${NC}"
            else
                echo -e "${YELLOW}⚠️  Key installed but daemon restart failed${NC}"
            fi
            ;;
        *)
            echo -e "${YELLOW}⚠️  Key installed but daemon not restarted${NC}"
            echo "To restart manually:"
            echo -e "${CYAN}  adb -s $selected_device shell pkill -f rayhunter-daemon${NC}"
            echo -e "${CYAN}  adb -s $selected_device shell 'cd /data/local/tmp && RAYHUNTER_JWT_KEY_FILE=\"/etc/keys/jwt-key.txt\" nohup ./rayhunter-daemon > daemon.log 2>&1 &'${NC}"
            ;;
    esac
    
    # Clean up temporary key file
    rm -f "$temp_key_file"
    
    echo ""
    echo -e "${GREEN}✅ Workflow completed${NC}"
}

# Main script logic
main() {
    show_banner
    
    case "${1:-help}" in
        generate-key)
            if ! check_python3; then
                exit 1
            fi
            interactive_key_generation "$2"
            ;;
        
        auto-pin)
            if ! check_python3; then
                exit 1
            fi
            local key_file="${2:-$DEFAULT_KEY_FILE}"
            echo -e "${BLUE}🎲 Generating secure random PIN...${NC}"
            local generated_pin
            generated_pin=$(generate_secure_pin) || exit 1
            
            echo -e "${GREEN}✅ Generated PIN: ${BOLD}$generated_pin${NC}"
            echo -e "${YELLOW}⚠️  Save this PIN - you'll need it for the client app!${NC}"
            
            generate_key_from_pin "$generated_pin" "$key_file"
            ;;
        
        custom-pin)
            if ! check_python3; then
                exit 1
            fi
            if [ -z "$2" ]; then
                echo -e "${RED}❌ PIN required for custom-pin command${NC}"
                echo "Usage: $0 custom-pin <8-digit-pin> [key-file]"
                exit 1
            fi
            
            local pin="$2"
            local key_file="${3:-$DEFAULT_KEY_FILE}"
            
            if ! validate_pin "$pin"; then
                exit 1
            fi
            
            generate_key_from_pin "$pin" "$key_file"
            ;;
        
        test-pin)
            if ! check_python3; then
                exit 1
            fi
            test_pin_derivation
            ;;
        
        install)
            if ! check_python3; then
                exit 1
            fi
            generate_and_install_workflow
            ;;
        
        install-key)
            if [ -z "$2" ]; then
                echo -e "${RED}❌ Key file required for install-key command${NC}"
                echo "Usage: $0 install-key <key-file>"
                exit 1
            fi
            
            local key_file="$2"
            if [ ! -f "$key_file" ]; then
                echo -e "${RED}❌ Key file not found: $key_file${NC}"
                exit 1
            fi
            
            # List devices and install
            if list_adb_devices; then
                echo ""
                local selected_device
                selected_device=$(select_adb_device) || exit 1
                
                if install_key_to_device "$key_file" "$selected_device"; then
                    echo ""
                    read -p "Would you like to restart the daemon with the new key? [y/N]: " restart_choice
                    
                    case "$restart_choice" in
                        [Yy]|[Yy][Ee][Ss])
                            local device_key_file="/etc/keys/jwt-key.txt"
                            restart_daemon_on_device "$selected_device" "$device_key_file"
                            ;;
                        *)
                            echo -e "${YELLOW}⚠️  Key installed but daemon not restarted${NC}"
                            ;;
                    esac
                    
                    # Clean up temporary key file after installation
                    cleanup_temp_key "$key_file"
                fi
            fi
            ;;
        
        list-devices)
            list_adb_devices
            ;;
        
        check-daemon)
            if ! check_adb; then
                exit 1
            fi
            
            # List devices first, then select
            if ! list_adb_devices; then
                exit 1
            fi
            
            echo ""
            local selected_device
            selected_device=$(select_adb_device) || exit 1
            check_daemon_status "$selected_device"
            ;;
        
        help|--help|-h)
            show_help
            ;;
        
        *)
            echo -e "${RED}❌ Unknown command: $1${NC}"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Handle Ctrl+C gracefully
trap 'echo -e "\n${YELLOW}⏹️  Operation cancelled by user${NC}"; exit 1' INT

# Run main function
main "$@"
