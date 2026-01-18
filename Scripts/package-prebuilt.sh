#!/bin/bash
#
# package-prebuilt.sh - Package pre-built static libraries for GitHub release
#
# Run this after a successful ./build.sh to create a tarball for distribution.
# Upload the resulting file to GitHub releases.
#

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

VERSION="${1:-1.0.0}"
OUTPUT_FILE="vipskit-prebuilt-${VERSION}.tar.gz"

STAGING_DIR="${PROJECT_ROOT}/build/staging"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[Package]${NC} $1"
}

log_error() {
    echo -e "${RED}[Package]${NC} $1"
}

# Verify staging directory exists
if [ ! -d "${STAGING_DIR}" ]; then
    log_error "build/staging/ not found. Run ./build.sh first."
    exit 1
fi

# Check that all required libraries are present
REQUIRED_LIBS=(
    "glib"
    "libjpeg-turbo"
    "libpng"
    "libwebp"
    "libjxl"
    "libheif"
    "highway"
    "expat"
    "dav1d"
    "brotli"
    "pcre2"
    "libffi"
)

log_info "Checking for required libraries..."
for lib in "${REQUIRED_LIBS[@]}"; do
    if [ ! -d "${STAGING_DIR}/${lib}" ]; then
        log_error "Missing: ${lib}"
        log_error "Run ./build.sh to build all dependencies first."
        exit 1
    fi
done

log_info "All required libraries present."

# Create the tarball
log_info "Creating ${OUTPUT_FILE}..."
cd "${PROJECT_ROOT}/build"

tar -czf "${OUTPUT_FILE}" staging/

# Move to project root for easy access
mv "${OUTPUT_FILE}" "${PROJECT_ROOT}/"

log_info ""
log_info "Created: ${OUTPUT_FILE}"
log_info "Size: $(du -h "${PROJECT_ROOT}/${OUTPUT_FILE}" | cut -f1)"
log_info ""
log_info "Upload this file to GitHub releases:"
log_info "  https://github.com/YOUR_USERNAME/VIPSKit/releases/new"
log_info ""
log_info "Then update PREBUILT_VERSION in Scripts/bootstrap.sh to match."
