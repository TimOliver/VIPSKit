#!/bin/bash
# build-libvips.sh - Build libvips for all iOS/Catalyst targets
# This is the main image processing library

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"
source "${SCRIPT_DIR}/utils.sh"

LIB_NAME="libvips"
SRC_ARCHIVE="vips-${LIBVIPS_VERSION}.tar.xz"
SRC_DIR="${SOURCES_DIR}/vips-${LIBVIPS_VERSION}"

# Extract source
extract_source "$LIB_NAME" "$SRC_ARCHIVE" "$SRC_DIR"

# Get cross file path for target
get_cross_file() {
    local target="$1"
    echo "${CROSS_FILES_DIR}/${target}.ini"
}

build_libvips() {
    local target="$1"
    local arch=$(get_target_arch "$target")

    local build_dir="${BUILD_OUTPUT_DIR}/${LIB_NAME}/${target}"
    local install_dir="${STAGING_DIR}/${LIB_NAME}/${target}"
    local cross_file=$(get_cross_file "$target")

    # Get all dependency paths
    local expat_dir="${STAGING_DIR}/expat/${target}"
    local libffi_dir="${STAGING_DIR}/libffi/${target}"
    local pcre2_dir="${STAGING_DIR}/pcre2/${target}"
    local glib_dir="${STAGING_DIR}/glib/${target}"
    local libjpeg_dir="${STAGING_DIR}/libjpeg-turbo/${target}"
    local libpng_dir="${STAGING_DIR}/libpng/${target}"
    local libwebp_dir="${STAGING_DIR}/libwebp/${target}"
    local brotli_dir="${STAGING_DIR}/brotli/${target}"
    local highway_dir="${STAGING_DIR}/highway/${target}"
    local libjxl_dir="${STAGING_DIR}/libjxl/${target}"
    local dav1d_dir="${STAGING_DIR}/dav1d/${target}"
    local libheif_dir="${STAGING_DIR}/libheif/${target}"

    # Clean existing build
    rm -rf "$build_dir"

    # Get SDK info for zlib
    local sdk=$(get_target_sdk "$target")
    local sdk_path=$(get_sdk_path "$sdk")

    # Create a zlib.pc file pointing to system zlib
    local zlib_pc_dir="${BUILD_OUTPUT_DIR}/${LIB_NAME}/${target}/pkgconfig"
    mkdir -p "$zlib_pc_dir"
    cat > "${zlib_pc_dir}/zlib.pc" << EOF
prefix=${sdk_path}/usr
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: zlib
Description: zlib compression library
Version: 1.2.12
Libs: -lz
Cflags: -I\${includedir}
EOF

    # Build pkg-config path from all dependencies
    local pkg_config_dirs=(
        "${zlib_pc_dir}"
        "${expat_dir}/lib/pkgconfig"
        "${libffi_dir}/lib/pkgconfig"
        "${pcre2_dir}/lib/pkgconfig"
        "${glib_dir}/lib/pkgconfig"
        "${libjpeg_dir}/lib/pkgconfig"
        "${libpng_dir}/lib/pkgconfig"
        "${libwebp_dir}/lib/pkgconfig"
        "${brotli_dir}/lib/pkgconfig"
        "${highway_dir}/lib/pkgconfig"
        "${libjxl_dir}/lib/pkgconfig"
        "${dav1d_dir}/lib/pkgconfig"
        "${libheif_dir}/lib/pkgconfig"
    )

    # Join paths with colon
    local pkg_config_path=$(IFS=:; echo "${pkg_config_dirs[*]}")
    export PKG_CONFIG_PATH="$pkg_config_path"
    export PKG_CONFIG_LIBDIR=""

    # Create a temporary cross file with all settings
    local temp_cross_file="${BUILD_OUTPUT_DIR}/${LIB_NAME}/${target}_cross.ini"
    mkdir -p "$(dirname "$temp_cross_file")"

    # Copy base cross file and add pkg-config paths
    cat "$cross_file" > "$temp_cross_file"

    # Convert pkg_config_dirs array to meson format
    local meson_pkg_paths=""
    for dir in "${pkg_config_dirs[@]}"; do
        if [ -n "$meson_pkg_paths" ]; then
            meson_pkg_paths+=", "
        fi
        meson_pkg_paths+="'${dir}'"
    done

    # Collect all static libraries to link into the shared library
    local static_libs=(
        "${expat_dir}/lib/libexpat.a"
        "${libffi_dir}/lib/libffi.a"
        "${pcre2_dir}/lib/libpcre2-8.a"
        "${brotli_dir}/lib/libbrotlicommon.a"
        "${brotli_dir}/lib/libbrotlidec.a"
        "${brotli_dir}/lib/libbrotlienc.a"
        "${highway_dir}/lib/libhwy.a"
        "${glib_dir}/lib/libintl.a"
        "${glib_dir}/lib/libglib-2.0.a"
        "${glib_dir}/lib/libgmodule-2.0.a"
        "${glib_dir}/lib/libgobject-2.0.a"
        "${glib_dir}/lib/libgio-2.0.a"
        "${libjpeg_dir}/lib/libjpeg.a"
        "${libpng_dir}/lib/libpng16.a"
        "${libwebp_dir}/lib/libsharpyuv.a"
        "${libwebp_dir}/lib/libwebp.a"
        "${libwebp_dir}/lib/libwebpmux.a"
        "${libwebp_dir}/lib/libwebpdemux.a"
        "${dav1d_dir}/lib/libdav1d.a"
        "${libjxl_dir}/lib/libjxl.a"
        "${libjxl_dir}/lib/libjxl_threads.a"
        "${libjxl_dir}/lib/libjxl_cms.a"
        "${libheif_dir}/lib/libheif.a"
    )

    # Build link arguments for static libraries
    local link_args=""
    for lib in "${static_libs[@]}"; do
        if [ -f "$lib" ]; then
            link_args="${link_args}, '${lib}'"
        fi
    done
    # Add system libraries
    link_args="${link_args}, '-lz', '-liconv', '-lresolv', '-lc++'"

    cat >> "$temp_cross_file" << EOF

[built-in options]
pkg_config_path = [${meson_pkg_paths}]
c_link_args = [${link_args:2}]
cpp_link_args = [${link_args:2}]
EOF

    meson setup "$build_dir" "$SRC_DIR" \
        --cross-file="$temp_cross_file" \
        --prefix="$install_dir" \
        --default-library=static \
        --buildtype=release \
        -Dintrospection=disabled \
        -Dmodules=disabled \
        -Dvapi=false \
        -Ddocs=false \
        -Ddeprecated=false \
        -Dexamples=false \
        -Dcplusplus=true \
        -Dcfitsio=disabled \
        -Dcgif=disabled \
        -Dexif=disabled \
        -Dfftw=disabled \
        -Dfontconfig=disabled \
        -Dheif=enabled \
        -Dimagequant=disabled \
        -Djpeg=enabled \
        -Djpeg-xl=enabled \
        -Dlcms=disabled \
        -Dmagick=disabled \
        -Dmatio=disabled \
        -Dnifti=disabled \
        -Dopenexr=disabled \
        -Dopenjpeg=disabled \
        -Dopenslide=disabled \
        -Dorc=disabled \
        -Dpangocairo=disabled \
        -Dpdfium=disabled \
        -Dpng=enabled \
        -Dpoppler=disabled \
        -Dquantizr=disabled \
        -Drsvg=disabled \
        -Dspng=disabled \
        -Dtiff=disabled \
        -Dwebp=enabled \
        -Dzlib=enabled \
        -Dhighway=enabled

    meson compile -C "$build_dir" -j "$JOBS"
    meson install -C "$build_dir"

    # Clean up temp cross file
    rm -f "$temp_cross_file"

    verify_library "${install_dir}/lib/libvips.a" "$arch"
}

build_for_all_targets "$LIB_NAME" build_libvips

log_success "libvips build complete"
