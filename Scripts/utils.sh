#!/bin/bash
# utils.sh - Common utility functions for vips-cocoa build system

# Source env.sh if not already sourced
if [ -z "$PROJECT_ROOT" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/env.sh"
fi

# =============================================================================
# Logging
# =============================================================================
log_info() {
    echo "[INFO] $*"
}

log_success() {
    echo "[SUCCESS] $*"
}

log_warning() {
    echo "[WARNING] $*"
}

log_error() {
    echo "[ERROR] $*" >&2
}

log_step() {
    echo ""
    echo "========================================"
    echo "$*"
    echo "========================================"
}

# =============================================================================
# Download Functions
# =============================================================================
download_source() {
    local name="$1"
    local url="$2"
    local filename="$3"

    local filepath="${SOURCES_DIR}/${filename}"

    if [ -f "$filepath" ]; then
        log_info "${name} already downloaded: ${filename}"
        return 0
    fi

    log_info "Downloading ${name} from ${url}"
    mkdir -p "$SOURCES_DIR"

    if ! curl -L -o "$filepath" "$url"; then
        log_error "Failed to download ${name}"
        rm -f "$filepath"
        return 1
    fi

    log_success "Downloaded ${name}"
}

extract_source() {
    local name="$1"
    local filename="$2"
    local dest_dir="$3"

    local filepath="${SOURCES_DIR}/${filename}"

    if [ -d "$dest_dir" ]; then
        log_info "${name} already extracted"
        return 0
    fi

    log_info "Extracting ${name}"
    mkdir -p "$(dirname "$dest_dir")"

    local temp_dir=$(mktemp -d)

    case "$filename" in
        *.tar.gz|*.tgz)
            tar -xzf "$filepath" -C "$temp_dir"
            ;;
        *.tar.xz)
            tar -xJf "$filepath" -C "$temp_dir"
            ;;
        *.tar.bz2)
            tar -xjf "$filepath" -C "$temp_dir"
            ;;
        *.zip)
            unzip -q "$filepath" -d "$temp_dir"
            ;;
        *)
            log_error "Unknown archive format: ${filename}"
            rm -rf "$temp_dir"
            return 1
            ;;
    esac

    # Move extracted directory to destination
    local extracted=$(ls "$temp_dir")
    mv "$temp_dir/$extracted" "$dest_dir"
    rm -rf "$temp_dir"

    log_success "Extracted ${name}"
}

# =============================================================================
# Build Environment Setup
# =============================================================================
setup_build_env() {
    local arch="$1"
    local sdk="$2"
    local target_type="$3"

    export CC=$(get_cc "$sdk")
    export CXX=$(get_cxx "$sdk")
    export AR=$(get_ar "$sdk")
    export RANLIB=$(get_ranlib "$sdk")
    export STRIP=$(get_strip "$sdk")

    export CFLAGS=$(get_cflags "$arch" "$sdk" "$target_type")
    export CXXFLAGS="${CFLAGS}"
    export LDFLAGS=$(get_ldflags "$arch" "$sdk" "$target_type")

    export HOST=$(get_host_triple "$arch")

    # pkg-config configuration
    export PKG_CONFIG_PATH=""
    export PKG_CONFIG_LIBDIR=""
}

# Add dependency install paths to pkg-config and compiler flags
add_dependency() {
    local lib_name="$1"
    local target="$2"

    local dep_install="${STAGING_DIR}/${lib_name}/${target}"

    if [ -d "${dep_install}/lib/pkgconfig" ]; then
        export PKG_CONFIG_PATH="${dep_install}/lib/pkgconfig:${PKG_CONFIG_PATH}"
    fi

    if [ -d "${dep_install}/include" ]; then
        export CFLAGS="${CFLAGS} -I${dep_install}/include"
        export CXXFLAGS="${CXXFLAGS} -I${dep_install}/include"
    fi

    if [ -d "${dep_install}/lib" ]; then
        export LDFLAGS="${LDFLAGS} -L${dep_install}/lib"
    fi
}

# =============================================================================
# CMake Build Functions
# =============================================================================
cmake_build() {
    local src_dir="$1"
    local build_dir="$2"
    local install_dir="$3"
    shift 3
    local cmake_args=("$@")

    mkdir -p "$build_dir"
    cd "$build_dir"

    cmake "$src_dir" \
        -DCMAKE_INSTALL_PREFIX="$install_dir" \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=OFF \
        "${cmake_args[@]}"

    cmake --build . --parallel "$JOBS"
    cmake --install .
}

cmake_build_ios() {
    local src_dir="$1"
    local build_dir="$2"
    local install_dir="$3"
    local platform="$4"
    local deployment_target="$5"
    shift 5
    local cmake_args=("$@")

    mkdir -p "$build_dir"
    cd "$build_dir"

    cmake "$src_dir" \
        -DCMAKE_TOOLCHAIN_FILE="${TOOLCHAINS_DIR}/ios.toolchain.cmake" \
        -DPLATFORM="$platform" \
        -DDEPLOYMENT_TARGET="${deployment_target}" \
        -DCMAKE_INSTALL_PREFIX="$install_dir" \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=OFF \
        -DENABLE_BITCODE=OFF \
        "${cmake_args[@]}"

    cmake --build . --parallel "$JOBS"
    cmake --install .
}

# Map our target to ios-cmake platform (wrapper for env.sh function)
get_cmake_platform() {
    local target="$1"
    get_target_cmake_platform "$target"
}

# =============================================================================
# Meson Build Functions
# =============================================================================
meson_build() {
    local src_dir="$1"
    local build_dir="$2"
    local install_dir="$3"
    local cross_file="$4"
    shift 4
    local meson_args=("$@")

    # Clean existing build if present
    if [ -d "$build_dir" ]; then
        rm -rf "$build_dir"
    fi

    meson setup "$build_dir" "$src_dir" \
        --cross-file="$cross_file" \
        --prefix="$install_dir" \
        --default-library=static \
        --buildtype=release \
        "${meson_args[@]}"

    meson compile -C "$build_dir" -j "$JOBS"
    meson install -C "$build_dir"
}

# =============================================================================
# Autotools Build Functions
# =============================================================================
autotools_build() {
    local src_dir="$1"
    local build_dir="$2"
    local install_dir="$3"
    shift 3
    local configure_args=("$@")

    mkdir -p "$build_dir"
    cd "$build_dir"

    "$src_dir/configure" \
        --prefix="$install_dir" \
        --host="$HOST" \
        --enable-static \
        --disable-shared \
        "${configure_args[@]}"

    make -j "$JOBS"
    make install
}

# =============================================================================
# Library Combination
# =============================================================================
# Create fat library from multiple architectures using lipo
create_fat_library() {
    local output="$1"
    shift
    local inputs=("$@")

    mkdir -p "$(dirname "$output")"
    lipo -create "${inputs[@]}" -output "$output"
}

# Combine multiple static libraries into one using libtool
combine_static_libs() {
    local output="$1"
    shift
    local inputs=("$@")

    mkdir -p "$(dirname "$output")"
    libtool -static -o "$output" "${inputs[@]}"
}

# =============================================================================
# Cleanup Functions
# =============================================================================
clean_build() {
    local lib_name="$1"
    log_info "Cleaning build artifacts for ${lib_name}"
    rm -rf "${BUILD_OUTPUT_DIR}/${lib_name}"
    rm -rf "${STAGING_DIR}/${lib_name}"
}

clean_all() {
    log_info "Cleaning all build artifacts"
    rm -rf "$BUILD_OUTPUT_DIR"
    rm -rf "$STAGING_DIR"
    rm -rf "${OUTPUT_DIR}/VIPSKit.xcframework"
    rm -rf "${OUTPUT_DIR}/xcframeworks"
}

# =============================================================================
# Verification Functions
# =============================================================================
verify_library() {
    local lib_path="$1"
    local expected_arch="$2"

    if [ ! -f "$lib_path" ]; then
        log_error "Library not found: ${lib_path}"
        return 1
    fi

    local archs=$(lipo -info "$lib_path" 2>/dev/null | sed 's/.*: //')
    if [[ "$archs" != *"$expected_arch"* ]]; then
        log_error "Library ${lib_path} does not contain ${expected_arch} (found: ${archs})"
        return 1
    fi

    log_success "Verified ${lib_path} contains ${expected_arch}"
}

# =============================================================================
# Build script helper
# =============================================================================
build_for_all_targets() {
    local lib_name="$1"
    local build_func="$2"

    log_step "Building ${lib_name} for all targets"

    for target in $TARGETS; do
        local arch=$(get_target_arch "$target")
        local sdk=$(get_target_sdk "$target")

        log_info "Building ${lib_name} for ${target} (${arch})"

        setup_build_env "$arch" "$sdk" "$target"

        if ! "$build_func" "$target"; then
            log_error "Failed to build ${lib_name} for ${target}"
            return 1
        fi

        log_success "Built ${lib_name} for ${target}"
    done

    log_success "Completed ${lib_name} for all targets"
}
