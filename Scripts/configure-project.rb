#!/usr/bin/env ruby
# configure-project.rb
# Creates a fresh VIPSKit.xcodeproj with the new Swift wrapper structure.
#
# Targets:
#   - VIPSKit: Dynamic framework (Sources/*.swift + Sources/Internal/CVIPS, links static vips.xcframework)
#   - VIPSKitTests: Unit tests (Tests/*.swift)
#   - VIPSTestHost: Minimal iOS app host for tests

require 'xcodeproj'
require 'fileutils'

ROOT = File.expand_path('..', __dir__)
PROJ_PATH = File.join(ROOT, 'VIPSKit.xcodeproj')

# Remove old project
FileUtils.rm_rf(PROJ_PATH)

project = Xcodeproj::Project.new(PROJ_PATH)
project.build_configuration_list.set_setting('IPHONEOS_DEPLOYMENT_TARGET', '15.0')

# ===========================================================================
# Framework Target: VIPSKit
# ===========================================================================
fw = project.new_target(:framework, 'VIPSKit', :ios, '15.0')
fw.build_configurations.each do |config|
  config.build_settings.merge!({
    'PRODUCT_BUNDLE_IDENTIFIER' => 'org.libvips.VIPSKit',
    'PRODUCT_NAME' => '$(TARGET_NAME)',
    'SWIFT_VERSION' => '5.0',
    'GENERATE_INFOPLIST_FILE' => 'YES',
    'DEFINES_MODULE' => 'YES',
    'DYLIB_INSTALL_NAME_BASE' => '@rpath',
    'INSTALL_PATH' => '$(LOCAL_LIBRARY_DIR)/Frameworks',
    'SKIP_INSTALL' => 'YES',
    'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES',

    # C shim needs to find vips headers from xcframework
    'HEADER_SEARCH_PATHS' => [
      '$(inherited)',
      '$(SRCROOT)/Sources/Internal/include',
    ],

    # Swift needs to find the CVIPS module
    'SWIFT_INCLUDE_PATHS' => [
      '$(inherited)',
      '$(SRCROOT)/Sources/Internal/include',
    ],

    # Clang module for importing vips from Swift
    'OTHER_CFLAGS' => [
      '$(inherited)',
      '-fmodule-map-file=$(SRCROOT)/Sources/Internal/include/module.modulemap',
      '-Wno-documentation',
    ],

    'OTHER_SWIFT_FLAGS' => [
      '$(inherited)',
      '-Xcc', '-fmodule-map-file=$(SRCROOT)/Sources/Internal/include/module.modulemap',
    ],

    # Link system libraries that vips depends on
    'OTHER_LDFLAGS' => [
      '$(inherited)',
      '-lz',
      '-liconv',
      '-lresolv',
      '-lc++',
      '-lexpat',
      '-force_load',
      '$(BUILD_DIR)/$(CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME)/vips.a',
    ],

    'CLANG_ENABLE_MODULES' => 'YES',
    'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',

    'GCC_PREPROCESSOR_DEFINITIONS' => [
      '$(inherited)',
      'HAVE_CONFIG_H=1',
    ],

    'SUPPORTED_PLATFORMS' => 'iphoneos iphonesimulator macosx',
    'SUPPORTS_MACCATALYST' => 'YES',
  })

  if config.name == 'Debug'
    config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
    config.build_settings['GCC_OPTIMIZATION_LEVEL'] = '0'
  else
    config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-O'
    config.build_settings['GCC_OPTIMIZATION_LEVEL'] = 's'
  end
end

# --- Add source files ---

sources_group = project.main_group.new_group('Sources')

# Internal/CVIPS group
internal_group = sources_group.new_group('Internal')
internal_include_group = internal_group.new_group('include')

cvips_c = internal_group.new_file(File.join(ROOT, 'Sources/Internal/CVIPS.c'))
cvips_h = internal_include_group.new_file(File.join(ROOT, 'Sources/Internal/include/CVIPS.h'))
internal_include_group.new_file(File.join(ROOT, 'Sources/Internal/include/module.modulemap'))

fw.source_build_phase.add_file_reference(cvips_c)

# CVIPS.h as Private header (visible to Swift in same target, not public)
headers_phase = fw.headers_build_phase
build_file = headers_phase.add_file_reference(cvips_h)
build_file.settings = { 'ATTRIBUTES' => ['Private'] }

# Swift source files (at Sources/ root)
swift_files = Dir.glob(File.join(ROOT, 'Sources/*.swift')).sort

swift_files.each do |path|
  ref = sources_group.new_file(path)
  fw.source_build_phase.add_file_reference(ref)
end

# --- Add vips.xcframework ---
fw_group = project.main_group.new_group('Frameworks')
xcfw_ref = fw_group.new_file('Frameworks/vips.xcframework')
xcfw_ref.source_tree = 'SOURCE_ROOT'
xcfw_ref.path = 'Frameworks/vips.xcframework'
xcfw_ref.last_known_file_type = 'wrapper.xcframework'

fw.frameworks_build_phase.add_file_reference(xcfw_ref, true)

# ===========================================================================
# Test Host Target: VIPSTestHost (minimal iOS app)
# ===========================================================================
host = project.new_target(:application, 'VIPSTestHost', :ios, '15.0')
host.build_configurations.each do |config|
  config.build_settings.merge!({
    'PRODUCT_BUNDLE_IDENTIFIER' => 'org.libvips.VIPSTestHost',
    'PRODUCT_NAME' => '$(TARGET_NAME)',
    'SWIFT_VERSION' => '5.0',
    'GENERATE_INFOPLIST_FILE' => 'YES',
    'INFOPLIST_FILE' => 'Tests/TestHost/Info.plist',
    'ASSETCATALOG_COMPILER_APPICON_NAME' => 'AppIcon',
    'CODE_SIGN_STYLE' => 'Automatic',
    'SUPPORTED_PLATFORMS' => 'iphoneos iphonesimulator',
  })
end

# Add test host source files
test_host_group = project.main_group.new_group('Tests').new_group('TestHost')
['AppDelegate.h', 'AppDelegate.m', 'main.m'].each do |name|
  path = File.join(ROOT, 'Tests/TestHost', name)
  next unless File.exist?(path)
  ref = test_host_group.new_file(path)
  host.source_build_phase.add_file_reference(ref) if name.end_with?('.m')
end

# Add storyboard
storyboard_path = File.join(ROOT, 'Tests/TestHost/LaunchScreen.storyboard')
if File.exist?(storyboard_path)
  ref = test_host_group.new_file(storyboard_path)
  host.resources_build_phase.add_file_reference(ref)
end

# Add Info.plist
info_plist_path = File.join(ROOT, 'Tests/TestHost/Info.plist')
if File.exist?(info_plist_path)
  test_host_group.new_file(info_plist_path)
end

# Embed VIPSKit framework in test host
host.add_dependency(fw)
embed_phase = host.new_copy_files_build_phase('Embed Frameworks')
embed_phase.dst_subfolder_spec = '10'  # Frameworks
embed_bf = embed_phase.add_file_reference(fw.product_reference, true)
embed_bf.settings = { 'ATTRIBUTES' => ['CodeSignOnCopy', 'RemoveHeadersOnCopy'] }

# Link VIPSKit framework
host.frameworks_build_phase.add_file_reference(fw.product_reference, true)

# ===========================================================================
# Test Target: VIPSKitTests
# ===========================================================================
tests = project.new_target(:unit_test_bundle, 'VIPSKitTests', :ios, '15.0')
tests.build_configurations.each do |config|
  config.build_settings.merge!({
    'PRODUCT_BUNDLE_IDENTIFIER' => 'org.libvips.VIPSKitTests',
    'PRODUCT_NAME' => '$(TARGET_NAME)',
    'SWIFT_VERSION' => '5.0',
    'INFOPLIST_FILE' => '',
    'GENERATE_INFOPLIST_FILE' => 'YES',
    'TEST_HOST' => '$(BUILT_PRODUCTS_DIR)/VIPSTestHost.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/VIPSTestHost',
    'BUNDLE_LOADER' => '$(TEST_HOST)',
    'SUPPORTED_PLATFORMS' => 'iphoneos iphonesimulator',
  })
end

tests.add_dependency(host)

# Link VIPSKit framework to tests
tests.frameworks_build_phase.add_file_reference(fw.product_reference, true)

# Add test source files
test_group = project.main_group['Tests'].new_group('VIPSKitTests')
test_files = Dir.glob(File.join(ROOT, 'Tests/*.swift')).sort

test_files.each do |path|
  ref = test_group.new_file(path)
  tests.source_build_phase.add_file_reference(ref)
end

# Add test resources
resources_group = project.main_group['Tests'].new_group('TestResources')
resource_files = Dir.glob(File.join(ROOT, 'Tests/TestResources/*')).reject { |f| File.basename(f) == '.gitkeep' }
resource_files.each do |path|
  ref = resources_group.new_file(path)
  tests.resources_build_phase.add_file_reference(ref)
end

# ===========================================================================
# Schemes
# ===========================================================================
# Save project first
project.save

# Create shared scheme for VIPSKit
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(fw)
scheme.add_test_target(tests)
scheme.set_launch_target(host)
scheme.save_as(PROJ_PATH, 'VIPSKit', true)

puts "✅ VIPSKit.xcodeproj configured successfully"
puts "   Framework: VIPSKit (dynamic framework)"
puts "   Tests: VIPSKitTests"
puts "   Test Host: VIPSTestHost"
