# VIPSKit

Swift wrapper for [libvips](https://www.libvips.org) image processing, providing an idiomatic Swift API over a pre-built static `vips.xcframework` from [vips-cocoa](https://github.com/TimOliver/vips-cocoa).

## Overview

VIPSKit is a pure Swift framework that wraps libvips for Apple platforms. The heavy lifting (compiling libvips + 17 dependencies) is handled by the separate [vips-cocoa](https://github.com/TimOliver/vips-cocoa) project, which produces a static `vips.xcframework`. VIPSKit imports that xcframework and provides a clean, type-safe Swift API.

## Supported Platforms

| Platform | Architectures | Min Version |
|----------|--------------|-------------|
| iOS Device | arm64 | 15.0 |
| iOS Simulator | arm64, x86_64 | 15.0 |
| Mac Catalyst | arm64, x86_64 | 15.0 |
| macOS | arm64, x86_64 | 12.0 |
| visionOS | arm64 | 1.0 |
| visionOS Simulator | arm64 | 1.0 |

## Image Format Support

- JPEG (libjpeg-turbo with SIMD acceleration)
- PNG (libpng)
- WebP (libwebp)
- JPEG-XL (libjxl)
- AVIF (decode-only via dav1d + libheif)
- HEIF (libheif)
- GIF (built-in)

## Architecture

```
vips-cocoa (separate repo)              VIPSKit (this repo)
├── Builds libvips + 17 deps    →      ├── Package.swift (SPM, depends on vips-cocoa)
└── vips.xcframework (static)          ├── Sources/
                                       │   ├── *.swift (Swift wrapper, public API)
                                       │   └── Internal/
                                       │       ├── CVIPS.c (C shim for variadic funcs)
                                       │       └── include/
                                       │           ├── CVIPS.h
                                       │           ├── module.modulemap
                                       │           └── vips.h (umbrella header)
                                       ├── Tests/*.swift (13 test files)
                                       ├── Scripts/configure-project.rb (Xcode project generator)
                                       └── build.sh (xcframework builder)
```

### Why a C Shim (CVIPS)?

Nearly all libvips operations are variadic C functions (NULL-terminated key-value pairs like `vips_thumbnail(path, &out, width, "height", height, NULL)`). **Swift cannot call variadic C functions.** The CVIPS shim provides ~50 non-variadic one-liner wrappers that Swift calls instead. Non-variadic vips functions (`vips_image_get_width`, `g_object_unref`, etc.) are called directly from Swift.

### Module Map

`Sources/Internal/include/module.modulemap` defines two Clang modules:
- `vips` — umbrella for the libvips C headers (from vips.xcframework)
- `CVIPS` — the variadic function shim

Swift source files use `internal import vips` and `internal import CVIPS` to keep these as implementation details, not exposed in the public API.

## Project Structure

```
VIPSKit/
├── CLAUDE.md
├── Package.swift                      # SPM package definition
├── build.sh                           # Builds VIPSKit.xcframework
├── Sources/
│   ├── VIPSImage.swift                # Main class, lifecycle, properties, memory
│   ├── VIPSImage+Loading.swift        # File/data loading, thumbnails
│   ├── VIPSImage+Saving.swift         # File/data export
│   ├── VIPSImage+Resize.swift         # Resize operations
│   ├── VIPSImage+Transform.swift      # Crop, rotate, flip, smart crop
│   ├── VIPSImage+Color.swift          # Grayscale, adjustments, invert
│   ├── VIPSImage+Filter.swift         # Blur, sharpen, edge detection
│   ├── VIPSImage+CGImage.swift        # CGImage creation
│   ├── VIPSImage+Composite.swift      # Image compositing
│   ├── VIPSImage+Tiling.swift         # Strip/region extraction
│   ├── VIPSImage+Caching.swift        # Cache export
│   ├── VIPSError.swift                # Error type
│   ├── ImageFormat.swift              # Format enum
│   ├── ResizeKernel.swift             # Kernel enum
│   ├── BlendMode.swift                # Blend mode enum
│   ├── Interesting.swift              # Smart crop strategy enum
│   ├── ImageStatistics.swift          # Statistics struct
│   └── Internal/
│       ├── CVIPS.c                    # C shim implementation
│       └── include/
│           ├── CVIPS.h                # C shim header
│           ├── module.modulemap       # Clang module definitions
│           └── vips.h                 # Umbrella header → <vips/vips.h>
├── Tests/
│   ├── VIPSImageTestCase.swift        # Base test class with helpers
│   ├── VIPSImageCoreTests.swift
│   ├── VIPSImageLoadingTests.swift
│   ├── VIPSImageSavingTests.swift
│   ├── VIPSImageResizeTests.swift
│   ├── VIPSImageTransformTests.swift
│   ├── VIPSImageColorTests.swift
│   ├── VIPSImageFilterTests.swift
│   ├── VIPSImageCGImageTests.swift
│   ├── VIPSImageCompositeTests.swift
│   ├── VIPSImageTilingTests.swift
│   ├── VIPSImageCachingTests.swift
│   ├── VIPSImageAnalysisTests.swift
│   ├── TestHost/                      # Minimal iOS app for Xcode test runner
│   └── TestResources/superman.jpg
├── Scripts/
│   └── configure-project.rb           # Generates VIPSKit.xcodeproj
├── Frameworks/
│   └── vips.xcframework/              # Pre-built static lib (gitignored)
└── VIPSKit.xcodeproj/                 # Generated Xcode project
```

## Integration

### Swift Package Manager (Recommended)

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/TimOliver/VIPSKit.git", from: "1.0.0"),
]
```

Or in Xcode: File > Add Package Dependencies, enter the repository URL.

VIPSKit automatically pulls in the pre-built `vips.xcframework` from vips-cocoa via SPM binary targets.

### XCFramework (Manual)

Build the xcframework:

```bash
# Copy static vips.xcframework from vips-cocoa first
cp -R ~/Developer/vips-cocoa/build/xcframeworks/ios/static/vips.xcframework Frameworks/

# Generate Xcode project and build xcframework
ruby Scripts/configure-project.rb
./build.sh
```

Then drag `VIPSKit.xcframework` into your Xcode project, set "Embed & Sign".

## Development Setup

### Prerequisites

- Xcode with command-line tools
- Ruby with `xcodeproj` gem: `gem install xcodeproj`
- Static `vips.xcframework` in `Frameworks/` (from vips-cocoa)

### Xcode Development

```bash
# Copy vips.xcframework
cp -R ~/Developer/vips-cocoa/build/xcframeworks/ios/static/vips.xcframework Frameworks/

# Generate project
ruby Scripts/configure-project.rb

# Open and run tests
open VIPSKit.xcodeproj  # ⌘U to run tests
```

### SPM Development

```bash
swift build          # Build
swift test           # Run tests (requires test resources)
```

### Build Options

```bash
./build.sh           # Build VIPSKit.xcframework (iOS, Simulator, Catalyst)
./build.sh --clean   # Clean first
./build.sh --fast    # Build for current platform only
```

## Swift Usage

```swift
import VIPSKit

// Initialize once at app start
try VIPSImage.initialize()

// Load image
let image = try VIPSImage(contentsOfFile: path)
let image = try VIPSImage(data: imageData)

// Properties
print("Size: \(image.width)x\(image.height)")
print("Bands: \(image.bands), hasAlpha: \(image.hasAlpha)")

// Resize
let fitted = try image.resizeToFit(width: 200, height: 200)
let scaled = try image.resize(scale: 0.5)
let exact = try image.resize(toWidth: 400, height: 300)

// Transform
let cropped = try image.crop(x: 10, y: 10, width: 100, height: 100)
let rotated = try image.rotate(byDegrees: 90)
let flipped = try image.flipHorizontal()
let oriented = try image.autoRotate()
let smart = try image.smartCrop(toWidth: 400, height: 400, interesting: .attention)

// Color
let gray = try image.grayscale()
let brighter = try image.adjustBrightness(0.2)
let adjusted = try image.adjust(brightness: 0.1, contrast: 1.2, saturation: 1.1)
let inverted = try image.invert()
let gammaCorrected = try image.adjustGamma(2.2)
let flattened = try image.flatten(red: 255, green: 255, blue: 255)

// Filter
let blurred = try image.blur(sigma: 2.0)
let sharpened = try image.sharpen(sigma: 1.0)
let edges = try image.sobel()
let cannyEdges = try image.canny(sigma: 1.4)

// Composite
let watermarked = try base.composite(withOverlay: overlay, mode: .over, x: 10, y: 10)

// Thumbnail (shrink-on-load, most memory efficient)
let thumb = try VIPSImage.thumbnail(fromFile: path, width: 200, height: 200)

// CGImage (zero-copy for display)
if let cgImage = try image.createCGImage() {
    let uiImage = UIImage(cgImage: cgImage)
}

// Direct thumbnail to CGImage (minimal peak memory)
if let cgImage = try VIPSImage.createThumbnail(fromFile: path, width: 200, height: 200) {
    let uiImage = UIImage(cgImage: cgImage)
}

// Export
let jpegData = try image.data(format: .jpeg, quality: 85)
let webpData = try image.data(format: .webP, quality: 80)
try image.write(toFile: "/path/to/output.jpg")

// Tiling
let strips = image.numberOfStrips(withHeight: 1000)
for i in 0..<strips {
    let strip = try image.strip(atIndex: i, height: 1000)
}
let region = try VIPSImage.extractRegion(fromFile: path, x: 0, y: 0, width: 500, height: 500)

// Analysis
let bounds = try image.findTrim(threshold: 20.0)
let stats = try image.statistics()
let avgColor = try image.averageColor()
let bgColor = try image.detectBackgroundColor()
let diff = try image1.subtract(image2)

// Caching
let cacheData = try image.cacheData()  // Lossless WebP
try image.writeToCache(file: "/path/to/cache/thumb")

// Raw pixel access
try image.withPixelData { data, width, height, bytesPerRow, bands in
    // data is UInt8 pointer, valid only within this block
}

// Memory management
let copied = try image.copyToMemory()  // Break lazy reference chain
VIPSImage.clearCache()
VIPSImage.setCacheMaxMemory(25 * 1024 * 1024)

// Cleanup
VIPSImage.shutdown()
```

## API Reference

### VIPSImage

| Method/Property | Description |
|--------|-------------|
| `initialize()` | Initialize libvips (call once at app start) |
| `shutdown()` | Cleanup libvips (optional, at app termination) |
| `width`, `height`, `bands`, `hasAlpha` | Image dimensions and channels |
| `init(contentsOfFile:)` | Load image from file path |
| `init(data:)` | Load image from Data |
| `init(buffer:width:height:bands:)` | Create from raw pixel buffer |
| `thumbnail(fromFile:width:height:)` | Shrink-on-load thumbnail |
| `createThumbnail(fromFile:width:height:)` | Thumbnail direct to CGImage |
| `write(toFile:)` | Save to file (format from extension) |
| `data(format:quality:)` | Export to Data |
| `createCGImage()` | Create CGImage (most efficient for display) |
| `resizeToFit(width:height:)` | Resize maintaining aspect ratio |
| `resize(scale:kernel:)` | Scale by factor |
| `resize(toWidth:height:)` | Resize to exact dimensions |
| `crop(x:y:width:height:)` | Crop region |
| `rotate(byDegrees:)` | Rotate 90/180/270 degrees |
| `flipHorizontal()`, `flipVertical()` | Mirror |
| `autoRotate()` | Apply EXIF orientation |
| `smartCrop(toWidth:height:interesting:)` | Content-aware crop |
| `composite(withOverlay:mode:x:y:)` | Composite with blend mode |
| `grayscale()` | Convert to grayscale |
| `flatten(red:green:blue:)` | Flatten alpha to background |
| `invert()` | Invert colors |
| `adjustBrightness(_:)` | Adjust brightness (-1.0 to 1.0) |
| `adjustContrast(_:)` | Adjust contrast (0.5 to 2.0) |
| `adjustSaturation(_:)` | Adjust saturation (0 to 2.0) |
| `adjustGamma(_:)` | Adjust gamma curve |
| `adjust(brightness:contrast:saturation:)` | Combined adjustment |
| `blur(sigma:)` | Gaussian blur |
| `sharpen(sigma:)` | Sharpen |
| `sobel()` | Sobel edge detection |
| `canny(sigma:)` | Canny edge detection |
| `copyToMemory()` | Break lazy reference chain |
| `withPixelData(_:)` | Zero-copy raw pixel access |
| `findTrim(threshold:background:)` | Find content bounding box |
| `statistics()` | Image statistics (min, max, mean, stddev) |
| `averageColor()` | Per-band mean values |
| `detectBackgroundColor(stripWidth:)` | Detect background by sampling edges |
| `subtract(_:)` | Pixel-wise subtraction |
| `absolute()` | Absolute value of pixels |
| `numberOfStrips(withHeight:)` | Count horizontal strips |
| `strip(atIndex:height:)` | Extract horizontal strip |
| `extractRegion(fromFile:x:y:width:height:)` | Extract region from file |
| `cacheData(format:quality:lossless:)` | Export for caching |
| `writeToCache(file:format:quality:lossless:)` | Write cache file |
| `clearCache()` | Clear operation cache |
| `setCacheMaxOperations(_:)` | Set max cached operations |
| `setCacheMaxMemory(_:)` | Set max cache memory |
| `memoryUsage()` | Current tracked memory |

### Enums

| Type | Values |
|------|--------|
| `ImageFormat` | `.unknown`, `.jpeg`, `.png`, `.webP`, `.heif`, `.avif`, `.jxl`, `.gif` |
| `ResizeKernel` | `.nearest`, `.linear`, `.cubic`, `.lanczos2`, `.lanczos3` |
| `BlendMode` | `.over`, `.multiply`, `.screen`, `.overlay`, `.add`, `.darken`, `.lighten`, `.softLight`, `.hardLight`, `.difference`, `.exclusion` |
| `Interesting` | `.none`, `.centre`, `.entropy`, `.attention`, `.low`, `.high` |

### ImageStatistics

| Property | Description |
|----------|-------------|
| `min` | Minimum pixel value |
| `max` | Maximum pixel value |
| `mean` | Mean pixel value |
| `standardDeviation` | Standard deviation |

## Architecture Notes

### Internal Implementation

- `VIPSImage` wraps an `UnsafeMutablePointer<VipsImage>` (NOT `OpaquePointer` — VipsImage is imported as a concrete C struct through the module map)
- `g_object_ref`/`g_object_unref` require `gpointer()` casts
- `vips_init()` is called directly (the `VIPS_INIT` macro is not callable from Swift)
- Uses `internal import` (Swift 5.9+ `AccessLevelOnImport`) to hide C types from public API

### Lazy Evaluation

libvips uses lazy evaluation — operations build a pipeline that only executes when output is needed. Use `copyToMemory()` to break reference chains and free source images early.

### Threading

Default: VIPS concurrency = 1 (single-threaded per operation). Parallelize at the application layer with `DispatchQueue.concurrentPerform`. For single large images, use `VIPSImage.setConcurrency(0)` for all cores.

### CGImage Export

`createCGImage()` transfers pixels directly from libvips to CoreGraphics via `CGDataProvider`, avoiding encode/decode overhead. The `CGDataProvider` release callback frees vips memory when the CGImage is deallocated.

### Thread Safety

VIPSImage is `@unchecked Sendable`. Safe to use from multiple threads with each thread processing different images. The vips operation cache uses mutexes internally.

### vips_cache_drop_all Bug (Workaround)

`clearCache()` does NOT call `vips_cache_drop_all()` (which crashes by destroying the hash table). Instead it temporarily sets `vips_cache_set_max(0)` to evict all entries, then restores the limit.

## License

- libvips: LGPL-2.1
- VIPSKit: MIT
