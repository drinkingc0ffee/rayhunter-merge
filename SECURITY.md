# Security Guidelines

## ⚠️ CRITICAL: Never Commit Sensitive Files

This repository contains security-sensitive components. **NEVER** commit the following files:

### 🔐 JWT and Cryptographic Keys
- `jwt-key.txt` - Contains the secret key for JWT token generation/validation
- `*.key` - Any cryptographic key files
- `*.pem` - Certificate or key files
- `*.p12` - PKCS#12 certificate files
- `*.pfx` - Personal Information Exchange files

### 🔧 Configuration Files with Sensitive Data
- `config.toml` - May contain device-specific configuration
- `config.local.toml` - Local development configuration
- `*.env` - Environment variable files
- `secrets.toml` - Secret configuration files

### 📱 Device-Specific Files
- `device_config/` - Device-specific configuration directories
- `device_keys/` - Device cryptographic keys
- `device_certs/` - Device certificates

### 🚨 What Happens If You Commit Sensitive Files

1. **Immediate Security Risk**: Cryptographic keys become public
2. **JWT Compromise**: Attackers can forge valid authentication tokens
3. **Device Compromise**: Unauthorized access to devices
4. **Repository Compromise**: Entire project security is compromised

## ✅ Safe to Commit

- Source code (`.rs` files)
- Documentation (`.md` files)
- Build scripts (`.sh`, `.ps1` files)
- Configuration templates (`.toml.in` files)
- Docker files (`.dockerfile`)
- CI/CD configuration (`.github/`, `.gitlab-ci.yml`)

## 🔒 Pre-commit Checklist

Before committing, verify:
- [ ] No `.key` files in the commit
- [ ] No `jwt-key.txt` in the commit
- [ ] No `config.toml` with real secrets
- [ ] No `.env` files
- [ ] No device-specific configuration files

## 🛠️ Development Setup

1. **Copy sensitive files locally**: Never commit them
2. **Use environment variables**: For development secrets
3. **Use configuration templates**: With placeholder values
4. **Document required files**: In README.md

## 🚨 Emergency Response

If sensitive files are accidentally committed:
1. **Immediately revoke** any exposed keys
2. **Rotate** all cryptographic material
3. **Contact** security team
4. **Review** git history for other sensitive data

## 📞 Security Contact

For security issues, contact the project maintainers immediately.
