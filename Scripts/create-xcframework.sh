#!/bin/bash
# create-xcframework.sh - Create VIPSKit.xcframework with Objective-C wrapper

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"
source "${SCRIPT_DIR}/utils.sh"

log_step "Creating VIPSKit.xcframework (dynamic with ObjC wrapper)"

# Paths
XCFRAMEWORK_DIR="${OUTPUT_DIR}/VIPSKit.xcframework"
TEMP_DIR="${BUILD_OUTPUT_DIR}/xcframework_temp"
WRAPPER_DIR="${PROJECT_ROOT}/Sources"

# Clean previous output
rm -rf "$XCFRAMEWORK_DIR"
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

# Platform configurations
PLATFORMS=(
    "ios-arm64:ios:arm64"
    "ios-arm64_x86_64-simulator:ios-sim-arm64,ios-sim-x86_64:arm64,x86_64"
    "ios-arm64_x86_64-maccatalyst:catalyst-arm64,catalyst-x86_64:arm64,x86_64"
)

# Create Info.plist
create_framework_plist() {
    local output_dir="$1"
    cat > "${output_dir}/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>VIPSKit</string>
    <key>CFBundleIdentifier</key>
    <string>org.libvips.VIPSKit</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>VIPSKit</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>${LIBVIPS_VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${LIBVIPS_VERSION}</string>
    <key>MinimumOSVersion</key>
    <string>${IOS_MIN_VERSION}</string>
</dict>
</plist>
EOF
}

# Create module map
create_module_map() {
    local output_dir="$1"
    mkdir -p "${output_dir}/Modules"
    cat > "${output_dir}/Modules/module.modulemap" << 'EOF'
framework module VIPSKit {
    umbrella header "VIPSKit.h"

    export *
    module * { export * }

    link "z"
    link "iconv"
}
EOF
}

# Compile wrapper and create dylib for a single architecture
# Sets DYLIB_OUTPUT variable with the path
build_dylib_for_target() {
    local target="$1"
    local arch=$(get_target_arch "$target")
    local sdk=$(get_target_sdk "$target")
    local output_dir="$2"

    echo "    Compiling wrapper for ${target} (${arch})..." >&2

    local sdk_path=$(get_sdk_path "$sdk")
    local cc=$(get_cc "$sdk")
    local cflags=$(get_cflags "$arch" "$sdk" "$target")

    # Build include paths
    local include_paths="-I${STAGING_DIR}/libvips/${target}/include"
    include_paths+=" -I${STAGING_DIR}/glib/${target}/include/glib-2.0"
    include_paths+=" -I${STAGING_DIR}/glib/${target}/lib/glib-2.0/include"

    # Source files to compile
    local source_files=(
        "VIPSImage.m"
        "VIPSImage+Loading.m"
        "VIPSImage+Saving.m"
        "VIPSImage+Resize.m"
        "VIPSImage+Transform.m"
        "VIPSImage+Color.m"
        "VIPSImage+Filter.m"
        "VIPSImage+Tiling.m"
        "VIPSImage+CGImage.m"
        "VIPSImage+Caching.m"
    )

    local object_files=""

    # Compile each source file
    for src in "${source_files[@]}"; do
        local obj_name="${src%.m}_${arch}.o"
        local obj_path="${output_dir}/${obj_name}"

        "$cc" $cflags $include_paths \
            -fobjc-arc \
            -c "${WRAPPER_DIR}/${src}" \
            -o "$obj_path"

        object_files+=" $obj_path"
    done

    echo "    Linking dylib for ${target} (${arch})..." >&2

    # Build list of static libraries
    local static_libs=""
    static_libs+=" ${STAGING_DIR}/expat/${target}/lib/libexpat.a"
    static_libs+=" ${STAGING_DIR}/libffi/${target}/lib/libffi.a"
    static_libs+=" ${STAGING_DIR}/pcre2/${target}/lib/libpcre2-8.a"
    static_libs+=" ${STAGING_DIR}/brotli/${target}/lib/libbrotlicommon.a"
    static_libs+=" ${STAGING_DIR}/brotli/${target}/lib/libbrotlidec.a"
    static_libs+=" ${STAGING_DIR}/brotli/${target}/lib/libbrotlienc.a"
    static_libs+=" ${STAGING_DIR}/highway/${target}/lib/libhwy.a"
    static_libs+=" ${STAGING_DIR}/glib/${target}/lib/libintl.a"
    static_libs+=" ${STAGING_DIR}/glib/${target}/lib/libglib-2.0.a"
    static_libs+=" ${STAGING_DIR}/glib/${target}/lib/libgmodule-2.0.a"
    static_libs+=" ${STAGING_DIR}/glib/${target}/lib/libgobject-2.0.a"
    static_libs+=" ${STAGING_DIR}/glib/${target}/lib/libgio-2.0.a"
    static_libs+=" ${STAGING_DIR}/libjpeg-turbo/${target}/lib/libjpeg.a"
    static_libs+=" ${STAGING_DIR}/libpng/${target}/lib/libpng16.a"
    static_libs+=" ${STAGING_DIR}/libwebp/${target}/lib/libsharpyuv.a"
    static_libs+=" ${STAGING_DIR}/libwebp/${target}/lib/libwebp.a"
    static_libs+=" ${STAGING_DIR}/libwebp/${target}/lib/libwebpmux.a"
    static_libs+=" ${STAGING_DIR}/libwebp/${target}/lib/libwebpdemux.a"
    static_libs+=" ${STAGING_DIR}/dav1d/${target}/lib/libdav1d.a"
    static_libs+=" ${STAGING_DIR}/libjxl/${target}/lib/libjxl.a"
    static_libs+=" ${STAGING_DIR}/libjxl/${target}/lib/libjxl_threads.a"
    static_libs+=" ${STAGING_DIR}/libjxl/${target}/lib/libjxl_cms.a"
    static_libs+=" ${STAGING_DIR}/libheif/${target}/lib/libheif.a"
    static_libs+=" ${STAGING_DIR}/libvips/${target}/lib/libvips.a"

    local dylib="${output_dir}/VIPSKit_${arch}.dylib"

    # Link everything into a dylib
    "$cc" $cflags \
        -dynamiclib \
        -install_name "@rpath/VIPSKit.framework/VIPSKit" \
        -o "$dylib" \
        $object_files \
        $static_libs \
        -framework Foundation \
        -framework CoreGraphics \
        -lz -liconv -lresolv -lc++

    # Return the path via stdout
    echo "$dylib"
}

# Create fat dylib from multiple architectures
create_fat_dylib() {
    local output="$1"
    shift
    local inputs=("$@")

    if [ ${#inputs[@]} -eq 1 ]; then
        cp "${inputs[0]}" "$output"
    else
        lipo -create "${inputs[@]}" -output "$output"
    fi
}

# Process each platform
for platform_config in "${PLATFORMS[@]}"; do
    IFS=':' read -r platform_name target_types archs <<< "$platform_config"

    log_info "Processing platform: ${platform_name}"

    # Create framework structure
    framework_dir="${TEMP_DIR}/${platform_name}/VIPSKit.framework"
    mkdir -p "${framework_dir}/Headers"

    # Split target types and archs
    IFS=',' read -ra target_array <<< "$target_types"
    IFS=',' read -ra arch_array <<< "$archs"

    platform_build_dir="${TEMP_DIR}/${platform_name}/build"
    mkdir -p "$platform_build_dir"

    arch_dylibs=()

    for i in "${!target_array[@]}"; do
        target_type="${target_array[$i]}"
        arch="${arch_array[$i]}"

        dylib=$(build_dylib_for_target "$target_type" "$platform_build_dir")
        arch_dylibs+=("$dylib")
    done

    # Create fat binary
    log_info "  Creating framework binary..."
    create_fat_dylib "${framework_dir}/VIPSKit" "${arch_dylibs[@]}"

    # Copy public header only
    cp "${WRAPPER_DIR}/VIPSImage.h" "${framework_dir}/Headers/VIPSKit.h"

    # Create Info.plist
    create_framework_plist "$framework_dir"

    # Create module map
    create_module_map "$framework_dir"

    # Show info
    size=$(ls -lh "${framework_dir}/VIPSKit" | awk '{print $5}')
    archs_info=$(lipo -info "${framework_dir}/VIPSKit" 2>/dev/null | sed 's/.*: //' || echo "unknown")
    log_info "  Framework: ${archs_info} (${size})"
done

# Create xcframework
log_info "Creating xcframework..."

xcframework_args=()
for platform_config in "${PLATFORMS[@]}"; do
    IFS=':' read -r platform_name _ _ <<< "$platform_config"
    framework_dir="${TEMP_DIR}/${platform_name}/VIPSKit.framework"
    xcframework_args+=(-framework "$framework_dir")
done

mkdir -p "$OUTPUT_DIR"
xcodebuild -create-xcframework \
    "${xcframework_args[@]}" \
    -output "$XCFRAMEWORK_DIR"

# Cleanup
rm -rf "$TEMP_DIR"

# Verify output
log_step "Verifying xcframework"

for dir in "${XCFRAMEWORK_DIR}"/*; do
    if [ -d "$dir" ] && [ -d "${dir}/VIPSKit.framework" ]; then
        platform=$(basename "$dir")
        binary="${dir}/VIPSKit.framework/VIPSKit"
        if [ -f "$binary" ]; then
            archs=$(lipo -info "$binary" 2>/dev/null | sed 's/.*: //' || echo "unknown")
            size=$(ls -lh "$binary" | awk '{print $5}')
            log_success "${platform}: ${archs} (${size})"
        fi
    fi
done

log_success "Created xcframework at: ${XCFRAMEWORK_DIR}"

# Print usage instructions
echo ""
echo "To use in your Xcode project:"
echo "1. Drag ${XCFRAMEWORK_DIR} into your Xcode project"
echo "2. Add to 'Frameworks, Libraries, and Embedded Content'"
echo "3. Set 'Embed' to 'Embed & Sign'"
echo ""
echo "Usage in Swift:"
echo "  import VIPSKit"
echo "  "
echo "  // Initialize once at app start"
echo "  try VIPSImage.initialize()"
echo "  "
echo "  // Load and process image"
echo "  let image = try VIPSImage(contentsOfFile: path)"
echo "  let thumbnail = try image.thumbnail(width: 200, height: 200)"
echo "  let data = try thumbnail.data(format: .jpeg, quality: 85)"
echo ""
echo "Usage in Objective-C:"
echo "  @import VIPSKit;"
echo "  "
echo "  [VIPSImage initializeWithError:nil];"
echo "  VIPSImage *image = [VIPSImage imageWithContentsOfFile:path error:nil];"
echo ""
