# VIPSKit

`VIPSKit` is a pure Swift wrapper for [libvips](https://github.com/libvips/libvips), the fast image processing library, for Apple platforms. The heavy lifting (compiling libvips + 17 dependencies) is handled by the separate [vips-cocoa](https://github.com/TimOliver/vips-cocoa) project, which produces a static `vips.xcframework`. VIPSKit imports that xcframework and provides a clean, type-safe Swift API. VIPSKit is then vended as a dynamic framework in order to still fulfill the obligations of the LGPL-2.1 license.

libvips is known for being exceptionally fast and memory-efficient, using a streaming architecture that processes images incrementally rather than loading entire images into memory. This makes it ideal for processing large images or batch thumbnail generation on mobile devices.

# Features

* Pure Swift API with full async/await support.
* Supports iOS 15+, macOS 12+, and visionOS 1.0+.
* Image format support for JPEG, PNG, WebP, JPEG-XL, TIFF, HEIF, AVIF, and GIF.
* Memory-efficient shrink-on-load thumbnailing for JPEG, WebP, and HEIF images.
* Smart content-aware cropping using attention detection.
* Image compositing with 25 blend modes for watermarks and overlays.
* Color adjustments (brightness, contrast, saturation, gamma).
* Gaussian blur, sharpening, and edge detection (Sobel, Canny).
* Drawing primitives (rectangles, lines, circles, flood fill).
* Image analysis (trim detection, statistics, average/background color).
* Full EXIF, XMP, and ICC metadata access.
* Efficient tiling and region extraction for very large images.
* Direct CGImage export for zero-copy display.

# Examples

`VIPSKit` features a simple, expressive API that handles all the complexity of libvips internally.

```swift
import VIPSKit

// Initialize once at app start
try VIPSImage.initialize()

// Load and create a thumbnail efficiently (shrink-on-load)
let thumbnail = try VIPSImage.thumbnail(fromFile: path, width: 200, height: 200)

// Or load for full processing
let image = try VIPSImage(contentsOfFile: path)

// Smart crop to find interesting regions
let cropped = try image.smartCrop(toWidth: 400, height: 400, interesting: .attention)

// Color adjustments
let adjusted = try image.adjust(brightness: 0.1, contrast: 1.2, saturation: 1.1)

// Add a watermark
let watermarked = try image.composite(withOverlay: watermark, mode: .over, x: 10, y: 10)

// Export to data or file
let jpegData = try image.data(format: .jpeg, quality: 85)
try image.write(toFile: "/path/to/output.jpg")

// Create CGImage directly for display (most efficient)
let cgImage = try image.cgImage
let uiImage = UIImage(cgImage: cgImage)
```

All I/O and CPU-heavy operations also have async variants:

```swift
// Async loading
let image = try await VIPSImage.loaded(fromFile: path)
let thumb = try await VIPSImage.thumbnail(fromFile: path, width: 200, height: 200)

// Async processing
let resized = try await image.resizedToFit(width: 800, height: 600)
let blurred = try await image.blurred(sigma: 2.0)

// Async export
let data = try await image.encoded(format: .webP, quality: 80)
```

# Requirements

`VIPSKit` supports the following platforms:

| Platform | Architectures | Min Version |
|----------|--------------|-------------|
| iOS | arm64 | 15.0 |
| iOS Simulator | arm64, x86_64 | 15.0 |
| Mac Catalyst | arm64, x86_64 | 15.0 |
| macOS | arm64, x86_64 | 12.0 |
| visionOS | arm64 | 1.0 |
| visionOS Simulator | arm64 | 1.0 |

# Installation

## Swift Package Manager (Recommended)

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/TimOliver/VIPSKit.git", from: "1.0.0"),
]
```

Or in Xcode: File > Add Package Dependencies, enter the repository URL.

VIPSKit automatically pulls in the pre-built `vips.xcframework` from vips-cocoa via SPM binary targets.

## XCFramework (Manual)

1. Build `VIPSKit.xcframework` (see [Building from Source](#building-from-source) below).
2. Drag it into your Xcode project.
3. Add to "Frameworks, Libraries, and Embedded Content".
4. Set "Embed" to "Embed & Sign".

# Development

### Prerequisites

- Xcode 16+ (Swift 6.0+)
- Ruby with `xcodeproj` gem: `gem install xcodeproj`
- Static `vips.xcframework` in `Frameworks/` (from [vips-cocoa](https://github.com/TimOliver/vips-cocoa))

### Quick Start

```bash
# Copy vips.xcframework from vips-cocoa
cp -R ~/Developer/vips-cocoa/build/xcframeworks/ios/static/vips.xcframework Frameworks/

# Generate Xcode project
ruby Scripts/configure-project.rb

# Open and run tests (⌘U)
open VIPSKit.xcodeproj
```

### SPM Development

```bash
swift build          # Build
swift test           # Run tests
```

# Building from Source

Build the `VIPSKit.xcframework`:

```bash
./build.sh
```

This archives for iOS, iOS Simulator, and Mac Catalyst, then produces `VIPSKit.xcframework` in the project root.

### Build Options

```bash
./build.sh --clean   # Clean build artifacts first
./build.sh --fast    # Build for current platform only (skip archiving)
```

# Supported Image Formats

| Format | Read | Write | Notes |
|--------|------|-------|-------|
| JPEG | Yes | Yes | libjpeg-turbo with SIMD |
| PNG | Yes | Yes | libpng |
| WebP | Yes | Yes | Lossy and lossless |
| JPEG-XL | Yes | Yes | libjxl |
| TIFF | Yes | Yes | Built-in |
| HEIF | Yes | No | Decode via libheif |
| AVIF | Yes | No | Decode via dav1d + libheif |
| GIF | Yes | No | Decode only, built-in |

# Why libvips?

Traditional image processing libraries load entire images into memory before processing. For a 20MP photo, this can mean 80MB+ of RAM just for the pixel buffer. Multiply that by a few concurrent operations, and mobile devices quickly run into memory pressure.

libvips uses a different approach: it streams pixels through a pipeline, processing only the portions needed at any time. Combined with "shrink-on-load" for formats like JPEG (which can decode directly at reduced resolution), this results in dramatically lower memory usage.

# Credits

`VIPSKit` was created by [Tim Oliver](http://twitter.com/TimOliverAU). libvips is developed by [John Cupitt](https://github.com/jcupitt) and contributors.

# License

Both libvips and VIPSKit are licensed under the LGPL-2.1. 

VIPSKit statically links libvips into the framework binary, which is then vended as a dynamic framework in order to continue fulfilling the LGPL obligations.

See [LICENSE](LICENSE) for details.

## Disclaimer

This project was built extensively with the help of [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (Opus 4.6). Given the complexity and breadth of features enabled by `libvips`, manually implementing every wrapper feature would have been a tremendously  time-consuming undertaking otherwise.

All code and build output has been reviewed and tested, but as with any project of this complexity, AI-assisted or not, bugs may exist. If you encounter incorrect behaviour, please [open an issue](https://github.com/TimOliver/VIPSKit/issues).