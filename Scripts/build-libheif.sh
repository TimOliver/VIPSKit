#!/bin/bash
# build-libheif.sh - Build libheif for all iOS/Catalyst targets
# libheif provides HEIF/AVIF support via dav1d decoder

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"
source "${SCRIPT_DIR}/utils.sh"

LIB_NAME="libheif"
SRC_ARCHIVE="libheif-${LIBHEIF_VERSION}.tar.gz"
SRC_DIR="${SOURCES_DIR}/libheif-${LIBHEIF_VERSION}"

# Extract source
extract_source "$LIB_NAME" "$SRC_ARCHIVE" "$SRC_DIR"

build_libheif() {
    local target="$1"
    local arch=$(get_target_arch "$target")
    local platform=$(get_target_cmake_platform "$target")

    local build_dir="${BUILD_OUTPUT_DIR}/${LIB_NAME}/${target}"
    local install_dir="${STAGING_DIR}/${LIB_NAME}/${target}"

    # Get dependency paths
    local dav1d_dir="${STAGING_DIR}/dav1d/${target}"

    rm -rf "$build_dir"
    mkdir -p "$build_dir"
    cd "$build_dir"

    # Set pkg-config path for dav1d
    export PKG_CONFIG_PATH="${dav1d_dir}/lib/pkgconfig"

    cmake "$SRC_DIR" \
        -DCMAKE_TOOLCHAIN_FILE="${TOOLCHAINS_DIR}/ios.toolchain.cmake" \
        -DPLATFORM="$platform" \
        -DDEPLOYMENT_TARGET="${IOS_MIN_VERSION}" \
        -DCMAKE_INSTALL_PREFIX="$install_dir" \
        -DCMAKE_BUILD_TYPE=Release \
        -DENABLE_BITCODE=OFF \
        -DBUILD_SHARED_LIBS=OFF \
        -DBUILD_TESTING=OFF \
        -DWITH_EXAMPLES=OFF \
        -DWITH_LIBDE265=OFF \
        -DWITH_X265=OFF \
        -DWITH_AOM_DECODER=OFF \
        -DWITH_AOM_ENCODER=OFF \
        -DWITH_RAV1E=OFF \
        -DWITH_DAV1D=ON \
        -DWITH_SvtEnc=OFF \
        -DWITH_KVAZAAR=OFF \
        -DWITH_JPEG_DECODER=OFF \
        -DWITH_JPEG_ENCODER=OFF \
        -DWITH_OpenJPEG_DECODER=OFF \
        -DWITH_OpenJPEG_ENCODER=OFF \
        -DWITH_FFMPEG_DECODER=OFF \
        -DWITH_UNCOMPRESSED_CODEC=ON \
        -DENABLE_PLUGIN_LOADING=OFF \
        -DENABLE_MULTITHREADING_SUPPORT=ON \
        -DCMAKE_PREFIX_PATH="${dav1d_dir}" \
        -DDAV1D_INCLUDE_DIR="${dav1d_dir}/include" \
        -DDAV1D_LIBRARY="${dav1d_dir}/lib/libdav1d.a"

    cmake --build . --parallel "$JOBS"
    cmake --install .

    # Fix pkg-config file for static linking - include dav1d in main Libs line
    local pc_file="${install_dir}/lib/pkgconfig/libheif.pc"
    if [ -f "$pc_file" ]; then
        # Replace Libs line to include dav1d for static linking
        sed -i.bak "s|^Libs: -L\${libdir} -lheif|Libs: -L\${libdir} -lheif -L${dav1d_dir}/lib -ldav1d|" "$pc_file"
        rm -f "${pc_file}.bak"
    fi

    verify_library "${install_dir}/lib/libheif.a" "$arch"
}

build_for_all_targets "$LIB_NAME" build_libheif

log_success "libheif build complete"
