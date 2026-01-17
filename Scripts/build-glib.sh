#!/bin/bash
# build-glib.sh - Build glib for all iOS/Catalyst targets
# GLib is the core dependency for libvips, uses Meson build system

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"
source "${SCRIPT_DIR}/utils.sh"

LIB_NAME="glib"
SRC_ARCHIVE="glib-${GLIB_VERSION}.tar.xz"
SRC_DIR="${SOURCES_DIR}/glib-${GLIB_VERSION}"

# Extract source
extract_source "$LIB_NAME" "$SRC_ARCHIVE" "$SRC_DIR"

# Get cross file path for target
get_cross_file() {
    local target="$1"
    echo "${CROSS_FILES_DIR}/${target}.ini"
}

build_glib() {
    local target="$1"
    local arch=$(get_target_arch "$target")

    local build_dir="${BUILD_OUTPUT_DIR}/${LIB_NAME}/${target}"
    local install_dir="${STAGING_DIR}/${LIB_NAME}/${target}"
    local cross_file=$(get_cross_file "$target")

    # Get dependency paths
    local libffi_dir="${STAGING_DIR}/libffi/${target}"
    local pcre2_dir="${STAGING_DIR}/pcre2/${target}"

    # Clean existing build
    rm -rf "$build_dir"

    # Set pkg-config paths for dependencies
    export PKG_CONFIG_PATH="${libffi_dir}/lib/pkgconfig:${pcre2_dir}/lib/pkgconfig"
    export PKG_CONFIG_LIBDIR=""

    # Create a temporary cross file with pkg-config paths
    local temp_cross_file="${BUILD_OUTPUT_DIR}/${LIB_NAME}/${target}_cross.ini"
    mkdir -p "$(dirname "$temp_cross_file")"

    cat "$cross_file" > "$temp_cross_file"
    cat >> "$temp_cross_file" << EOF

[built-in options]
pkg_config_path = ['${libffi_dir}/lib/pkgconfig', '${pcre2_dir}/lib/pkgconfig']
EOF

    meson setup "$build_dir" "$SRC_DIR" \
        --cross-file="$temp_cross_file" \
        --prefix="$install_dir" \
        --default-library=static \
        --buildtype=release \
        -Dtests=false \
        -Dinstalled_tests=false \
        -Dnls=disabled \
        -Dselinux=disabled \
        -Dxattr=false \
        -Dlibmount=disabled \
        -Dman-pages=disabled \
        -Ddtrace=false \
        -Dsystemtap=false \
        -Dgtk_doc=false \
        -Dbsymbolic_functions=false \
        -Dglib_debug=disabled \
        -Dglib_assert=false \
        -Dglib_checks=false

    meson compile -C "$build_dir" -j "$JOBS"
    meson install -C "$build_dir"

    # Clean up temp cross file
    rm -f "$temp_cross_file"

    verify_library "${install_dir}/lib/libglib-2.0.a" "$arch"
    verify_library "${install_dir}/lib/libgio-2.0.a" "$arch"
    verify_library "${install_dir}/lib/libgobject-2.0.a" "$arch"
    verify_library "${install_dir}/lib/libgmodule-2.0.a" "$arch"
}

build_for_all_targets "$LIB_NAME" build_glib

log_success "glib build complete"
