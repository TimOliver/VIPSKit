#!/usr/bin/env ruby
# add-libvips-target.rb - Add libvips source files to Xcode project for debugging

require 'xcodeproj'
require 'pathname'

PROJECT_PATH = File.expand_path('../../VIPSKit.xcodeproj', __FILE__)
VIPS_SOURCE_DIR = File.expand_path('../../Vendor/vips-8.18.0/libvips', __FILE__)
VIPS_GENERATED_DIR = File.expand_path('../../Vendor/libvips-generated', __FILE__)
STAGING_DIR = File.expand_path('../../build/staging', __FILE__)
WRAPPER_SOURCE_DIR = File.expand_path('../../Sources', __FILE__)

puts "Opening project: #{PROJECT_PATH}"
project = Xcodeproj::Project.open(PROJECT_PATH)

# Check if target already exists
existing_target = project.targets.find { |t| t.name == 'libvips' }
if existing_target
  puts "Removing existing libvips target..."
  existing_target.remove_from_project
end

# Remove existing libvips group if it exists
existing_group = project.main_group.groups.find { |g| g.name == 'libvips' }
if existing_group
  puts "Removing existing libvips group..."
  existing_group.remove_from_project
end

puts "Creating libvips static library target..."
target = project.new_target(:static_library, 'libvips', :ios, '15.0')

# Create a group for libvips sources
vips_group = project.main_group.new_group('libvips')

# Subdirectories in libvips/libvips that contain source files
VIPS_SUBDIRS = %w[
  arithmetic
  colour
  conversion
  convolution
  create
  draw
  foreign
  freqfilt
  histogram
  iofuncs
  morphology
  mosaicing
  resample
]

# Module subdirectory - these are optional loaders compiled as part of main lib when modules disabled
MODULE_FILES = %w[heif.c jxl.c]

# Collect all source files
source_files = []

VIPS_SUBDIRS.each do |subdir|
  dir_path = File.join(VIPS_SOURCE_DIR, subdir)
  next unless File.directory?(dir_path)

  Dir.glob(File.join(dir_path, '*.c')).each do |file|
    source_files << file
  end
end

# Add module files (heif, jxl loaders - built into library when modules disabled)
module_dir = File.join(VIPS_SOURCE_DIR, 'module')
MODULE_FILES.each do |file|
  path = File.join(module_dir, file)
  source_files << path if File.exist?(path)
end

# Add generated enumtypes.c
enumtypes_path = File.join(VIPS_GENERATED_DIR, 'enumtypes.c')
source_files << enumtypes_path if File.exist?(enumtypes_path)

puts "Found #{source_files.length} source files"

# Add source files to project
sources_group = vips_group.new_group('Sources')

source_files.each do |file_path|
  file_ref = sources_group.new_file(file_path)
  target.source_build_phase.add_file_reference(file_ref)
end

# Add headers group (for reference, not compiled)
headers_group = vips_group.new_group('Headers')

# Add public headers
public_headers_dir = File.join(VIPS_SOURCE_DIR, 'include', 'vips')
Dir.glob(File.join(public_headers_dir, '*.h')).each do |file|
  headers_group.new_file(file)
end

# Add generated headers
generated_group = vips_group.new_group('Generated')
Dir.glob(File.join(VIPS_GENERATED_DIR, '*.h')).each do |file|
  generated_group.new_file(file)
end
# Also add config.h
config_path = File.join(VIPS_GENERATED_DIR, 'config.h')
generated_group.new_file(config_path) if File.exist?(config_path)

# Configure build settings
puts "Configuring build settings..."

target.build_configurations.each do |config|
  settings = config.build_settings

  # Header search paths
  header_paths = [
    '$(SRCROOT)/Vendor/libvips-generated',                    # config.h, version.h, enumtypes.h, vipsmarshal.h
    '$(SRCROOT)/Vendor/vips-8.18.0/libvips',                  # Internal headers
    '$(SRCROOT)/Vendor/vips-8.18.0/libvips/include',          # Public headers
    '$(SRCROOT)/Vendor/vips-8.18.0/libvips/iofuncs',          # For ppmload.h, etc.
    '$(SRCROOT)/Vendor/vips-8.18.0/libvips/foreign',          # For libnsgif/nsgif.h
    '$(SRCROOT)/build/staging/glib/ios-sim-arm64/include',    # libintl.h
    '$(SRCROOT)/build/staging/glib/ios-sim-arm64/include/glib-2.0',
    '$(SRCROOT)/build/staging/glib/ios-sim-arm64/lib/glib-2.0/include',
    '$(SRCROOT)/build/staging/libjpeg-turbo/ios-sim-arm64/include',
    '$(SRCROOT)/build/staging/libpng/ios-sim-arm64/include',
    '$(SRCROOT)/build/staging/libwebp/ios-sim-arm64/include',
    '$(SRCROOT)/build/staging/libjxl/ios-sim-arm64/include',
    '$(SRCROOT)/build/staging/libheif/ios-sim-arm64/include',
    '$(SRCROOT)/build/staging/highway/ios-sim-arm64/include',
    '$(SRCROOT)/build/staging/expat/ios-sim-arm64/include',
    '$(SRCROOT)/build/staging/dav1d/ios-sim-arm64/include',
  ]
  settings['HEADER_SEARCH_PATHS'] = header_paths

  # Preprocessor definitions
  settings['GCC_PREPROCESSOR_DEFINITIONS'] = [
    '$(inherited)',
    'HAVE_CONFIG_H=1',
    'G_LOG_DOMAIN="VIPS"',
  ]

  # C language settings
  settings['GCC_C_LANGUAGE_STANDARD'] = 'gnu11'
  settings['CLANG_ENABLE_MODULES'] = 'NO'  # Disable modules for C code

  # Warning settings - suppress some warnings in third-party code
  settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'

  # Architecture settings
  settings['ONLY_ACTIVE_ARCH'] = 'YES' if config.name == 'Debug'
  settings['VALID_ARCHS'] = 'arm64 x86_64'
  settings['ARCHS'] = '$(ARCHS_STANDARD)'

  # iOS deployment target
  settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'

  # Product settings
  settings['PRODUCT_NAME'] = 'vips'
  settings['SKIP_INSTALL'] = 'YES'

  # Debug settings
  if config.name == 'Debug'
    settings['GCC_OPTIMIZATION_LEVEL'] = '0'
    settings['GCC_GENERATE_DEBUGGING_SYMBOLS'] = 'YES'
    settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf-with-dsym'
  end
end

# =============================================================================
# VIPSWrapper target - for VIPSImage Objective-C wrapper syntax highlighting
# =============================================================================

# Check if VIPSWrapper target already exists
existing_wrapper = project.targets.find { |t| t.name == 'VIPSWrapper' }
if existing_wrapper
  puts "Removing existing VIPSWrapper target..."
  existing_wrapper.remove_from_project
end

puts "Creating VIPSWrapper static library target..."
wrapper_target = project.new_target(:static_library, 'VIPSWrapper', :ios, '15.0')

# Find the VIPSImage Sources group (has path = 'Sources', not the libvips Sources subgroup)
sources_group = project.main_group.groups.find { |g| g.path == 'Sources' }

if sources_group
  # Add wrapper source files to the target's build phase
  wrapper_files = []
  sources_group.files.each do |file_ref|
    if file_ref.path && file_ref.path.end_with?('.m')
      wrapper_target.source_build_phase.add_file_reference(file_ref)
      wrapper_files << file_ref.path
    end
  end
  puts "Added #{wrapper_files.length} VIPSImage source files to VIPSWrapper target"
else
  puts "Warning: Sources group not found in main group"
  # List available groups for debugging
  puts "Available groups: #{project.main_group.groups.map { |g| g.name || g.path }.join(', ')}"
end

# Configure VIPSWrapper build settings
wrapper_target.build_configurations.each do |config|
  settings = config.build_settings

  # Header search paths - same as libvips plus wrapper headers
  header_paths = [
    '$(SRCROOT)/Sources',                                       # VIPSImage headers
    '$(SRCROOT)/Vendor/libvips-generated',                      # config.h, version.h, enumtypes.h
    '$(SRCROOT)/Vendor/vips-8.18.0/libvips/include',            # Public libvips headers
    '$(SRCROOT)/build/staging/glib/ios-sim-arm64/include',      # libintl.h
    '$(SRCROOT)/build/staging/glib/ios-sim-arm64/include/glib-2.0',
    '$(SRCROOT)/build/staging/glib/ios-sim-arm64/lib/glib-2.0/include',
    '$(SRCROOT)/build/staging/libjpeg-turbo/ios-sim-arm64/include',
    '$(SRCROOT)/build/staging/libpng/ios-sim-arm64/include',
    '$(SRCROOT)/build/staging/libwebp/ios-sim-arm64/include',
    '$(SRCROOT)/build/staging/libjxl/ios-sim-arm64/include',
    '$(SRCROOT)/build/staging/libheif/ios-sim-arm64/include',
    '$(SRCROOT)/build/staging/highway/ios-sim-arm64/include',
    '$(SRCROOT)/build/staging/expat/ios-sim-arm64/include',
    '$(SRCROOT)/build/staging/dav1d/ios-sim-arm64/include',
  ]
  settings['HEADER_SEARCH_PATHS'] = header_paths

  # Preprocessor definitions
  settings['GCC_PREPROCESSOR_DEFINITIONS'] = [
    '$(inherited)',
    'HAVE_CONFIG_H=1',
  ]

  # Language settings - Objective-C
  settings['CLANG_ENABLE_MODULES'] = 'YES'
  settings['CLANG_ENABLE_OBJC_ARC'] = 'YES'

  # Architecture settings
  settings['ONLY_ACTIVE_ARCH'] = 'YES' if config.name == 'Debug'
  settings['VALID_ARCHS'] = 'arm64 x86_64'
  settings['ARCHS'] = '$(ARCHS_STANDARD)'

  # iOS deployment target
  settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'

  # Product settings
  settings['PRODUCT_NAME'] = 'VIPSWrapper'
  settings['SKIP_INSTALL'] = 'YES'

  # Debug settings
  if config.name == 'Debug'
    settings['GCC_OPTIMIZATION_LEVEL'] = '0'
    settings['GCC_GENERATE_DEBUGGING_SYMBOLS'] = 'YES'
    settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf-with-dsym'
  end
end

# Save the project
puts "Saving project..."
project.save

puts ""
puts "=" * 60
puts "Targets added successfully!"
puts "=" * 60
puts ""
puts "Created targets:"
puts "  - libvips: C library sources (346 files)"
puts "  - VIPSWrapper: Objective-C wrapper sources"
puts ""
puts "For syntax highlighting and code completion:"
puts "  1. Open VIPSKit.xcodeproj in Xcode"
puts "  2. Build the VIPSWrapper target once: Product > Build"
puts "  3. Xcode will index all VIPSImage source files"
puts ""
puts "For debugging libvips internals:"
puts "  1. Build the libvips target"
puts "  2. Set breakpoints in libvips source files"
puts ""
