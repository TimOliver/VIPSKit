#!/bin/bash
# build-libwebp.sh - Build libwebp for all iOS/Catalyst targets

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"
source "${SCRIPT_DIR}/utils.sh"

LIB_NAME="libwebp"
SRC_ARCHIVE="libwebp-${LIBWEBP_VERSION}.tar.gz"
SRC_DIR="${SOURCES_DIR}/libwebp-${LIBWEBP_VERSION}"

# Extract source
extract_source "$LIB_NAME" "$SRC_ARCHIVE" "$SRC_DIR"

build_libwebp() {
    local target="$1"
    local arch=$(get_target_arch "$target")
    local platform=$(get_target_cmake_platform "$target")

    local build_dir="${BUILD_OUTPUT_DIR}/${LIB_NAME}/${target}"
    local install_dir="${STAGING_DIR}/${LIB_NAME}/${target}"

    # Get dependency paths
    local libpng_dir="${STAGING_DIR}/libpng/${target}"
    local libjpeg_dir="${STAGING_DIR}/libjpeg-turbo/${target}"

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
        -DBUILD_SHARED_LIBS=OFF \
        -DWEBP_BUILD_ANIM_UTILS=OFF \
        -DWEBP_BUILD_CWEBP=OFF \
        -DWEBP_BUILD_DWEBP=OFF \
        -DWEBP_BUILD_GIF2WEBP=OFF \
        -DWEBP_BUILD_IMG2WEBP=OFF \
        -DWEBP_BUILD_VWEBP=OFF \
        -DWEBP_BUILD_WEBPINFO=OFF \
        -DWEBP_BUILD_LIBWEBPMUX=ON \
        -DWEBP_BUILD_WEBPMUX=OFF \
        -DWEBP_BUILD_EXTRAS=OFF \
        -DWEBP_ENABLE_SIMD=ON \
        -DPNG_PNG_INCLUDE_DIR="${libpng_dir}/include" \
        -DPNG_LIBRARY="${libpng_dir}/lib/libpng16.a" \
        -DJPEG_INCLUDE_DIR="${libjpeg_dir}/include" \
        -DJPEG_LIBRARY="${libjpeg_dir}/lib/libjpeg.a"

    cmake --build . --parallel "$JOBS"
    cmake --install .

    # Fix pkg-config file for static linking - include libsharpyuv in main Libs line
    local pc_file="${install_dir}/lib/pkgconfig/libwebp.pc"
    if [ -f "$pc_file" ]; then
        sed -i.bak 's|^Libs: -L${libdir} -lwebp|Libs: -L${libdir} -lwebp -lsharpyuv|' "$pc_file"
        rm -f "${pc_file}.bak"
    fi

    verify_library "${install_dir}/lib/libwebp.a" "$arch"
    verify_library "${install_dir}/lib/libwebpmux.a" "$arch"
    verify_library "${install_dir}/lib/libwebpdemux.a" "$arch"
}

build_for_all_targets "$LIB_NAME" build_libwebp

log_success "libwebp build complete"
