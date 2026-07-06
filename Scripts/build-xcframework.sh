#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_DIR="$ROOT_DIR/SourcePackage"
BUILD_DIR="$ROOT_DIR/build"
DERIVED_DATA="$BUILD_DIR/DerivedData"
OUTPUT="$ROOT_DIR/PGameSDK.xcframework"

rm -rf "$BUILD_DIR" "$OUTPUT"
mkdir -p "$BUILD_DIR"

cd "$SOURCE_DIR"

build_framework() {
  local destination="$1"
  local sdk_name="$2"
  local product_dir="$DERIVED_DATA/Build/Products/Release-$sdk_name"
  local framework_dir="$product_dir/PackageFrameworks/PGameSDK.framework"
  local swiftmodule_dir="$product_dir/PGameSDK.swiftmodule"
  local generated_header="$DERIVED_DATA/Build/Intermediates.noindex/GeneratedModuleMaps-$sdk_name/PGameSDK-Swift.h"

  xcodebuild build \
    -scheme PGameSDK \
    -configuration Release \
    -destination "$destination" \
    -derivedDataPath "$DERIVED_DATA" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES

  mkdir -p "$framework_dir/Modules" "$framework_dir/Headers"
  rm -rf "$framework_dir/Modules/PGameSDK.swiftmodule"
  cp -R "$swiftmodule_dir" "$framework_dir/Modules/PGameSDK.swiftmodule"
  cp "$generated_header" "$framework_dir/Headers/PGameSDK-Swift.h"

  cat > "$framework_dir/Modules/module.modulemap" <<'MODULEMAP'
framework module PGameSDK {
  header "../Headers/PGameSDK-Swift.h"
  export *
}
MODULEMAP
}

build_framework "generic/platform=iOS" "iphoneos"
build_framework "generic/platform=iOS Simulator" "iphonesimulator"

DEVICE_PRODUCTS="$DERIVED_DATA/Build/Products/Release-iphoneos"
SIMULATOR_PRODUCTS="$DERIVED_DATA/Build/Products/Release-iphonesimulator"

xcodebuild -create-xcframework \
  -framework "$DEVICE_PRODUCTS/PackageFrameworks/PGameSDK.framework" \
  -debug-symbols "$DEVICE_PRODUCTS/PGameSDK.framework.dSYM" \
  -framework "$SIMULATOR_PRODUCTS/PackageFrameworks/PGameSDK.framework" \
  -debug-symbols "$SIMULATOR_PRODUCTS/PGameSDK.framework.dSYM" \
  -output "$OUTPUT"

echo "Built $OUTPUT"
