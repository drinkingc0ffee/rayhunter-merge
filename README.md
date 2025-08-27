# Rayhunter Merge

A comprehensive cellular network monitoring and analysis system with GPS tracking capabilities and JWT authentication.

## 🚀 Features

- **Cellular Network Monitoring**: Real-time analysis of cellular network behavior
- **GPS Tracking**: Secure GPS data collection with JWT authentication
- **Captive Portal**: WiFi hotspot with traffic redirection capabilities
- **Cross-Platform**: Supports ARM devices with Docker-based cross-compilation
- **Security**: JWT-based authentication with comprehensive security features

## 🏗️ Architecture

```
rayhunter-merge/
├── daemon/           # Main daemon application (Rust)
├── lib/              # Core library components (Rust)
├── tools/            # Utility scripts and tools
├── installer/        # Installation and deployment scripts
├── doc/              # Documentation
└── dist/             # Distribution and configuration templates
```

## 🔧 Prerequisites

- **Rust**: Latest stable version
- **Docker**: For cross-compilation to ARM targets
- **ADB**: Android Debug Bridge for device deployment
- **Python 3**: For utility scripts and testing

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd rayhunter-merge
```

### 2. Setup Sensitive Files (CRITICAL)

**⚠️ NEVER commit these files to version control:**

```bash
# Create JWT key file (required for GPS API)
echo "your-secret-key-here" > jwt-key.txt

# Create device configuration (if needed)
cp dist/config.toml.in daemon/config.toml
# Edit daemon/config.toml with your device settings
```

### 3. Build the Project

```bash
# Build for ARM target
docker exec -it orbic-aug-25-25-container cargo build --release --target="armv7-unknown-linux-musleabihf" --bin rayhunter-daemon

# Build GPS JWT utility
docker exec -it orbic-aug-25-25-container cargo build --release --target="armv7-unknown-linux-musleabihf" --bin gps_jwt_pin
```

### 4. Deploy to Device

```bash
# Deploy daemon
./deploy_daemon.sh

# Deploy GPS utility
./deploy_gps_jwt_pin.sh
```

## 🔐 Security Configuration

### JWT Authentication

The GPS v2 API uses JWT tokens for authentication:

```bash
# Generate JWT token (example)
python3 create_jwt_token.py

# Test GPS API
curl -X POST http://localhost:8080/api/v2/gps \
  -H "Authorization: Bearer <your-jwt-token>"
```

### Required JWT Claims

```json
{
  "lat": 37.7749,
  "lon": -122.4194,
  "exp": 1640995200,
  "iat": 1640995170,
  "jti": "unique_id",
  "accuracy": 5.0,
  "altitude": 100.0,
  "speed": 25.0,
  "heading": 180.0
}
```

## 🌐 Captive Portal

Enable the captive portal to redirect WiFi traffic:

```bash
# Start captive portal
adb shell rootshell -c "'/data/rayhunter/start_captive_portal.sh'"

# Stop captive portal
adb shell rootshell -c "'/data/rayhunter/stop_captive_portal.sh'"
```

## 🧪 Testing

### Test GPS API

```bash
# Test with valid JWT
./test_gps_api.sh

# Test with Python script
python3 test_gps_v2_api.py
```

### Test Captive Portal

```bash
# Test DNS redirection
./tools/test_android_captive_final.sh
```

## 📁 Project Structure

- **`daemon/`**: Main application with GPS API and cellular monitoring
- **`lib/`**: Core libraries for cellular analysis and data processing
- **`tools/`**: Utility scripts for deployment, testing, and configuration
- **`installer/`**: Installation and deployment automation
- **`doc/`**: Project documentation and guides

## 🔒 Security Considerations

- **JWT Keys**: Never commit `jwt-key.txt` or any cryptographic keys
- **Configuration**: Use templates and environment variables for sensitive data
- **Device Access**: Ensure proper authentication for device deployment
- **Network Security**: Captive portal should only be used in controlled environments

## 🐛 Troubleshooting

### Common Issues

1. **Build Failures**: Ensure Docker container is running and Rust toolchain is installed
2. **Deployment Issues**: Check ADB connection and device permissions
3. **JWT Authentication**: Verify JWT key file exists and token format is correct
4. **Captive Portal**: Check network interface configuration and dnsmasq status

### Logs

```bash
# Check daemon logs
adb shell cat /data/rayhunter/rayhunter.log

# Check captive portal logs
adb shell cat /data/rayhunter/captive_portal.log
```

## 📚 Documentation

- [Security Guidelines](SECURITY.md)
- [Code of Conduct](CODE_OF_CONDUCT.md)
- [License](LICENSE)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. **Verify no sensitive files are included**
5. Submit a pull request

## 📄 License

This project is licensed under the terms specified in the [LICENSE](LICENSE) file.

## ⚠️ Disclaimer

This tool is for educational and research purposes. Use responsibly and in accordance with applicable laws and regulations.
