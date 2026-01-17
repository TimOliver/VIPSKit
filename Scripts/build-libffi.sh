#!/bin/bash
# build-libffi.sh - Build libffi for all iOS/Catalyst targets
# Uses manual compilation to avoid autotools CFI issues with newer LLVM

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"
source "${SCRIPT_DIR}/utils.sh"

LIB_NAME="libffi"
SRC_ARCHIVE="libffi-${LIBFFI_VERSION}.tar.gz"
SRC_DIR="${SOURCES_DIR}/libffi-${LIBFFI_VERSION}"

# Extract source
extract_source "$LIB_NAME" "$SRC_ARCHIVE" "$SRC_DIR"

# Generate ffi.h from ffi.h.in for a given architecture
generate_ffi_h() {
    local install_dir="$1"
    local arch="$2"

    mkdir -p "${install_dir}/include"

    # Copy ffitarget.h for the appropriate architecture
    if [ "$arch" = "arm64" ]; then
        cp "${SRC_DIR}/src/aarch64/ffitarget.h" "${install_dir}/include/"
        local target="AARCH64"
        local exec_trampoline_table="1"
    else
        cp "${SRC_DIR}/src/x86/ffitarget.h" "${install_dir}/include/"
        local target="X86_64"
        # x86_64 doesn't use trampoline tables on Darwin
        local exec_trampoline_table="0"
    fi

    # Calculate FFI_VERSION_NUMBER (e.g., 3.5.2 -> 0x030502)
    local major=$(echo "$LIBFFI_VERSION" | cut -d. -f1)
    local minor=$(echo "$LIBFFI_VERSION" | cut -d. -f2)
    local patch=$(echo "$LIBFFI_VERSION" | cut -d. -f3)
    local version_number=$(printf "0x%02x%02x%02x" "$major" "$minor" "$patch")

    # Generate ffi.h from template
    sed -e "s/@VERSION@/${LIBFFI_VERSION}/g" \
        -e "s/@TARGET@/${target}/g" \
        -e "s/@HAVE_LONG_DOUBLE@/1/g" \
        -e "s/@FFI_EXEC_TRAMPOLINE_TABLE@/${exec_trampoline_table}/g" \
        -e "s/@FFI_VERSION_STRING@/${LIBFFI_VERSION}/g" \
        -e "s/@FFI_VERSION_NUMBER@/${version_number}/g" \
        "${SRC_DIR}/include/ffi.h.in" > "${install_dir}/include/ffi.h"

    # Copy other headers
    cp "${SRC_DIR}/include/ffi_common.h" "${install_dir}/include/"
    cp "${SRC_DIR}/include/ffi_cfi.h" "${install_dir}/include/"
    cp "${SRC_DIR}/include/tramp.h" "${install_dir}/include/"
}

# Generate fficonfig.h - architecture-specific configuration
generate_fficonfig_h() {
    local install_dir="$1"
    local arch="$2"

    # arm64 uses trampoline tables, x86_64 doesn't
    if [ "$arch" = "arm64" ]; then
        local ffi_exec_trampoline_table="#define FFI_EXEC_TRAMPOLINE_TABLE 1"
    else
        local ffi_exec_trampoline_table="/* #undef FFI_EXEC_TRAMPOLINE_TABLE */"
    fi

    cat > "${install_dir}/include/fficonfig.h" << EOF
/* fficonfig.h - generated for iOS/Catalyst cross-compilation */

#define PACKAGE "libffi"
#define PACKAGE_NAME "libffi"
#define PACKAGE_STRING "libffi ${LIBFFI_VERSION}"
#define PACKAGE_VERSION "${LIBFFI_VERSION}"
#define VERSION "${LIBFFI_VERSION}"

#define STDC_HEADERS 1
#define HAVE_ALLOCA 1
#define HAVE_ALLOCA_H 1
#define HAVE_DLFCN_H 1
#define HAVE_INTTYPES_H 1
#define HAVE_MEMCPY 1
#define HAVE_MEMORY_H 1
#define HAVE_MKOSTEMP 1
#define HAVE_MKSTEMP 1
#define HAVE_MMAP 1
#define HAVE_MMAP_ANON 1
#define HAVE_MMAP_FILE 1
#define HAVE_STDINT_H 1
#define HAVE_STDLIB_H 1
#define HAVE_STRING_H 1
#define HAVE_STRINGS_H 1
#define HAVE_SYS_MMAN_H 1
#define HAVE_SYS_STAT_H 1
#define HAVE_SYS_TYPES_H 1
#define HAVE_UNISTD_H 1

#define SIZEOF_DOUBLE 8
#define SIZEOF_LONG_DOUBLE 8
#define SIZEOF_SIZE_T 8

/* Apple-specific settings */
#define SYMBOL_UNDERSCORE 1
${ffi_exec_trampoline_table}
#define HAVE_RO_EH_FRAME 1
#define EH_FRAME_FLAGS "a"
#define HAVE_HIDDEN_VISIBILITY_ATTRIBUTE 1

/* DO NOT define HAVE_AS_CFI_PSEUDO_OP - causes issues with newer LLVM */
/* #undef HAVE_AS_CFI_PSEUDO_OP */

/* x86_64 PC-relative addressing - use X - . syntax instead of X@rel */
#define HAVE_AS_X86_PCREL 1

#define LT_OBJDIR ".libs/"

/* FFI_HIDDEN - different definitions for assembly and C */
#ifdef HAVE_HIDDEN_VISIBILITY_ATTRIBUTE
#ifdef LIBFFI_ASM
#ifdef __APPLE__
#define FFI_HIDDEN(name) .private_extern name
#else
#define FFI_HIDDEN(name) .hidden name
#endif
#else
#define FFI_HIDDEN __attribute__ ((visibility ("hidden")))
#endif
#else
#ifdef LIBFFI_ASM
#define FFI_HIDDEN(name)
#else
#define FFI_HIDDEN
#endif
#endif
EOF
}

build_libffi() {
    local target="$1"
    local arch=$(get_target_arch "$target")
    local sdk=$(get_target_sdk "$target")

    local build_dir="${BUILD_OUTPUT_DIR}/${LIB_NAME}/${target}"
    local install_dir="${STAGING_DIR}/${LIB_NAME}/${target}"

    rm -rf "$build_dir" "$install_dir"
    mkdir -p "$build_dir" "$install_dir/lib"

    # Generate headers
    generate_ffi_h "$install_dir" "$arch"
    generate_fficonfig_h "$install_dir" "$arch"

    # Get compiler and flags
    local CC=$(get_cc "$sdk")
    local CFLAGS=$(get_cflags "$arch" "$sdk" "$target")

    # Add include paths - install dir first so our fficonfig.h takes precedence
    CFLAGS="${CFLAGS} -I${install_dir}/include -I${SRC_DIR}/include -I${SRC_DIR}/src"

    # Determine source files based on architecture
    local c_sources=""
    local asm_sources=""

    if [ "$arch" = "arm64" ]; then
        c_sources="${SRC_DIR}/src/aarch64/ffi.c"
        asm_sources="${SRC_DIR}/src/aarch64/sysv.S"
        CFLAGS="${CFLAGS} -I${SRC_DIR}/src/aarch64"
    else
        # x86_64 - need both ffi64.c and ffiw64.c as ffi64.c references efi64 functions
        c_sources="${SRC_DIR}/src/x86/ffi64.c ${SRC_DIR}/src/x86/ffiw64.c"
        asm_sources="${SRC_DIR}/src/x86/unix64.S ${SRC_DIR}/src/x86/win64.S"
        CFLAGS="${CFLAGS} -I${SRC_DIR}/src/x86"
    fi

    # Common source files
    c_sources="${c_sources} ${SRC_DIR}/src/closures.c ${SRC_DIR}/src/prep_cif.c ${SRC_DIR}/src/types.c ${SRC_DIR}/src/tramp.c ${SRC_DIR}/src/raw_api.c ${SRC_DIR}/src/java_raw_api.c"

    cd "$build_dir"

    local obj_files=""

    # Compile C sources
    for src in $c_sources; do
        if [ -f "$src" ]; then
            local basename=$(basename "$src" .c)
            log_info "Compiling ${basename}.c"
            "$CC" $CFLAGS -c "$src" -o "${basename}.o" || { log_error "Failed to compile ${basename}.c"; return 1; }
            obj_files="${obj_files} ${basename}.o"
        fi
    done

    # Compile assembly sources
    for src in $asm_sources; do
        if [ -f "$src" ]; then
            local basename=$(basename "$src" .S)
            log_info "Compiling ${basename}.S"
            "$CC" $CFLAGS -c "$src" -o "${basename}.o" || { log_error "Failed to compile ${basename}.S"; return 1; }
            obj_files="${obj_files} ${basename}.o"
        fi
    done

    # Create static library
    log_info "Creating libffi.a"
    ar rcs "${install_dir}/lib/libffi.a" $obj_files
    ranlib "${install_dir}/lib/libffi.a"

    # Create pkg-config file
    mkdir -p "${install_dir}/lib/pkgconfig"
    cat > "${install_dir}/lib/pkgconfig/libffi.pc" << EOF
prefix=${install_dir}
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: libffi
Description: Library supporting Foreign Function Interfaces
Version: ${LIBFFI_VERSION}
Libs: -L\${libdir} -lffi
Cflags: -I\${includedir}
EOF

    verify_library "${install_dir}/lib/libffi.a" "$arch"
}

build_for_all_targets "$LIB_NAME" build_libffi

log_success "libffi build complete"
