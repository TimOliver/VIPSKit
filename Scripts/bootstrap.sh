#!/bin/bash
#
# bootstrap.sh - Download dependencies for VIPSKit development
#
# This script is run automatically by Xcode on first build, or can be run manually.
# It downloads:
#   1. Pre-built static libraries (from GitHub releases)
#   2. libvips source code (for source-level debugging)
#

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuration
VIPS_VERSION="8.18.0"
PREBUILT_VERSION="1.0.0"  # Update this when releasing new pre-built artifacts
GITHUB_REPO="TimOliver/VIPSKit"
PREBUILT_URL="https://github.com/${GITHUB_REPO}/releases/download/v${PREBUILT_VERSION}/vipskit-prebuilt-${PREBUILT_VERSION}.tar.gz"
VIPS_SOURCE_URL="https://github.com/libvips/libvips/releases/download/v${VIPS_VERSION}/vips-${VIPS_VERSION}.tar.xz"

# Directories
STAGING_DIR="${PROJECT_ROOT}/build/staging"
VENDOR_DIR="${PROJECT_ROOT}/Vendor"
VIPS_SOURCE_DIR="${VENDOR_DIR}/vips-${VIPS_VERSION}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[VIPSKit]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[VIPSKit]${NC} $1"
}

log_error() {
    echo -e "${RED}[VIPSKit]${NC} $1"
}

# Check if we need to download anything
needs_download() {
    # Check for pre-built static libraries
    if [ ! -d "${STAGING_DIR}/glib" ] || [ ! -d "${STAGING_DIR}/libjpeg-turbo" ]; then
        return 0
    fi

    # Check for libvips source
    if [ ! -d "${VIPS_SOURCE_DIR}/libvips" ]; then
        return 0
    fi

    return 1
}

download_prebuilt_libraries() {
    log_info "Downloading pre-built static libraries..."

    mkdir -p "${PROJECT_ROOT}/build"
    cd "${PROJECT_ROOT}/build"

    # Download
    if command -v curl &> /dev/null; then
        curl -L -o prebuilt.tar.gz "${PREBUILT_URL}" || {
            log_error "Failed to download pre-built libraries from:"
            log_error "  ${PREBUILT_URL}"
            log_error ""
            log_error "If this is a fresh clone, you may need to build from source:"
            log_error "  ./build.sh"
            exit 1
        }
    elif command -v wget &> /dev/null; then
        wget -O prebuilt.tar.gz "${PREBUILT_URL}" || {
            log_error "Failed to download pre-built libraries"
            exit 1
        }
    else
        log_error "Neither curl nor wget found. Please install one."
        exit 1
    fi

    # Extract
    log_info "Extracting pre-built libraries..."
    tar -xzf prebuilt.tar.gz
    rm prebuilt.tar.gz

    log_info "Pre-built libraries installed to build/staging/"
}

download_vips_source() {
    log_info "Downloading libvips ${VIPS_VERSION} source..."

    mkdir -p "${VENDOR_DIR}"
    cd "${VENDOR_DIR}"

    # Download
    if command -v curl &> /dev/null; then
        curl -L -o vips-source.tar.xz "${VIPS_SOURCE_URL}" || {
            log_error "Failed to download libvips source"
            exit 1
        }
    elif command -v wget &> /dev/null; then
        wget -O vips-source.tar.xz "${VIPS_SOURCE_URL}"
    fi

    # Extract
    log_info "Extracting libvips source..."
    tar -xf vips-source.tar.xz
    rm vips-source.tar.xz

    log_info "libvips source installed to Vendor/vips-${VIPS_VERSION}/"
}

configure_xcode_project() {
    # Check if ruby and xcodeproj gem are available
    if ! command -v ruby &> /dev/null; then
        log_warn "Ruby not found - skipping Xcode project configuration"
        log_warn "You may need to run: ruby Scripts/add-libvips-target.rb"
        return
    fi

    if ! ruby -e "require 'xcodeproj'" 2>/dev/null; then
        log_warn "xcodeproj gem not found - skipping Xcode project configuration"
        log_warn "Install with: gem install xcodeproj"
        log_warn "Then run: ruby Scripts/add-libvips-target.rb"
        return
    fi

    log_info "Configuring Xcode project..."
    ruby "${SCRIPT_DIR}/add-libvips-target.rb"
}

main() {
    log_info "VIPSKit Bootstrap"
    log_info "================="

    if ! needs_download; then
        log_info "Dependencies already present. Nothing to do."
        exit 0
    fi

    # Download pre-built libraries if missing
    if [ ! -d "${STAGING_DIR}/glib" ]; then
        download_prebuilt_libraries
    else
        log_info "Pre-built libraries already present."
    fi

    # Download libvips source if missing
    if [ ! -d "${VIPS_SOURCE_DIR}/libvips" ]; then
        download_vips_source
    else
        log_info "libvips source already present."
    fi

    # Configure Xcode project
    configure_xcode_project

    log_info ""
    log_info "Bootstrap complete!"
    log_info "You can now build and run tests in Xcode."
}

main "$@"
