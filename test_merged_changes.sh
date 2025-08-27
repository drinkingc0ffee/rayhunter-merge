#!/bin/bash

# Test script for verifying merged changes

echo "Testing merged changes..."

# Check if all necessary files exist
echo "Checking for required files..."
FILES=(
  "daemon/src/gps.rs"
  "daemon/src/gps_v2.rs"
  "daemon/src/bin/gps_jwt_pin.rs"
  "lib/src/cellular_info.rs"
  "lib/src/analysis/cellular_network.rs"
)

for file in "${FILES[@]}"; do
  if [ -f "$file" ]; then
    echo "✅ $file exists"
  else
    echo "❌ $file does not exist"
    exit 1
  fi
done

# Check if modules are properly registered
echo "Checking module registrations..."

if grep -q "mod gps;" daemon/src/main.rs && grep -q "mod gps_v2;" daemon/src/main.rs; then
  echo "✅ GPS modules registered in main.rs"
else
  echo "❌ GPS modules not properly registered in main.rs"
  exit 1
fi

if grep -q "pub mod cellular_info;" lib/src/lib.rs; then
  echo "✅ cellular_info module registered in lib.rs"
else
  echo "❌ cellular_info module not properly registered in lib.rs"
  exit 1
fi

if grep -q "pub mod cellular_network;" lib/src/analysis/mod.rs; then
  echo "✅ cellular_network module registered in analysis/mod.rs"
else
  echo "❌ cellular_network module not properly registered in analysis/mod.rs"
  exit 1
fi

# Check if GPS v2 API route is registered
if grep -q ".route(\"/api/v2/gps\", post(gps_v2::gps_api_v2))" daemon/src/main.rs; then
  echo "✅ GPS v2 API route registered"
else
  echo "❌ GPS v2 API route not registered"
  exit 1
fi

# Check if JWT configuration is added
if grep -q "pub jwt_secret: Option<String>" daemon/src/config.rs; then
  echo "✅ JWT configuration added to Config struct"
else
  echo "❌ JWT configuration not added to Config struct"
  exit 1
fi

echo "All tests passed! Merged changes verified."
