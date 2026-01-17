#!/bin/bash
# build-brotli.sh - Build brotli for all iOS/Catalyst targets

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"
source "${SCRIPT_DIR}/utils.sh"

LIB_NAME="brotli"
SRC_ARCHIVE="brotli-${BROTLI_VERSION}.tar.gz"
SRC_DIR="${SOURCES_DIR}/brotli-${BROTLI_VERSION}"

# Extract source
extract_source "$LIB_NAME" "$SRC_ARCHIVE" "$SRC_DIR"

build_brotli() {
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
        -DBROTLI_DISABLE_TESTS=ON \
        -DBROTLI_BUNDLED_MODE=ON \
        -DBUILD_SHARED_LIBS=OFF

    cmake --build . --parallel "$JOBS"

    # BROTLI_BUNDLED_MODE skips install, so manually copy libraries and headers
    mkdir -p "${install_dir}/lib"
    mkdir -p "${install_dir}/include/brotli"

    # Copy static libraries
    cp "${build_dir}/libbrotlicommon.a" "${install_dir}/lib/"
    cp "${build_dir}/libbrotlidec.a" "${install_dir}/lib/"
    cp "${build_dir}/libbrotlienc.a" "${install_dir}/lib/"

    # Copy headers
    cp "${SRC_DIR}/c/include/brotli/"*.h "${install_dir}/include/brotli/"

    # Create pkg-config files
    mkdir -p "${install_dir}/lib/pkgconfig"

    cat > "${install_dir}/lib/pkgconfig/libbrotlicommon.pc" << EOF
prefix=${install_dir}
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: libbrotlicommon
Description: Brotli common dictionary library
Version: ${BROTLI_VERSION}
Libs: -L\${libdir} -lbrotlicommon
Cflags: -I\${includedir}
EOF

    cat > "${install_dir}/lib/pkgconfig/libbrotlidec.pc" << EOF
prefix=${install_dir}
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: libbrotlidec
Description: Brotli decoder library
Version: ${BROTLI_VERSION}
Requires: libbrotlicommon >= ${BROTLI_VERSION}
Libs: -L\${libdir} -lbrotlidec
Cflags: -I\${includedir}
EOF

    cat > "${install_dir}/lib/pkgconfig/libbrotlienc.pc" << EOF
prefix=${install_dir}
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: libbrotlienc
Description: Brotli encoder library
Version: ${BROTLI_VERSION}
Requires: libbrotlicommon >= ${BROTLI_VERSION}
Libs: -L\${libdir} -lbrotlienc
Cflags: -I\${includedir}
EOF

    verify_library "${install_dir}/lib/libbrotlicommon.a" "$arch"
    verify_library "${install_dir}/lib/libbrotlidec.a" "$arch"
    verify_library "${install_dir}/lib/libbrotlienc.a" "$arch"
}

build_for_all_targets "$LIB_NAME" build_brotli

log_success "brotli build complete"
