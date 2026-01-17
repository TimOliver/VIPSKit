#!/bin/bash
# build-libjpeg-turbo.sh - Build libjpeg-turbo for all iOS/Catalyst targets

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"
source "${SCRIPT_DIR}/utils.sh"

LIB_NAME="libjpeg-turbo"
SRC_ARCHIVE="libjpeg-turbo-${LIBJPEG_TURBO_VERSION}.tar.gz"
SRC_DIR="${SOURCES_DIR}/libjpeg-turbo-${LIBJPEG_TURBO_VERSION}"

# Extract source
extract_source "$LIB_NAME" "$SRC_ARCHIVE" "$SRC_DIR"

build_libjpeg_turbo() {
    local target="$1"
    local arch=$(get_target_arch "$target")
    local platform=$(get_target_cmake_platform "$target")

    local build_dir="${BUILD_OUTPUT_DIR}/${LIB_NAME}/${target}"
    local install_dir="${STAGING_DIR}/${LIB_NAME}/${target}"

    rm -rf "$build_dir"
    mkdir -p "$build_dir"
    cd "$build_dir"

    cmake "$SRC_DIR" \
        -DCMAKE_TOOLCHAIN_FILE="${TOOLCHAINS_DIR}/ios.toolchain.cmake" \
        -DPLATFORM="$platform" \
        -DDEPLOYMENT_TARGET="${IOS_MIN_VERSION}" \
        -DCMAKE_INSTALL_PREFIX="$install_dir" \
        -DCMAKE_BUILD_TYPE=Release \
        -DENABLE_BITCODE=OFF \
        -DENABLE_SHARED=OFF \
        -DENABLE_STATIC=ON \
        -DWITH_TURBOJPEG=ON \
        -DWITH_JPEG8=ON \
        -DWITH_SIMD=ON

    cmake --build . --parallel "$JOBS"
    cmake --install .

    verify_library "${install_dir}/lib/libjpeg.a" "$arch"
    verify_library "${install_dir}/lib/libturbojpeg.a" "$arch"
}

build_for_all_targets "$LIB_NAME" build_libjpeg_turbo

log_success "libjpeg-turbo build complete"
