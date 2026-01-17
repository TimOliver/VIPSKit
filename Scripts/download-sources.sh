#!/bin/bash
# download-sources.sh - Download all source archives for VIPSKit

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

# =============================================================================
# Download URLs (using versions from env.sh)
# =============================================================================
GLIB_MAJOR_MINOR="${GLIB_VERSION%.*}"

DOWNLOADS=(
    "expat|https://github.com/libexpat/libexpat/releases/download/R_${EXPAT_VERSION//./_}/expat-${EXPAT_VERSION}.tar.gz"
    "libffi|https://github.com/libffi/libffi/releases/download/v${LIBFFI_VERSION}/libffi-${LIBFFI_VERSION}.tar.gz"
    "pcre2|https://github.com/PCRE2Project/pcre2/releases/download/pcre2-${PCRE2_VERSION}/pcre2-${PCRE2_VERSION}.tar.gz"
    "libjpeg-turbo|https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/${LIBJPEG_TURBO_VERSION}/libjpeg-turbo-${LIBJPEG_TURBO_VERSION}.tar.gz"
    "libpng|https://downloads.sourceforge.net/project/libpng/libpng16/${LIBPNG_VERSION}/libpng-${LIBPNG_VERSION}.tar.gz"
    "libwebp|https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-${LIBWEBP_VERSION}.tar.gz"
    "brotli|https://github.com/google/brotli/archive/refs/tags/v${BROTLI_VERSION}.tar.gz"
    "highway|https://github.com/google/highway/archive/refs/tags/${HIGHWAY_VERSION}.tar.gz"
    "glib|https://download.gnome.org/sources/glib/${GLIB_MAJOR_MINOR}/glib-${GLIB_VERSION}.tar.xz"
    "dav1d|https://code.videolan.org/videolan/dav1d/-/archive/${DAV1D_VERSION}/dav1d-${DAV1D_VERSION}.tar.gz"
    "libjxl|https://github.com/libjxl/libjxl/archive/refs/tags/v${LIBJXL_VERSION}.tar.gz"
    "libheif|https://github.com/strukturag/libheif/releases/download/v${LIBHEIF_VERSION}/libheif-${LIBHEIF_VERSION}.tar.gz"
    "libvips|https://github.com/libvips/libvips/releases/download/v${LIBVIPS_VERSION}/vips-${LIBVIPS_VERSION}.tar.xz"
)

# Map library names to archive filenames (for libraries where name differs)
get_filename() {
    local name="$1"
    local url="$2"
    case "$name" in
        brotli)   echo "brotli-${BROTLI_VERSION}.tar.gz" ;;
        highway)  echo "highway-${HIGHWAY_VERSION}.tar.gz" ;;
        libjxl)   echo "libjxl-${LIBJXL_VERSION}.tar.gz" ;;
        libvips)  echo "vips-${LIBVIPS_VERSION}.tar.xz" ;;
        *)        basename "$url" ;;
    esac
}

# =============================================================================
# Download Function
# =============================================================================
download() {
    local name="$1"
    local url="$2"
    local filename=$(get_filename "$name" "$url")
    local filepath="${SOURCES_DIR}/${filename}"

    if [ -f "$filepath" ]; then
        echo "[SKIP] ${name} already downloaded: ${filename}"
        return 0
    fi

    echo "[DOWNLOAD] ${name}..."
    if curl -L -f -o "$filepath" "$url"; then
        echo "[OK] ${name}"
    else
        echo "[FAILED] ${name}" >&2
        rm -f "$filepath"
        return 1
    fi
}

# =============================================================================
# Main
# =============================================================================
mkdir -p "$SOURCES_DIR"

echo "Downloading source archives to: ${SOURCES_DIR}"
echo ""

failed=0
for entry in "${DOWNLOADS[@]}"; do
    IFS='|' read -r name url <<< "$entry"
    if ! download "$name" "$url"; then
        ((failed++))
    fi
done

echo ""
if [ $failed -eq 0 ]; then
    echo "All sources downloaded successfully."
else
    echo "Failed to download $failed source(s)." >&2
    exit 1
fi
