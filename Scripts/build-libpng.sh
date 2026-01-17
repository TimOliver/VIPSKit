#!/bin/bash
# build-libpng.sh - Build libpng for all iOS/Catalyst targets

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"
source "${SCRIPT_DIR}/utils.sh"

LIB_NAME="libpng"
SRC_ARCHIVE="libpng-${LIBPNG_VERSION}.tar.gz"
SRC_DIR="${SOURCES_DIR}/libpng-${LIBPNG_VERSION}"

# Extract source
extract_source "$LIB_NAME" "$SRC_ARCHIVE" "$SRC_DIR"

build_libpng() {
    local target="$1"
    local arch=$(get_target_arch "$target")
    local platform=$(get_target_cmake_platform "$target")

    local build_dir="${BUILD_OUTPUT_DIR}/${LIB_NAME}/${target}"
    local install_dir="${STAGING_DIR}/${LIB_NAME}/${target}"

    rm -rf "$build_dir"
    mkdir -p "$build_dir"
    cd "$build_dir"

    # libpng uses system zlib which is available in iOS SDK
    cmake "$SRC_DIR" \
        -DCMAKE_TOOLCHAIN_FILE="${TOOLCHAINS_DIR}/ios.toolchain.cmake" \
        -DPLATFORM="$platform" \
        -DDEPLOYMENT_TARGET="${IOS_MIN_VERSION}" \
        -DCMAKE_INSTALL_PREFIX="$install_dir" \
        -DCMAKE_BUILD_TYPE=Release \
        -DENABLE_BITCODE=OFF \
        -DPNG_SHARED=OFF \
        -DPNG_STATIC=ON \
        -DPNG_TESTS=OFF \
        -DPNG_FRAMEWORK=OFF \
        -DPNG_HARDWARE_OPTIMIZATIONS=ON

    cmake --build . --parallel "$JOBS"
    cmake --install .

    verify_library "${install_dir}/lib/libpng16.a" "$arch"
}

build_for_all_targets "$LIB_NAME" build_libpng

log_success "libpng build complete"
