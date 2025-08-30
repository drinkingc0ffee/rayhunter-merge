#!/bin/bash

# Script to optimize the rayhunter-daemon binary for embedded Linux
# This script creates a .cargo/config.toml file with optimization settings

echo "Setting up Rust optimization for embedded Linux target"
echo "===================================================="

# Create .cargo directory if it doesn't exist
mkdir -p .cargo

# Create config.toml with optimization settings
cat > .cargo/config.toml << EOL
[target.armv7-unknown-linux-musleabihf]
rustflags = [
  "-C", "opt-level=z",
  "-C", "lto=true",
  "-C", "codegen-units=1",
  "-C", "panic=abort",
  "-C", "strip=true",
]

[profile.release]
opt-level = 'z'     # Optimize for size
lto = true          # Enable Link Time Optimization
codegen-units = 1   # Reduce parallel code generation units for better optimization
panic = 'abort'     # Abort on panic (smaller binary)
strip = true        # Strip symbols from binary
EOL

echo "Created .cargo/config.toml with optimization settings for embedded Linux"
echo "This will produce a smaller binary optimized for the target system"
echo ""
echo "To build the optimized binary, run:"
echo "docker exec -it orbic-aug-25-25-container cargo build --release --target=\"armv7-unknown-linux-musleabihf\" --bin rayhunter-daemon"
