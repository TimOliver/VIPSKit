#!/bin/bash
# build.sh - Build VIPSKit.xcframework
#
# Builds VIPSKit as a dynamic framework wrapping the static vips.xcframework,
# then packages as an xcframework for iOS, iOS Simulator, and Mac Catalyst.
#
# Prerequisites:
#   - Xcode with command-line tools
#   - Frameworks/vips.xcframework (static, from vips-cocoa)

set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${ROOT_DIR}/build"
ARCHIVE_DIR="${BUILD_DIR}/archives"
XCFRAMEWORK_DIR="${ROOT_DIR}/VIPSKit.xcframework"
PROJECT="${ROOT_DIR}/VIPSKit.xcodeproj"
SCHEME="VIPSKit"

# =============================================================================
# Help
# =============================================================================
show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Build VIPSKit.xcframework from the Swift wrapper + static vips.xcframework.

Options:
    -h, --help     Show this help message
    -c, --clean    Clean build artifacts before building
    -f, --fast     Skip archiving, just build framework for current platform

Prerequisites:
    Frameworks/vips.xcframework must exist (copy from vips-cocoa build output).

EOF
}

# =============================================================================
# Parse Arguments
# =============================================================================
CLEAN=false
FAST=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help) show_help; exit 0 ;;
        -c|--clean) CLEAN=true; shift ;;
        -f|--fast) FAST=true; shift ;;
        *) echo "Unknown option: $1"; show_help; exit 1 ;;
    esac
done

# =============================================================================
# Verify prerequisites
# =============================================================================
if [ ! -d "${ROOT_DIR}/Frameworks/vips.xcframework" ]; then
    echo "❌ Frameworks/vips.xcframework not found"
    echo "   Copy from vips-cocoa: cp -R ~/Developer/vips-cocoa/build/xcframeworks/ios/static/vips.xcframework Frameworks/"
    exit 1
fi

# =============================================================================
# Clean
# =============================================================================
if [ "$CLEAN" = true ]; then
    echo "🧹 Cleaning..."
    rm -rf "${BUILD_DIR}" "${XCFRAMEWORK_DIR}"
fi

mkdir -p "${ARCHIVE_DIR}"

# =============================================================================
# Fast mode: just build for current platform
# =============================================================================
if [ "$FAST" = true ]; then
    echo "⚡ Building VIPSKit for current platform..."
    xcodebuild build \
        -project "${PROJECT}" \
        -scheme "${SCHEME}" \
        -configuration Release \
        -quiet
    echo "✅ Build complete"
    exit 0
fi

# =============================================================================
# Archive for each platform
# =============================================================================
echo "📦 Building VIPSKit.xcframework..."
echo ""

# iOS Device
echo "  → Archiving for iOS..."
xcodebuild archive \
    -project "${PROJECT}" \
    -scheme "${SCHEME}" \
    -configuration Release \
    -destination "generic/platform=iOS" \
    -archivePath "${ARCHIVE_DIR}/VIPSKit-ios" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    -quiet

# iOS Simulator
echo "  → Archiving for iOS Simulator..."
xcodebuild archive \
    -project "${PROJECT}" \
    -scheme "${SCHEME}" \
    -configuration Release \
    -destination "generic/platform=iOS Simulator" \
    -archivePath "${ARCHIVE_DIR}/VIPSKit-sim" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    -quiet

# Mac Catalyst
echo "  → Archiving for Mac Catalyst..."
xcodebuild archive \
    -project "${PROJECT}" \
    -scheme "${SCHEME}" \
    -configuration Release \
    -destination "generic/platform=macOS,variant=Mac Catalyst" \
    -archivePath "${ARCHIVE_DIR}/VIPSKit-catalyst" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    -quiet

# =============================================================================
# Create xcframework
# =============================================================================
echo "  → Creating xcframework..."
rm -rf "${XCFRAMEWORK_DIR}"

xcodebuild -create-xcframework \
    -framework "${ARCHIVE_DIR}/VIPSKit-ios.xcarchive/Products/Library/Frameworks/VIPSKit.framework" \
    -framework "${ARCHIVE_DIR}/VIPSKit-sim.xcarchive/Products/Library/Frameworks/VIPSKit.framework" \
    -framework "${ARCHIVE_DIR}/VIPSKit-catalyst.xcarchive/Products/Library/Frameworks/VIPSKit.framework" \
    -output "${XCFRAMEWORK_DIR}"

echo ""
echo "✅ VIPSKit.xcframework created successfully"
echo "   ${XCFRAMEWORK_DIR}"
