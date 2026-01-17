#!/bin/bash
# build.sh - Main build orchestrator for vips-cocoa
# Builds libvips and all dependencies as a universal xcframework

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/Scripts/env.sh"
source "${SCRIPT_DIR}/Scripts/utils.sh"

# =============================================================================
# Help and Usage
# =============================================================================
show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Build libvips as a universal xcframework for iOS/Mac Catalyst.

Options:
    -h, --help          Show this help message
    -c, --clean         Clean all build artifacts before building
    -d, --download-only Download sources only, don't build
    -s, --skip-download Skip downloading sources (use existing)
    -l, --list          List all libraries and versions
    -j, --jobs N        Number of parallel jobs (default: auto)
    -f, --framework     Rebuild framework only (fast iteration)
    --skip-to LIB       Skip to building specific library
    --only LIB          Build only specific library

Libraries (in build order):
    expat, libffi, pcre2, libjpeg-turbo, libpng, brotli, highway,
    glib, libwebp, dav1d, libjxl, libheif, libvips

Examples:
    $(basename "$0")                    # Full build
    $(basename "$0") -c                 # Clean build
    $(basename "$0") -f                 # Rebuild framework only (fast)
    $(basename "$0") --skip-to glib     # Skip to glib (assume deps built)
    $(basename "$0") --only libvips     # Build only libvips

EOF
}

list_libraries() {
    cat << EOF
Library Versions:
    expat:          ${EXPAT_VERSION}
    libffi:         ${LIBFFI_VERSION}
    pcre2:          ${PCRE2_VERSION}
    libjpeg-turbo:  ${LIBJPEG_TURBO_VERSION}
    libpng:         ${LIBPNG_VERSION}
    libwebp:        ${LIBWEBP_VERSION}
    brotli:         ${BROTLI_VERSION}
    highway:        ${HIGHWAY_VERSION}
    glib:           ${GLIB_VERSION}
    dav1d:          ${DAV1D_VERSION}
    libjxl:         ${LIBJXL_VERSION}
    libheif:        ${LIBHEIF_VERSION}
    libvips:        ${LIBVIPS_VERSION}

Target Platforms:
    - iOS arm64 (device)
    - iOS Simulator arm64 (Apple Silicon)
    - iOS Simulator x86_64 (Intel)
    - Mac Catalyst arm64 (Apple Silicon)
    - Mac Catalyst x86_64 (Intel)

Minimum iOS Version: ${IOS_MIN_VERSION}
EOF
}

# =============================================================================
# Parse Arguments
# =============================================================================
CLEAN=false
DOWNLOAD_ONLY=false
SKIP_DOWNLOAD=false
FRAMEWORK_ONLY=false
SKIP_TO=""
ONLY_LIB=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -c|--clean)
            CLEAN=true
            shift
            ;;
        -d|--download-only)
            DOWNLOAD_ONLY=true
            shift
            ;;
        -s|--skip-download)
            SKIP_DOWNLOAD=true
            shift
            ;;
        -l|--list)
            list_libraries
            exit 0
            ;;
        -j|--jobs)
            JOBS="$2"
            shift 2
            ;;
        -f|--framework)
            FRAMEWORK_ONLY=true
            shift
            ;;
        --skip-to)
            SKIP_TO="$2"
            shift 2
            ;;
        --only)
            ONLY_LIB="$2"
            shift 2
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# =============================================================================
# Prerequisites Check
# =============================================================================
check_prerequisites() {
    log_step "Checking prerequisites"

    local missing=()

    # Check for required tools
    command -v cmake >/dev/null 2>&1 || missing+=("cmake")
    command -v meson >/dev/null 2>&1 || missing+=("meson")
    command -v ninja >/dev/null 2>&1 || missing+=("ninja")
    command -v pkg-config >/dev/null 2>&1 || missing+=("pkg-config")
    command -v xcodebuild >/dev/null 2>&1 || missing+=("xcodebuild (Xcode)")
    command -v xcrun >/dev/null 2>&1 || missing+=("xcrun (Xcode Command Line Tools)")

    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing required tools: ${missing[*]}"
        echo ""
        echo "Install with:"
        echo "  brew install cmake meson ninja pkg-config"
        echo "  xcode-select --install"
        exit 1
    fi

    # Check Xcode SDK availability
    if ! xcrun --sdk iphoneos --show-sdk-path >/dev/null 2>&1; then
        log_error "iOS SDK not found. Please install Xcode with iOS support."
        exit 1
    fi

    log_success "All prerequisites satisfied"
}

# =============================================================================
# Build Libraries
# =============================================================================
# Build order (respecting dependencies)
BUILD_ORDER=(
    "expat"
    "libffi"
    "pcre2"
    "libjpeg-turbo"
    "libpng"
    "brotli"
    "highway"
    "glib"
    "libwebp"
    "dav1d"
    "libjxl"
    "libheif"
    "libvips"
)

should_build() {
    local lib="$1"

    # If --only specified, only build that library
    if [ -n "$ONLY_LIB" ]; then
        [ "$lib" = "$ONLY_LIB" ]
        return
    fi

    # If --skip-to specified, skip until we reach that library
    if [ -n "$SKIP_TO" ]; then
        if [ "$SKIP_TO_REACHED" != "true" ]; then
            if [ "$lib" = "$SKIP_TO" ]; then
                SKIP_TO_REACHED=true
                return 0
            fi
            return 1
        fi
    fi

    return 0
}

build_library() {
    local lib="$1"
    local script="${SCRIPTS_DIR}/build-${lib}.sh"

    if [ ! -f "$script" ]; then
        log_error "Build script not found: ${script}"
        return 1
    fi

    log_step "Building ${lib}"
    bash "$script"
}

# =============================================================================
# Main Build Process
# =============================================================================
main() {
    local start_time=$(date +%s)

    echo "=================================================="
    echo "  vips-cocoa build system"
    echo "  Building libvips ${LIBVIPS_VERSION} for iOS/Catalyst"
    echo "=================================================="
    echo ""

    check_prerequisites

    # Clean if requested
    if [ "$CLEAN" = true ]; then
        log_step "Cleaning build artifacts"
        clean_all
    fi

    # Framework-only mode: just rebuild the wrapper and xcframework
    if [ "$FRAMEWORK_ONLY" = true ]; then
        log_step "Rebuilding framework only"
        bash "${SCRIPTS_DIR}/create-xcframework.sh"

        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        echo ""
        log_success "Framework rebuilt in ${duration}s"
        echo "Output: ${OUTPUT_DIR}/VIPSKit.xcframework"
        return
    fi

    # Download sources
    if [ "$SKIP_DOWNLOAD" != true ]; then
        bash "${SCRIPTS_DIR}/download-sources.sh"
    fi

    if [ "$DOWNLOAD_ONLY" = true ]; then
        log_success "Download complete"
        exit 0
    fi

    # Build all libraries
    SKIP_TO_REACHED=false
    for lib in "${BUILD_ORDER[@]}"; do
        if should_build "$lib"; then
            build_library "$lib"
        else
            log_info "Skipping ${lib}"
        fi
    done

    # Create xcframework
    if [ -z "$ONLY_LIB" ] || [ "$ONLY_LIB" = "xcframework" ]; then
        bash "${SCRIPTS_DIR}/create-xcframework.sh"
    fi

    # Report completion
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))

    echo ""
    echo "=================================================="
    log_success "Build completed in ${minutes}m ${seconds}s"
    echo "=================================================="
    echo ""
    echo "Output: ${OUTPUT_DIR}/VIPSKit.xcframework"
    echo ""
}

main "$@"
