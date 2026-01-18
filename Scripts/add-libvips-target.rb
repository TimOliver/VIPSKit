#!/usr/bin/env ruby
# add-libvips-target.rb - Create VIPSKit target for development/debugging
#
# Creates a single static library target combining:
# - libvips C sources (for debugging into libvips internals)
# - VIPSImage Objective-C wrapper sources
#
# Configures VIPSTests to use this target instead of VIPSKit.xcframework

require 'xcodeproj'
require 'pathname'

PROJECT_PATH = File.expand_path('../../VIPSKit.xcodeproj', __FILE__)
VIPS_SOURCE_DIR = File.expand_path('../../Vendor/vips-8.18.0/libvips', __FILE__)
VIPS_GENERATED_DIR = File.expand_path('../../Vendor/libvips-generated', __FILE__)
STAGING_DIR = File.expand_path('../../build/staging', __FILE__)

puts "Opening project: #{PROJECT_PATH}"
project = Xcodeproj::Project.open(PROJECT_PATH)

# =============================================================================
# Clean up old targets
# =============================================================================

%w[libvips VIPSWrapper VIPSKit].each do |name|
  existing = project.targets.find { |t| t.name == name }
  if existing
    puts "Removing existing #{name} target..."
    existing.remove_from_project
  end
end

# Remove existing libvips group if it exists
existing_group = project.main_group.groups.find { |g| g.name == 'libvips' }
if existing_group
  puts "Removing existing libvips group..."
  existing_group.remove_from_project
end

# =============================================================================
# Create VIPSKit static library target
# =============================================================================

puts "Creating VIPSKit static library target..."
target = project.new_target(:static_library, 'VIPSKit', :ios, '15.0')

# =============================================================================
# Add libvips C sources
# =============================================================================

vips_group = project.main_group.new_group('libvips')

VIPS_SUBDIRS = %w[
  arithmetic colour conversion convolution create draw foreign
  freqfilt histogram iofuncs morphology mosaicing resample
]

# Subdirectories within foreign that need to be included
FOREIGN_SUBDIRS = %w[libnsgif]

MODULE_FILES = %w[heif.c jxl.c]

# Collect libvips source files
libvips_sources = []

VIPS_SUBDIRS.each do |subdir|
  dir_path = File.join(VIPS_SOURCE_DIR, subdir)
  next unless File.directory?(dir_path)
  # Include .c files
  Dir.glob(File.join(dir_path, '*.c')).each { |f| libvips_sources << f }
  # Include .cpp files but exclude *_hwy.cpp (Highway SIMD - complex build requirements)
  Dir.glob(File.join(dir_path, '*.cpp')).each do |f|
    next if f.end_with?('_hwy.cpp')
    libvips_sources << f
  end
end

# Add module files
module_dir = File.join(VIPS_SOURCE_DIR, 'module')
MODULE_FILES.each do |file|
  path = File.join(module_dir, file)
  libvips_sources << path if File.exist?(path)
end

# Add foreign subdirectories (libnsgif, etc.)
FOREIGN_SUBDIRS.each do |subdir|
  dir_path = File.join(VIPS_SOURCE_DIR, 'foreign', subdir)
  next unless File.directory?(dir_path)
  Dir.glob(File.join(dir_path, '*.c')).each { |f| libvips_sources << f }
end

# Add generated files (enumtypes.c, vipsmarshal.c)
%w[enumtypes.c vipsmarshal.c].each do |file|
  path = File.join(VIPS_GENERATED_DIR, file)
  libvips_sources << path if File.exist?(path)
end

puts "Found #{libvips_sources.length} libvips C source files"

# Add to project
libvips_sources_group = vips_group.new_group('Sources')
libvips_sources.each do |file_path|
  file_ref = libvips_sources_group.new_file(file_path)
  target.source_build_phase.add_file_reference(file_ref)
end

# Add headers for reference
headers_group = vips_group.new_group('Headers')
public_headers_dir = File.join(VIPS_SOURCE_DIR, 'include', 'vips')
Dir.glob(File.join(public_headers_dir, '*.h')).each { |f| headers_group.new_file(f) }

generated_group = vips_group.new_group('Generated')
Dir.glob(File.join(VIPS_GENERATED_DIR, '*.h')).each { |f| generated_group.new_file(f) }
config_path = File.join(VIPS_GENERATED_DIR, 'config.h')
generated_group.new_file(config_path) if File.exist?(config_path)

# =============================================================================
# Add VIPSImage wrapper sources
# =============================================================================

wrapper_sources_group = project.main_group.groups.find { |g| g.path == 'Sources' }
wrapper_count = 0

if wrapper_sources_group
  wrapper_sources_group.files.each do |file_ref|
    if file_ref.path && file_ref.path.end_with?('.m')
      target.source_build_phase.add_file_reference(file_ref)
      wrapper_count += 1
    end
  end
  puts "Added #{wrapper_count} VIPSImage Objective-C source files"
else
  puts "Warning: Sources group not found"
end

# =============================================================================
# Configure build settings
# =============================================================================

puts "Configuring build settings..."

target.build_configurations.each do |config|
  settings = config.build_settings

  # Header search paths
  settings['HEADER_SEARCH_PATHS'] = [
    '$(SRCROOT)/Sources',                                       # VIPSImage headers
    '$(SRCROOT)/Vendor/libvips-generated',                      # config.h, version.h, enumtypes.h
    '$(SRCROOT)/Vendor/vips-8.18.0/libvips',                    # Internal headers
    '$(SRCROOT)/Vendor/vips-8.18.0/libvips/include',            # Public headers
    '$(SRCROOT)/Vendor/vips-8.18.0/libvips/iofuncs',            # ppmload.h, etc.
    '$(SRCROOT)/Vendor/vips-8.18.0/libvips/foreign',            # libnsgif/nsgif.h
    '$(SRCROOT)/build/staging/glib/ios-sim-arm64/include',
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

  # Preprocessor definitions (G_LOG_DOMAIN is already in config.h)
  settings['GCC_PREPROCESSOR_DEFINITIONS'] = [
    '$(inherited)',
    'HAVE_CONFIG_H=1',
  ]

  # Language settings
  settings['GCC_C_LANGUAGE_STANDARD'] = 'gnu11'
  settings['CLANG_ENABLE_MODULES'] = 'YES'
  settings['CLANG_ENABLE_OBJC_ARC'] = 'YES'

  # Suppress warnings in third-party libvips code
  settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'

  # Architecture
  settings['ONLY_ACTIVE_ARCH'] = 'YES' if config.name == 'Debug'
  settings['ARCHS'] = '$(ARCHS_STANDARD)'
  settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'

  # Product
  settings['PRODUCT_NAME'] = 'VIPSKit'
  settings['SKIP_INSTALL'] = 'YES'

  # Debug settings
  if config.name == 'Debug'
    settings['GCC_OPTIMIZATION_LEVEL'] = '0'
    settings['GCC_GENERATE_DEBUGGING_SYMBOLS'] = 'YES'
    settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf-with-dsym'
  end
end

# =============================================================================
# Configure VIPSTests to use VIPSKit target
# =============================================================================

vips_tests = project.targets.find { |t| t.name == 'VIPSTests' }

if vips_tests
  puts "Configuring VIPSTests to use VIPSKit target..."

  # Remove stale dependencies (from previous VIPSKit target)
  vips_tests.dependencies.each do |dep|
    if dep.target.nil? || dep.target.name == 'VIPSKit'
      dep.remove_from_project
    end
  end

  # Add dependency
  vips_tests.add_dependency(target)

  # Find and remove VIPSKit.xcframework from link phase
  frameworks_phase = vips_tests.frameworks_build_phase
  xcframework_ref = frameworks_phase.files.find { |f| f.display_name&.include?('VIPSKit.xcframework') }
  if xcframework_ref
    puts "Removing VIPSKit.xcframework from VIPSTests linking..."
    frameworks_phase.remove_file_reference(xcframework_ref.file_ref)
  end

  # Find and remove from embed phase
  embed_phase = vips_tests.build_phases.find { |p| p.is_a?(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase) && p.name == 'Embed Frameworks' }
  if embed_phase
    embed_ref = embed_phase.files.find { |f| f.display_name&.include?('VIPSKit.xcframework') }
    if embed_ref
      puts "Removing VIPSKit.xcframework from embed phase..."
      embed_phase.remove_file_reference(embed_ref.file_ref)
    end
  end

  # Add VIPSKit.a to link phase
  product_ref = target.product_reference
  frameworks_phase.add_file_reference(product_ref) unless frameworks_phase.files.any? { |f| f.file_ref == product_ref }

  # Add dependency static libraries
  lib_search_paths = []
  libs_to_link = []

  %w[glib libjpeg-turbo libpng libwebp libjxl libheif highway expat dav1d brotli pcre2 libffi].each do |lib|
    lib_path = "$(SRCROOT)/build/staging/#{lib}/ios-sim-arm64/lib"
    lib_search_paths << lib_path
  end

  # Configure VIPSTests build settings
  vips_tests.build_configurations.each do |config|
    settings = config.build_settings

    # Add header search paths
    existing_headers = settings['HEADER_SEARCH_PATHS'] || ['$(inherited)']
    existing_headers = [existing_headers] unless existing_headers.is_a?(Array)

    new_headers = [
      '$(SRCROOT)/Sources',
      '$(SRCROOT)/Vendor/libvips-generated',
      '$(SRCROOT)/Vendor/vips-8.18.0/libvips/include',
      '$(SRCROOT)/build/staging/glib/ios-sim-arm64/include',
      '$(SRCROOT)/build/staging/glib/ios-sim-arm64/include/glib-2.0',
      '$(SRCROOT)/build/staging/glib/ios-sim-arm64/lib/glib-2.0/include',
    ]
    settings['HEADER_SEARCH_PATHS'] = (existing_headers + new_headers).uniq

    # Add library search paths
    existing_lib_paths = settings['LIBRARY_SEARCH_PATHS'] || ['$(inherited)']
    existing_lib_paths = [existing_lib_paths] unless existing_lib_paths.is_a?(Array)
    settings['LIBRARY_SEARCH_PATHS'] = (existing_lib_paths + lib_search_paths).uniq

    # Add other linker flags for static libraries
    settings['OTHER_LDFLAGS'] = [
      '$(inherited)',
      '-ObjC',  # Force loading of all Objective-C categories from static libraries
      '-lc++',  # Required for C++ libraries (libjxl, highway, libheif, libvips vector code)
      '-lresolv',  # Required for DNS resolver functions used by gio
      '-liconv',  # Required for glib character conversion
      '-lglib-2.0', '-lgobject-2.0', '-lgio-2.0', '-lgmodule-2.0', '-lintl', '-lffi',
      '-ljpeg', '-lpng16', '-lz',
      '-lwebp', '-lwebpdemux', '-lwebpmux', '-lsharpyuv',
      '-ljxl', '-ljxl_cms', '-ljxl_threads', '-lhwy', '-lbrotlienc', '-lbrotlidec', '-lbrotlicommon',
      '-lheif', '-ldav1d',
      '-lexpat', '-lpcre2-8',
    ]
  end

  puts "VIPSTests configured to link against VIPSKit + dependencies"
else
  puts "Warning: VIPSTests target not found"
end

# =============================================================================
# Configure TestHost to find VIPSImage.h
# =============================================================================

test_host = project.targets.find { |t| t.name == 'TestHost' }

if test_host
  puts "Configuring TestHost header search paths..."

  test_host.build_configurations.each do |config|
    settings = config.build_settings

    existing_headers = settings['HEADER_SEARCH_PATHS'] || ['$(inherited)']
    existing_headers = [existing_headers] unless existing_headers.is_a?(Array)

    new_headers = ['$(SRCROOT)/Sources']
    settings['HEADER_SEARCH_PATHS'] = (existing_headers + new_headers).uniq
  end

  puts "TestHost configured"
else
  puts "Warning: TestHost target not found"
end

# =============================================================================
# Save project
# =============================================================================

puts "Saving project..."
project.save

puts ""
puts "=" * 60
puts "VIPSKit target created successfully!"
puts "=" * 60
puts ""
puts "Combined target includes:"
puts "  - #{libvips_sources.length} libvips C source files"
puts "  - #{wrapper_count} VIPSImage Objective-C source files"
puts ""
puts "To run tests with full debugging:"
puts "  1. Open VIPSKit.xcodeproj in Xcode"
puts "  2. Select the VIPSTests scheme"
puts "  3. Set breakpoints in VIPSImage or libvips sources"
puts "  4. Run tests (Cmd+U)"
puts ""
