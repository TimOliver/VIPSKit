# VIPSKit

`VIPSKit` is an XCFramework distribution of [libvips](https://github.com/libvips/libvips), the fast image processing library, for iOS. It includes an Objective-C wrapper that provides a clean, idiomatic API for Swift and Objective-C projects.

libvips is known for being exceptionally fast and memory-efficient, using a streaming architecture that processes images incrementally rather than loading entire images into memory. This makes it ideal for processing large images or batch thumbnail generation on mobile devices.

# Features

* Pre-built universal XCFramework for iOS devices (arm64), iOS Simulator (arm64, x86_64), and Mac Catalyst (arm64, x86_64).
* Clean Objective-C wrapper with full Swift compatibility.
* Supports JPEG, PNG, WebP, HEIF, AVIF, JPEG-XL, and GIF formats.
* Memory-efficient shrink-on-load thumbnailing for JPEG images.
* Smart content-aware cropping using attention detection.
* Image compositing with 25+ blend modes for watermarks and overlays.
* Color adjustments (brightness, contrast, saturation, gamma).
* Edge detection (Sobel, Canny algorithms).
* Efficient tiling and region extraction for very large images.
* Direct CGImage export for zero-copy display.
* Flexible caching API with lossless WebP support.

# Examples

`VIPSKit` features a simple, chainable API that handles all the complexity of libvips internally.

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
if let cgImage = try image.createCGImage() {
    let uiImage = UIImage(cgImage: cgImage)
}
```

For Objective-C:

```objc
@import VIPSKit;

[VIPSImage initializeWithError:nil];

VIPSImage *image = [VIPSImage imageWithContentsOfFile:path error:&error];
VIPSImage *thumbnail = [image resizeToFitWidth:200 height:200 error:&error];
NSData *jpegData = [thumbnail dataWithFormat:VIPSImageFormatJPEG quality:85 error:&error];
```

# Requirements

`VIPSKit` requires iOS 15.0 and above. The framework is written in Objective-C but imports seamlessly into Swift.

# Installation

## Manual Installation

1. Download or build `VIPSKit.xcframework`
2. Drag it into your Xcode project
3. Add to "Frameworks, Libraries, and Embedded Content"
4. Set "Embed" to "Embed & Sign"

## Swift Package Manager

*Coming soon*

# Development

Want to contribute, debug, or just explore the code? VIPSKit includes full source-level debugging support.

### Quick Start

```bash
git clone https://github.com/anthropics/VIPSKit.git
cd VIPSKit
./Scripts/bootstrap.sh   # Downloads pre-built libraries + libvips source
open VIPSKit.xcodeproj   # Open in Xcode
```

Press ⌘U to run tests. You can set breakpoints in both the Objective-C wrapper (`Sources/`) and the libvips C code (`Vendor/vips-*/libvips/`).

### Requirements

```bash
gem install xcodeproj     # For Xcode project configuration
```

# Building from Source

To build the XCFramework from source (instead of using pre-built libraries):

### Prerequisites

```bash
brew install meson ninja cmake nasm glib
```

### Build

```bash
./build.sh
```

This will download all sources, cross-compile for all target platforms, and produce `VIPSKit.xcframework` in the project root.

### Build Options

```bash
./build.sh --clean          # Clean all build artifacts first
./build.sh --skip-download  # Skip downloading sources
./build.sh --jobs 8         # Set parallel job count
./build.sh -f               # Rebuild framework only (fast)
```

### Creating a Pre-built Release

After building, create a tarball for GitHub releases:

```bash
./Scripts/package-prebuilt.sh 1.0.0
# Creates vipskit-prebuilt-1.0.0.tar.gz
```

# Supported Image Formats

| Format | Read | Write | Notes |
|--------|------|-------|-------|
| JPEG | Yes | Yes | libjpeg-turbo with SIMD |
| PNG | Yes | Yes | libpng |
| WebP | Yes | Yes | Lossy and lossless |
| HEIF | Yes | Yes | libheif |
| AVIF | Yes | No | Decode via dav1d |
| JPEG-XL | Yes | Yes | libjxl |
| GIF | Yes | Yes | Built-in |

# Why libvips?

Traditional image processing libraries load entire images into memory before processing. For a 20MP photo, this can mean 80MB+ of RAM just for the pixel buffer. Multiply that by a few concurrent operations, and mobile devices quickly run into memory pressure.

libvips uses a different approach: it streams pixels through a pipeline, processing only the portions needed at any time. Combined with "shrink-on-load" for formats like JPEG (which can decode directly at reduced resolution), this results in dramatically lower memory usage.

# Credits

`VIPSKit` was created by [Tim Oliver](http://twitter.com/TimOliverAU) as a component of [iComics](http://icomics.net).

libvips is developed by [John Googin-Cupples](https://github.com/jcupitt) and contributors.

# License

`VIPSKit` wrapper code is available under the MIT license.

libvips is licensed under the LGPL-2.1. As `VIPSKit` dynamically links libvips, your app can use any license compatible with dynamic linking to LGPL libraries.

Please see the [LICENSE](LICENSE) file for more information.
