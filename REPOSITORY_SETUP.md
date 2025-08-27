# Repository Setup Guide

This guide helps you prepare the Rayhunter Merge project for pushing to a GitHub repository.

## 🚨 CRITICAL: Security First

**Before pushing to any public repository, ensure NO sensitive files are included.**

## 📋 Pre-Push Checklist

### 1. ✅ Sensitive Files Removed
- [ ] `jwt-key.txt` is NOT in the repository
- [ ] No `*.key` files
- [ ] No `*.pem` files
- [ ] No `config.toml` with real secrets
- [ ] No `.env` files
- [ ] No device-specific configuration files

### 2. ✅ .gitignore Files Created
- [ ] Root `.gitignore` covers all sensitive patterns
- [ ] `daemon/.gitignore` for Rust build artifacts
- [ ] `lib/.gitignore` for library artifacts
- [ ] `tools/.gitignore` for Python artifacts

### 3. ✅ Documentation Updated
- [ ] `README.md` with comprehensive setup instructions
- [ ] `SECURITY.md` with security guidelines
- [ ] `REPOSITORY_SETUP.md` (this file)
- [ ] Configuration templates created

### 4. ✅ Pre-commit Hook Active
- [ ] `.git/hooks/pre-commit` is executable
- [ ] Hook checks for sensitive files
- [ ] Hook warns about potential secrets

## 🔍 Verification Steps

### Check Current Git Status
```bash
# See what files are staged
git status

# See what files would be committed
git diff --cached --name-only

# Check for sensitive files in the entire repository
find . -name "*.key" -o -name "*.pem" -o -name "jwt-key.txt" -o -name "config.toml"
```

### Verify .gitignore is Working
```bash
# Check if sensitive files are ignored
git check-ignore jwt-key.txt
git check-ignore daemon/config.toml
git check-ignore "*.key"
```

### Test Pre-commit Hook
```bash
# Try to stage a sensitive file (should fail)
echo "test" > test.key
git add test.key
git commit -m "test"  # Should fail due to pre-commit hook
rm test.key
```

## 🚀 GitHub Repository Setup

### 1. Create New Repository
- Go to GitHub and create a new repository
- **DO NOT** initialize with README, .gitignore, or license (we have these)

### 2. Add Remote Origin
```bash
git remote add origin https://github.com/yourusername/rayhunter-merge.git
```

### 3. Push to GitHub
```bash
# First push
git push -u origin main

# Verify sensitive files are not pushed
# Check the repository on GitHub to ensure no sensitive data is visible
```

## 🔒 Security Best Practices

### 1. Use Configuration Templates
- Copy `daemon/config.toml.example` to `daemon/config.toml`
- Fill in device-specific values locally
- Never commit the filled configuration

### 2. Environment Variables
- Use environment variables for secrets in development
- Document required environment variables in README
- Never commit `.env` files

### 3. JWT Key Management
- Generate JWT keys locally for each deployment
- Use strong, random keys (64+ character hex strings)
- Rotate keys regularly

### 4. Device Configuration
- Keep device-specific settings local
- Use configuration templates for documentation
- Document required configuration steps

## 🐛 Troubleshooting

### Sensitive File Already Committed
If you accidentally committed a sensitive file:

```bash
# Remove from git history (DANGEROUS - rewrites history)
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch jwt-key.txt' \
  --prune-empty --tag-name-filter cat -- --all

# Force push (DANGEROUS - rewrites remote history)
git push origin --force

# IMPORTANT: Rotate all exposed keys immediately
```

### Pre-commit Hook Not Working
```bash
# Check if hook is executable
ls -la .git/hooks/pre-commit

# Make executable if needed
chmod +x .git/hooks/pre-commit

# Test the hook manually
.git/hooks/pre-commit
```

## 📚 Additional Resources

- [GitHub Security Best Practices](https://docs.github.com/en/github/creating-cloning-and-archiving-repositories/creating-a-repository-on-github/about-repository-visibility)
- [Git Hooks Documentation](https://git-scm.com/docs/githooks)
- [Rust Security Guidelines](https://rust-lang.github.io/rust-clippy/master/index.html#security)

## 🆘 Emergency Contacts

If you accidentally expose sensitive data:
1. **Immediately** revoke all exposed keys
2. **Rotate** all cryptographic material
3. **Contact** the security team
4. **Review** the entire git history

## ✅ Final Verification

Before pushing to GitHub:

1. **Run the pre-commit hook**: `git commit --allow-empty -m "test"`
2. **Check staged files**: `git diff --cached --name-only`
3. **Verify .gitignore**: `git check-ignore <sensitive-file>`
4. **Review documentation**: Ensure setup instructions are clear
5. **Test locally**: Build and test the project locally

**Remember: Once pushed to a public repository, sensitive data becomes public forever. There's no undo button for security breaches.**
