#!/bin/bash
# env.sh - Environment configuration for vips-cocoa build system
# This file defines versions, URLs, paths, and compiler flags for all targets

set -e

# =============================================================================
# Project Paths
# =============================================================================
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export SCRIPTS_DIR="${PROJECT_ROOT}/Scripts"
export SOURCES_DIR="${PROJECT_ROOT}/Vendor"
export BUILD_DIR="${PROJECT_ROOT}/build"
export BUILD_OUTPUT_DIR="${BUILD_DIR}/output"
export STAGING_DIR="${BUILD_DIR}/staging"
export OUTPUT_DIR="${PROJECT_ROOT}"
export CROSS_FILES_DIR="${SCRIPTS_DIR}/cross-files"
export TOOLCHAINS_DIR="${SCRIPTS_DIR}/toolchains"

# =============================================================================
# iOS Configuration
# =============================================================================
export IOS_MIN_VERSION="15.0"
export MACOS_MIN_VERSION="12.0"
export TVOS_MIN_VERSION="15.0"
export VISIONOS_MIN_VERSION="1.0"

# =============================================================================
# Library Versions
# =============================================================================
export EXPAT_VERSION="2.7.3"
export LIBFFI_VERSION="3.5.2"
export PCRE2_VERSION="10.47"
export LIBJPEG_TURBO_VERSION="3.1.3"
export LIBPNG_VERSION="1.6.54"
export LIBWEBP_VERSION="1.6.0"
export BROTLI_VERSION="1.2.0"
export HIGHWAY_VERSION="1.3.0"
export GLIB_VERSION="2.87.1"
export DAV1D_VERSION="1.5.1"
export LIBJXL_VERSION="0.11.1"
export LIBHEIF_VERSION="1.21.2"
export LIBVIPS_VERSION="8.18.0"

# =============================================================================
# Download URLs
# =============================================================================
export EXPAT_URL="https://github.com/libexpat/libexpat/releases/download/R_${EXPAT_VERSION//./_}/expat-${EXPAT_VERSION}.tar.gz"
export LIBFFI_URL="https://github.com/libffi/libffi/releases/download/v${LIBFFI_VERSION}/libffi-${LIBFFI_VERSION}.tar.gz"
export PCRE2_URL="https://github.com/PCRE2Project/pcre2/releases/download/pcre2-${PCRE2_VERSION}/pcre2-${PCRE2_VERSION}.tar.gz"
export LIBJPEG_TURBO_URL="https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/${LIBJPEG_TURBO_VERSION}/libjpeg-turbo-${LIBJPEG_TURBO_VERSION}.tar.gz"
export LIBPNG_URL="https://downloads.sourceforge.net/project/libpng/libpng16/${LIBPNG_VERSION}/libpng-${LIBPNG_VERSION}.tar.gz"
export LIBWEBP_URL="https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-${LIBWEBP_VERSION}.tar.gz"
export BROTLI_URL="https://github.com/google/brotli/archive/refs/tags/v${BROTLI_VERSION}.tar.gz"
export HIGHWAY_URL="https://github.com/google/highway/archive/refs/tags/${HIGHWAY_VERSION}.tar.gz"

# GLib uses major.minor versioning for directory
GLIB_MAJOR_MINOR="${GLIB_VERSION%.*}"
export GLIB_URL="https://download.gnome.org/sources/glib/${GLIB_MAJOR_MINOR}/glib-${GLIB_VERSION}.tar.xz"

export DAV1D_URL="https://code.videolan.org/videolan/dav1d/-/archive/${DAV1D_VERSION}/dav1d-${DAV1D_VERSION}.tar.gz"
export LIBJXL_URL="https://github.com/libjxl/libjxl/archive/refs/tags/v${LIBJXL_VERSION}.tar.gz"
export LIBHEIF_URL="https://github.com/strukturag/libheif/releases/download/v${LIBHEIF_VERSION}/libheif-${LIBHEIF_VERSION}.tar.gz"
export LIBVIPS_URL="https://github.com/libvips/libvips/releases/download/v${LIBVIPS_VERSION}/vips-${LIBVIPS_VERSION}.tar.xz"

# =============================================================================
# Target Architectures
# =============================================================================
# Default target list (iOS only, overridden by --platform in build.sh)
if [ -z "$TARGETS" ]; then
    export TARGETS="ios ios-sim-arm64 ios-sim-x86_64 catalyst-arm64 catalyst-x86_64"
fi

# =============================================================================
# Platform/Target Mapping
# =============================================================================
# Maps platform family name to its build targets
get_platform_targets() {
    case "$1" in
        ios) echo "ios ios-sim-arm64 ios-sim-x86_64 catalyst-arm64 catalyst-x86_64" ;;
        macos) echo "macos-arm64 macos-x86_64" ;;
        tvos) echo "tvos tvos-sim-arm64 tvos-sim-x86_64" ;;
        visionos) echo "visionos visionos-sim-arm64" ;;
    esac
}

# Returns the minimum deployment version for a given target
get_deployment_target() {
    case "$1" in
        ios|ios-sim-arm64|ios-sim-x86_64|catalyst-arm64|catalyst-x86_64)
            echo "$IOS_MIN_VERSION" ;;
        macos-arm64|macos-x86_64)
            echo "$MACOS_MIN_VERSION" ;;
        tvos|tvos-sim-arm64|tvos-sim-x86_64)
            echo "$TVOS_MIN_VERSION" ;;
        visionos|visionos-sim-arm64)
            echo "$VISIONOS_MIN_VERSION" ;;
    esac
}

# Get target properties using case statements (bash 3.2 compatible)
get_target_arch() {
    case "$1" in
        ios|ios-sim-arm64|catalyst-arm64) echo "arm64" ;;
        ios-sim-x86_64|catalyst-x86_64) echo "x86_64" ;;
        macos-arm64) echo "arm64" ;;
        macos-x86_64) echo "x86_64" ;;
        tvos|tvos-sim-arm64) echo "arm64" ;;
        tvos-sim-x86_64) echo "x86_64" ;;
        visionos|visionos-sim-arm64) echo "arm64" ;;
    esac
}

get_target_sdk() {
    case "$1" in
        ios) echo "iphoneos" ;;
        ios-sim-arm64|ios-sim-x86_64) echo "iphonesimulator" ;;
        catalyst-arm64|catalyst-x86_64) echo "macosx" ;;
        macos-arm64|macos-x86_64) echo "macosx" ;;
        tvos) echo "appletvos" ;;
        tvos-sim-arm64|tvos-sim-x86_64) echo "appletvsimulator" ;;
        visionos) echo "xros" ;;
        visionos-sim-arm64) echo "xrsimulator" ;;
    esac
}

get_target_cmake_platform() {
    case "$1" in
        ios) echo "OS64" ;;
        ios-sim-arm64) echo "SIMULATORARM64" ;;
        ios-sim-x86_64) echo "SIMULATOR64" ;;
        catalyst-arm64) echo "MAC_CATALYST_ARM64" ;;
        catalyst-x86_64) echo "MAC_CATALYST" ;;
        macos-arm64) echo "MAC_ARM64" ;;
        macos-x86_64) echo "MAC" ;;
        tvos) echo "TVOS" ;;
        tvos-sim-arm64) echo "SIMULATORARM64_TVOS" ;;
        tvos-sim-x86_64) echo "SIMULATOR_TVOS" ;;
        visionos) echo "VISIONOS" ;;
        visionos-sim-arm64) echo "SIMULATOR_VISIONOS" ;;
    esac
}

# =============================================================================
# SDK Paths (computed at runtime)
# =============================================================================
get_sdk_path() {
    local sdk="$1"
    xcrun --sdk "$sdk" --show-sdk-path
}

# =============================================================================
# Compiler Configuration
# =============================================================================
get_cc() {
    xcrun --sdk "$1" --find clang
}

get_cxx() {
    xcrun --sdk "$1" --find clang++
}

get_ar() {
    xcrun --sdk "$1" --find ar
}

get_ranlib() {
    xcrun --sdk "$1" --find ranlib
}

get_strip() {
    xcrun --sdk "$1" --find strip
}

# =============================================================================
# Compiler Flags per Target
# =============================================================================
get_cflags() {
    local arch="$1"
    local sdk="$2"
    local target_type="$3"
    local sdk_path=$(get_sdk_path "$sdk")

    local flags="-arch ${arch} -isysroot ${sdk_path} -O2 -DNDEBUG"

    case "$target_type" in
        ios)
            flags+=" -mios-version-min=${IOS_MIN_VERSION}"
            ;;
        ios-sim-arm64|ios-sim-x86_64)
            flags+=" -mios-simulator-version-min=${IOS_MIN_VERSION}"
            ;;
        catalyst-arm64)
            flags+=" -target arm64-apple-ios${IOS_MIN_VERSION}-macabi"
            ;;
        catalyst-x86_64)
            flags+=" -target x86_64-apple-ios${IOS_MIN_VERSION}-macabi"
            ;;
        macos-arm64|macos-x86_64)
            flags+=" -mmacosx-version-min=${MACOS_MIN_VERSION}"
            ;;
        tvos)
            flags+=" -mtvos-version-min=${TVOS_MIN_VERSION}"
            ;;
        tvos-sim-arm64|tvos-sim-x86_64)
            flags+=" -mtvos-simulator-version-min=${TVOS_MIN_VERSION}"
            ;;
        visionos)
            flags+=" -target arm64-apple-xros${VISIONOS_MIN_VERSION}"
            ;;
        visionos-sim-arm64)
            flags+=" -target arm64-apple-xros${VISIONOS_MIN_VERSION}-simulator"
            ;;
    esac

    # Enable position independent code for static libraries
    flags+=" -fPIC"

    echo "$flags"
}

get_ldflags() {
    local arch="$1"
    local sdk="$2"
    local target_type="$3"
    local sdk_path=$(get_sdk_path "$sdk")

    local flags="-arch ${arch} -isysroot ${sdk_path}"

    case "$target_type" in
        ios)
            flags+=" -mios-version-min=${IOS_MIN_VERSION}"
            ;;
        ios-sim-arm64|ios-sim-x86_64)
            flags+=" -mios-simulator-version-min=${IOS_MIN_VERSION}"
            ;;
        catalyst-arm64)
            flags+=" -target arm64-apple-ios${IOS_MIN_VERSION}-macabi"
            ;;
        catalyst-x86_64)
            flags+=" -target x86_64-apple-ios${IOS_MIN_VERSION}-macabi"
            ;;
        macos-arm64|macos-x86_64)
            flags+=" -mmacosx-version-min=${MACOS_MIN_VERSION}"
            ;;
        tvos)
            flags+=" -mtvos-version-min=${TVOS_MIN_VERSION}"
            ;;
        tvos-sim-arm64|tvos-sim-x86_64)
            flags+=" -mtvos-simulator-version-min=${TVOS_MIN_VERSION}"
            ;;
        visionos)
            flags+=" -target arm64-apple-xros${VISIONOS_MIN_VERSION}"
            ;;
        visionos-sim-arm64)
            flags+=" -target arm64-apple-xros${VISIONOS_MIN_VERSION}-simulator"
            ;;
    esac

    echo "$flags"
}

# =============================================================================
# Autotools Host Triple
# =============================================================================
get_host_triple() {
    local arch="$1"

    case "$arch" in
        arm64) echo "aarch64-apple-darwin" ;;
        x86_64) echo "x86_64-apple-darwin" ;;
    esac
}


# =============================================================================
# Number of parallel jobs
# =============================================================================
export JOBS=$(sysctl -n hw.ncpu)
