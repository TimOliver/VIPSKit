#!/bin/bash
# build-libjxl.sh - Build libjxl (JPEG-XL) for all iOS/Catalyst targets

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"
source "${SCRIPT_DIR}/utils.sh"

LIB_NAME="libjxl"
SRC_ARCHIVE="libjxl-${LIBJXL_VERSION}.tar.gz"
SRC_DIR="${SOURCES_DIR}/libjxl-${LIBJXL_VERSION}"

# Extract source
extract_source "$LIB_NAME" "$SRC_ARCHIVE" "$SRC_DIR"

# Fetch third_party dependencies (required by CMakeLists.txt even when using system libs)
DEPS_MARKER="${SRC_DIR}/.deps_fetched"
if [ ! -f "$DEPS_MARKER" ]; then
    log_info "Fetching libjxl third_party dependencies..."
    cd "$SRC_DIR"
    ./deps.sh
    touch "$DEPS_MARKER"
    cd - > /dev/null
fi

build_libjxl() {
    local target="$1"
    local arch=$(get_target_arch "$target")
    local platform=$(get_target_cmake_platform "$target")

    local build_dir="${BUILD_OUTPUT_DIR}/${LIB_NAME}/${target}"
    local install_dir="${STAGING_DIR}/${LIB_NAME}/${target}"

    # Get dependency paths
    local brotli_dir="${STAGING_DIR}/brotli/${target}"
    local highway_dir="${STAGING_DIR}/highway/${target}"

    rm -rf "$build_dir"
    mkdir -p "$build_dir"
    cd "$build_dir"

    # libjxl needs to find brotli and highway
    cmake "$SRC_DIR" \
        -DCMAKE_TOOLCHAIN_FILE="${TOOLCHAINS_DIR}/ios.toolchain.cmake" \
        -DPLATFORM="$platform" \
        -DDEPLOYMENT_TARGET="${IOS_MIN_VERSION}" \
        -DCMAKE_INSTALL_PREFIX="$install_dir" \
        -DCMAKE_BUILD_TYPE=Release \
        -DENABLE_BITCODE=OFF \
        -DBUILD_SHARED_LIBS=OFF \
        -DBUILD_TESTING=OFF \
        -DJPEGXL_ENABLE_TOOLS=OFF \
        -DJPEGXL_ENABLE_DOXYGEN=OFF \
        -DJPEGXL_ENABLE_MANPAGES=OFF \
        -DJPEGXL_ENABLE_BENCHMARK=OFF \
        -DJPEGXL_ENABLE_EXAMPLES=OFF \
        -DJPEGXL_ENABLE_JNI=OFF \
        -DJPEGXL_ENABLE_SJPEG=OFF \
        -DJPEGXL_ENABLE_OPENEXR=OFF \
        -DJPEGXL_ENABLE_SKCMS=ON \
        -DJPEGXL_BUNDLE_LIBPNG=OFF \
        -DJPEGXL_ENABLE_TRANSCODE_JPEG=ON \
        -DJPEGXL_STATIC=ON \
        -DJPEGXL_FORCE_SYSTEM_BROTLI=ON \
        -DJPEGXL_FORCE_SYSTEM_HWY=ON \
        -DCMAKE_PREFIX_PATH="${brotli_dir};${highway_dir}" \
        -DBROTLIDEC_INCLUDE_DIRS="${brotli_dir}/include" \
        -DBROTLIENC_INCLUDE_DIRS="${brotli_dir}/include" \
        -DBROTLIDEC_LIBRARIES="${brotli_dir}/lib/libbrotlidec-static.a;${brotli_dir}/lib/libbrotlicommon-static.a" \
        -DBROTLIENC_LIBRARIES="${brotli_dir}/lib/libbrotlienc-static.a;${brotli_dir}/lib/libbrotlicommon-static.a" \
        -DHWY_INCLUDE_DIRS="${highway_dir}/include" \
        -DHWY_LIBRARY="${highway_dir}/lib/libhwy.a"

    cmake --build . --parallel "$JOBS"
    cmake --install .

    verify_library "${install_dir}/lib/libjxl.a" "$arch"
    verify_library "${install_dir}/lib/libjxl_threads.a" "$arch"
}

build_for_all_targets "$LIB_NAME" build_libjxl

log_success "libjxl build complete"
