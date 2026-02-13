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
- AVIF (decode-only via dav1d + libheif — no encoder)
- HEIF (decode-only via libheif — no encoder)
- GIF (decode-only, built-in — no encoder)
- TIFF (built-in)

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
                                       ├── Tests/*.swift (22 test files)
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
│   ├── VIPSImage.swift                # Main class, lifecycle, Cache namespace, PixelBuffer, concurrency
│   ├── VIPSImage+Loading.swift        # File/data loading, thumbnails, imageInfo
│   ├── VIPSImage+Saving.swift         # File/data export
│   ├── VIPSImage+Resize.swift         # Resize operations
│   ├── VIPSImage+Transform.swift      # Crop, flip, smart crop
│   ├── VIPSImage+Rotate.swift         # Rotation operations
│   ├── VIPSImage+Color.swift          # Grayscale, adjustments, invert, flatten
│   ├── VIPSImage+Filter.swift         # Blur, sharpen, edge detection
│   ├── VIPSImage+CGImage.swift        # CGImage creation (cgImage property, thumbnailCGImage)
│   ├── VIPSImage+Composite.swift      # Image compositing
│   ├── VIPSImage+Tiling.swift         # Strip/region extraction
│   ├── VIPSImage+Band.swift           # Alpha, premultiply, band operations
│   ├── VIPSImage+Histogram.swift      # Histogram equalization
│   ├── VIPSImage+Pixel.swift          # Raw pixel value access
│   ├── VIPSImage+Embed.swift          # Gravity/embed operations
│   ├── VIPSImage+Draw.swift           # Drawing primitives (rect, line, circle, flood fill)
│   ├── VIPSImage+Analysis.swift       # Statistics, trim, average color, background detection
│   ├── VIPSImage+Metadata.swift       # EXIF/metadata access, MetadataProxy subscript
│   ├── VIPSColor.swift                # RGB color type, ink(forBands:), CGColor/UIColor/NSColor interop
│   ├── VIPSError.swift                # Error type
│   ├── VIPSImageFormat.swift          # Format enum
│   ├── VIPSImageStatistics.swift      # Statistics struct
│   ├── VIPSResizeKernel.swift         # Kernel enum (with vipsValue)
│   ├── VIPSBlendMode.swift            # Blend mode enum (with vipsValue)
│   ├── VIPSInteresting.swift          # Smart crop strategy enum (with vipsValue)
│   ├── VIPSExtendMode.swift           # Extend mode enum (with vipsValue)
│   ├── VIPSCompassDirection.swift     # Compass direction enum (with vipsValue)
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
│   ├── VIPSImageRotateTests.swift
│   ├── VIPSImageColorTests.swift
│   ├── VIPSImageFilterTests.swift
│   ├── VIPSImageCGImageTests.swift
│   ├── VIPSImageCompositeTests.swift
│   ├── VIPSImageTilingTests.swift
│   ├── VIPSImageHistogramTests.swift
│   ├── VIPSImageBandTests.swift
│   ├── VIPSImagePixelTests.swift
│   ├── VIPSImageEmbedTests.swift
│   ├── VIPSImageDrawTests.swift
│   ├── VIPSImageAnalysisTests.swift
│   ├── VIPSImageMetadataTests.swift
│   ├── VIPSColorTests.swift
│   ├── VIPSErrorTests.swift
│   ├── VIPSImageFormatTests.swift
│   ├── TestHost/                      # Minimal iOS app for Xcode test runner
│   └── TestResources/                 # Test images (superman.jpg, test.jpg, grayscale.jpg,
│                                      #   rotated-3.jpg, rotated-6.jpg, test-rgb.png,
│                                      #   test-rgba.png, tiny.png)
├── Scripts/
│   ├── configure-project.rb           # Generates VIPSKit.xcodeproj
│   └── generate-test-images.swift     # Test image generator using CoreGraphics/ImageIO
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

// Resize (CGSize overloads available for all)
let fitted = try image.resizeToFit(width: 200, height: 200)
let scaled = try image.resize(scale: 0.5)
let exact = try image.resize(toWidth: 400, height: 300)

// Transform
let cropped = try image.crop(x: 10, y: 10, width: 100, height: 100)
let cropped2 = try image.crop(CGRect(x: 10, y: 10, width: 100, height: 100))
let rotated = try image.rotate(degrees: 90)
let flipped = try image.flippedHorizontally()
let oriented = try image.autoRotated()
let smart = try image.smartCrop(toWidth: 400, height: 400, interesting: .attention)
let side = try image.joinedHorizontally(with: other)
let stacked = try image.joinedVertically(with: other)

// Color
let gray = try image.grayscaled()
let brighter = try image.adjustBrightness(0.2)
let adjusted = try image.adjust(brightness: 0.1, contrast: 1.2, saturation: 1.1)
let inverted = try image.inverted()
let gammaCorrected = try image.adjustGamma(2.2)
let flattened = try image.flatten(background: .white)

// Filter
let blurred = try image.blurred(sigma: 2.0)
let sharpened = try image.sharpened(sigma: 1.0)
let edges = try image.sobel()
let cannyEdges = try image.canny(sigma: 1.4)

// Composite (CGPoint overload available)
let watermarked = try base.composite(withOverlay: overlay, mode: .over, x: 10, y: 10)

// Drawing (mutates in-place, chainable)
let canvas = try VIPSImage.blank(width: 200, height: 200)
try canvas
    .drawRect(x: 10, y: 10, width: 50, height: 50,
              color: VIPSColor(red: 255, green: 0, blue: 0), fill: true)
    .drawLine(from: CGPoint(x: 0, y: 0), to: CGPoint(x: 99, y: 99),
              color: .white)
    .drawCircle(cx: 50, cy: 50, radius: 30, color: .black, fill: true)

// Thumbnail (shrink-on-load, most memory efficient)
let thumb = try VIPSImage.thumbnail(fromFile: path, width: 200, height: 200)

// CGImage (zero-copy for display)
let cgImage = try image.cgImage
let uiImage = UIImage(cgImage: cgImage)

// Direct thumbnail to CGImage (minimal peak memory)
let thumbCG = try VIPSImage.thumbnailCGImage(fromFile: path, width: 200, height: 200)
let thumbUI = UIImage(cgImage: thumbCG)

// Export
let jpegData = try image.data(format: .jpeg, quality: 85)
let webpData = try image.data(format: .webP, quality: 80)
let losslessWebP = try image.data(format: .webP, lossless: true)
try image.write(toFile: "/path/to/output.jpg")

// Tiling
let strips = image.numberOfStrips(withHeight: 1000)
for i in 0..<strips {
    let strip = try image.strip(atIndex: i, height: 1000)
}
let region = try VIPSImage.extractRegion(fromFile: path, x: 0, y: 0, width: 500, height: 500)

// Analysis
let bounds = try image.findTrim(threshold: 20.0)
let boundsExplicit = try image.findTrim(threshold: 5.0, background: VIPSColor(red: 255, green: 255, blue: 255))
let stats = try image.statistics()
let avgColor = try image.averageColor()
let bgColor = try image.detectBackgroundColor()
let diff = try image1.subtract(image2)

// Metadata
let orient = image.orientation                       // EXIF orientation (1-8)
let make = image.exifField("Make")                   // e.g., "Canon"
let pages = image.pageCount                          // Multi-page count
let icc = image.iccProfile                           // Raw ICC data
image.metadata["my-custom-key"] = "value"            // Subscript access via MetadataProxy

// Raw pixel access (via PixelBuffer struct)
try image.withPixelData { buffer in
    // buffer.data, buffer.width, buffer.height, buffer.bytesPerRow, buffer.bands
}

// Memory management
let copied = try image.copiedToMemory()  // Break lazy reference chain
VIPSImage.Cache.clear()
VIPSImage.Cache.maxMemory = 25 * 1024 * 1024

// Cache configuration
VIPSImage.Cache.maxOperations = 100
VIPSImage.Cache.maxFiles = 100
VIPSImage.concurrency = 0  // Use all cores

// Cleanup
VIPSImage.shutdown()
```

### Async Usage

All I/O-bound and CPU-heavy operations have `async throws` variants that use `Task.detached` to move work off the calling actor. This is safe because `VIPSImage` is `@unchecked Sendable`.

```swift
// Async loading (static factories — Swift doesn't support async init)
let image = try await VIPSImage.loaded(fromFile: path)
let image = try await VIPSImage.loaded(data: imageData)
let thumb = try await VIPSImage.thumbnail(fromFile: path, width: 200, height: 200)

// Async resize (past-tense naming)
let fitted = try await image.resizedToFit(width: 200, height: 200)
let scaled = try await image.resized(scale: 0.5)
let exact = try await image.resized(toWidth: 400, height: 300)

// Async transform
let cropped = try await image.cropped(x: 10, y: 10, width: 100, height: 100)
let smart = try await image.smartCropped(toWidth: 400, height: 400)

// Async color/filter
let gray = try await image.grayscaled()
let blurred = try await image.blurred(sigma: 2.0)
let adjusted = try await image.adjusted(brightness: 0.1, contrast: 1.2, saturation: 1.1)

// Async CGImage
let cgImage = try await image.makeCGImage()
let thumbCG = try await VIPSImage.thumbnailCGImage(fromFile: path, width: 200, height: 200)

// Async export
let jpegData = try await image.encoded(format: .jpeg, quality: 85)
try await image.write(toFile: "/path/to/output.jpg")

// Async analysis
let bounds = try await image.findTrim()
let bgColor = try await image.detectedBackgroundColor()
```

## API Reference

### VIPSImage

| Method/Property | Description |
|--------|-------------|
| `initialize()` | Initialize libvips (call once at app start) |
| `shutdown()` | Cleanup libvips (optional, at app termination) |
| `width`, `height`, `bands`, `hasAlpha` | Image dimensions and channels |
| `loaderName` | Internal vips loader name (e.g., `"jpegload"`) |
| `sourceFormat` | Detected source format enum |
| `init(contentsOfFile:)` | Load image from file path |
| `init(contentsOfFileSequential:)` | Load with sequential (streaming) access |
| `init(data:)` | Load image from Data |
| `init(buffer:width:height:bands:)` | Create from raw pixel buffer |
| `thumbnail(fromFile:width:height:)` | Shrink-on-load thumbnail from file |
| `thumbnail(fromFile:size:)` | Shrink-on-load thumbnail from file (CGSize) |
| `thumbnail(fromData:width:height:)` | Shrink-on-load thumbnail from Data |
| `thumbnail(fromData:size:)` | Shrink-on-load thumbnail from Data (CGSize) |
| `thumbnailCGImage(fromFile:width:height:)` | Thumbnail direct to CGImage |
| `thumbnailCGImage(fromFile:size:)` | Thumbnail direct to CGImage (CGSize) |
| `write(toFile:)` | Save to file (format from extension). Supported: JPEG, PNG, WebP, JXL, TIFF |
| `write(toFile:format:quality:lossless:)` | Save to file with explicit format. Lossless option for WebP/JXL. HEIF/AVIF/GIF not supported (decode-only) |
| `data(format:quality:lossless:)` | Export to Data. Lossless option for WebP/JXL. HEIF/AVIF/GIF not supported (decode-only) |
| `cgImage` | Throwing computed property → CGImage |
| `resizeToFit(width:height:)` | Resize maintaining aspect ratio |
| `resizeToFit(size:)` | Resize maintaining aspect ratio (CGSize) |
| `resize(scale:kernel:)` | Scale by factor |
| `resize(toWidth:height:)` | Resize to exact dimensions |
| `resize(to:)` | Resize to exact dimensions (CGSize) |
| `crop(x:y:width:height:)` | Crop region |
| `crop(_ rect:)` | Crop region (CGRect) |
| `rotate(degrees:)` | Rotate by a multiple of 90 degrees |
| `flippedHorizontally()` | Mirror horizontally |
| `flippedVertically()` | Mirror vertically |
| `autoRotated()` | Apply EXIF orientation |
| `smartCrop(toWidth:height:interesting:)` | Content-aware crop |
| `smartCrop(to:interesting:)` | Content-aware crop (CGSize) |
| `joinedHorizontally(with:)` | Join two images side by side horizontally |
| `joinedVertically(with:)` | Join two images stacked vertically |
| `composite(withOverlay:mode:x:y:)` | Composite with blend mode |
| `composite(withOverlay:mode:at:)` | Composite with blend mode (CGPoint) |
| `grayscaled()` | Convert to grayscale |
| `flatten(background:)` | Flatten alpha to VIPSColor background |
| `inverted()` | Invert colors |
| `adjustBrightness(_:)` | Adjust brightness (-1.0 to 1.0) |
| `adjustContrast(_:)` | Adjust contrast (0.5 to 2.0) |
| `adjustSaturation(_:)` | Adjust saturation (0 to 2.0) |
| `adjustGamma(_:)` | Adjust gamma curve |
| `adjust(brightness:contrast:saturation:)` | Combined adjustment |
| `blurred(sigma:)` | Gaussian blur |
| `sharpened(sigma:)` | Sharpen |
| `sobel()` | Sobel edge detection |
| `canny(sigma:)` | Canny edge detection |
| `histogramEqualized()` | Equalize histogram |
| `addingAlpha()` | Add alpha band |
| `premultiplied()` | Premultiply alpha |
| `unpremultiplied()` | Unpremultiply alpha |
| `copiedToMemory()` | Break lazy reference chain |
| `withPixelData(_:)` | Zero-copy raw pixel access (PixelBuffer) |
| `findTrim(threshold:background:)` | Find content bounding box |
| `statistics()` | Image statistics (min, max, mean, stddev) |
| `averageColor()` | Per-band mean values → VIPSColor |
| `detectBackgroundColor(stripWidth:)` | Detect background via trim margins or prominent edge color → VIPSColor |
| `subtract(_:)` | Pixel-wise subtraction |
| `absolute()` | Absolute value of pixels |
| `tileRects(tileWidth:tileHeight:)` | Calculate tile grid rectangles |
| `numberOfStrips(withHeight:)` | Count horizontal strips |
| `strip(atIndex:height:)` | Extract horizontal strip |
| `extractRegion(fromFile:x:y:width:height:)` | Extract region from file |
| `extractRegion(fromData:x:y:width:height:)` | Extract region from Data |
| `memoryUsage` | Current tracked memory (static property) |
| `memoryHighWater` | Peak tracked memory (static property) |
| `resetMemoryHighWater()` | Reset peak memory counter |
| `blank(width:height:bands:)` | Create blank (black) image |
| `blank(size:bands:)` | Create blank image (CGSize) |
| `drawRect(x:y:width:height:color:fill:)` | Draw rectangle (mutates in-place, chainable) |
| `drawLine(from:to:color:)` | Draw line (mutates in-place, chainable) |
| `drawCircle(cx:cy:radius:color:fill:)` | Draw circle (mutates in-place, chainable) |
| `drawCircle(center:radius:color:fill:)` | Draw circle CGPoint (mutates in-place, chainable) |
| `floodFill(x:y:color:)` | Flood fill connected region (mutates in-place, chainable) |
| `floodFill(at:color:)` | Flood fill CGPoint (mutates in-place, chainable) |
| `gravity(direction:width:height:extend:)` | Embed with gravity |
| `gravity(direction:size:extend:)` | Embed with gravity (CGSize) |
| `pixelValues(atX:y:)` | Read pixel values at coordinates → VIPSColor |
| `pixelValues(at:)` | Read pixel values (CGPoint) → VIPSColor |
| `imageInfo(atPath:)` | Get image info without full decode |
| `metadata` | MetadataProxy for subscript access |
| `metadataFields` | All metadata field names |
| `hasMetadata(named:)` | Check if field exists |
| `getString(named:)` | Get string metadata |
| `getInt(named:)` | Get integer metadata |
| `getDouble(named:)` | Get double metadata |
| `getBlob(named:)` | Get binary blob metadata (EXIF, XMP, ICC) |
| `setString(named:value:)` | Set string metadata |
| `setInt(named:value:)` | Set integer metadata |
| `setDouble(named:value:)` | Set double metadata |
| `removeMetadata(named:)` | Remove a metadata field |
| `orientation` | EXIF orientation tag (1-8) |
| `xResolution`, `yResolution` | Resolution in pixels/mm |
| `pageCount` | Number of pages (multi-page images) |
| `pageHeight` | Single page height (multi-page images) |
| `exifData` | Raw EXIF data blob |
| `xmpData` | Raw XMP metadata blob |
| `iccProfile` | ICC color profile data |
| `exifField(_:)` | Read parsed EXIF tag by name |

#### Async Variants

Most I/O-bound and CPU-heavy methods have `async throws` overloads using `Task.detached` to move work off the calling actor. Naming convention: past tense for renamed variants, same name for already past-tense methods.

| Method/Property | Description |
|--------|-------------|
| `loaded(fromFile:)` | Load image from file path (static factory for `init(contentsOfFile:)`) |
| `loaded(fromFileSequential:)` | Load with sequential (streaming) access (static factory for `init(contentsOfFileSequential:)`) |
| `loaded(data:)` | Load image from Data (static factory for `init(data:)`) |
| `thumbnail(fromFile:width:height:)` | Shrink-on-load thumbnail from file |
| `thumbnail(fromFile:size:)` | Shrink-on-load thumbnail from file (CGSize) |
| `thumbnail(fromData:width:height:)` | Shrink-on-load thumbnail from Data |
| `thumbnail(fromData:size:)` | Shrink-on-load thumbnail from Data (CGSize) |
| `imageInfo(atPath:)` | Get image dimensions and format without full decode |
| `write(toFile:)` | Save to file (format inferred from extension). Supported: JPEG, PNG, WebP, JXL, TIFF |
| `write(toFile:format:quality:lossless:)` | Save to file with explicit format. Lossless option for WebP/JXL. HEIF/AVIF/GIF not supported (decode-only) |
| `encoded(format:quality:lossless:)` | Export to Data (async name for `data(format:quality:lossless:)`). Lossless option for WebP/JXL. HEIF/AVIF/GIF not supported (decode-only) |
| `makeCGImage()` | Create CGImage via direct pixel transfer (async name for `cgImage` property) |
| `thumbnailCGImage(fromFile:width:height:)` | Shrink-on-load thumbnail direct to CGImage |
| `thumbnailCGImage(fromFile:size:)` | Shrink-on-load thumbnail direct to CGImage (CGSize) |
| `resizedToFit(width:height:)` | Resize maintaining aspect ratio |
| `resizedToFit(size:)` | Resize maintaining aspect ratio (CGSize) |
| `resized(scale:kernel:)` | Scale by factor with interpolation kernel |
| `resized(toWidth:height:)` | Resize to exact dimensions |
| `resized(to:)` | Resize to exact dimensions (CGSize) |
| `cropped(x:y:width:height:)` | Crop rectangular region |
| `cropped(_:)` | Crop rectangular region (CGRect) |
| `smartCropped(toWidth:height:interesting:)` | Content-aware crop keeping most important region |
| `smartCropped(to:interesting:)` | Content-aware crop (CGSize) |
| `joinedHorizontally(with:)` | Join two images side by side horizontally |
| `joinedVertically(with:)` | Join two images stacked vertically |
| `rotated(byAngle:)` | Rotate by arbitrary angle with black corner fill |
| `grayscaled()` | Convert to grayscale (single-band luminance) |
| `flattened(background:)` | Flatten alpha channel against a VIPSColor background |
| `inverted()` | Invert colors (photographic negative) |
| `adjustedBrightness(_:)` | Adjust brightness (-1.0 to 1.0) |
| `adjustedContrast(_:)` | Adjust contrast (0.5 to 2.0) |
| `adjustedSaturation(_:)` | Adjust saturation via LCH chroma scaling (0 to 2.0) |
| `adjustedGamma(_:)` | Adjust gamma curve |
| `adjusted(brightness:contrast:saturation:)` | Combined brightness/contrast/saturation in one pass |
| `blurred(sigma:)` | Gaussian blur |
| `sharpened(sigma:)` | Sharpen via unsharp mask |
| `sobel()` | Sobel edge detection |
| `canny(sigma:)` | Canny edge detection (8-bit output) |
| `composited(withOverlay:mode:x:y:)` | Composite with blend mode at position |
| `composited(withOverlay:mode:at:)` | Composite with blend mode at CGPoint |
| `composited(withOverlay:mode:)` | Composite with blend mode, overlay centered |
| `findTrim(threshold:background:)` | Find content bounding box by detecting margins |
| `statistics()` | Image statistics (min, max, mean, stddev) |
| `averageColor()` | Per-band mean values → VIPSColor |
| `detectedBackgroundColor(stripWidth:)` | Detect background via trim margins or prominent edge color → VIPSColor |
| `histogramEqualized()` | Equalize histogram for improved contrast |
| `extractedRegion(fromFile:x:y:width:height:)` | Extract region from file without full decode |
| `extractedRegion(fromData:x:y:width:height:)` | Extract region from Data without full decode |
| `copiedToMemory()` | Break lazy evaluation chain, copy pixels to contiguous memory |

### VIPSImage.Cache

| Method/Property | Description |
|--------|-------------|
| `Cache.maxOperations` | Max cached operations (read-write) |
| `Cache.maxMemory` | Max cache memory in bytes (read-write) |
| `Cache.maxFiles` | Max cached files (read-write) |
| `Cache.clear()` | Clear operation cache |

### VIPSImage.concurrency

| Property | Description |
|----------|-------------|
| `concurrency` | VIPS concurrency level (read-write, 0 = all cores) |

### VIPSColor

| Member | Description |
|--------|-------------|
| `values` | Raw per-band `[Double]` values (0.0–255.0 for 8-bit) |
| `red`, `green`, `blue` | Per-component `Double` accessors |
| `alpha` | Optional alpha `Double` (nil if < 4 bands) |
| `init(red:green:blue:)` | Create color from UInt8 components |
| `init(values:)` | Create from per-band `[Double]` values |
| `.white` | Pure white constant |
| `.black` | Pure black constant |
| `subscript(position:)` | Band value by index (`RandomAccessCollection`) |
| `init?(cgColor:)` | Create from CGColor (converts to sRGB, failable) |
| `cgColor` | Export as CGColor in sRGB color space |
| `init?(uiColor:)` | Create from UIColor (iOS/visionOS/Catalyst only) |
| `uiColor` | Export as UIColor (iOS/visionOS/Catalyst only) |
| `init?(nsColor:)` | Create from NSColor (macOS only, non-Catalyst) |
| `nsColor` | Export as NSColor (macOS only, non-Catalyst) |

### PixelBuffer

| Property | Description |
|----------|-------------|
| `data` | `UnsafePointer<UInt8>` to pixel data |
| `width` | Image width in pixels |
| `height` | Image height in pixels |
| `bytesPerRow` | Row stride in bytes |
| `bands` | Number of bands/channels |

### MetadataProxy

| Member | Description |
|--------|-------------|
| `subscript(key: String) -> String?` | Get/set string metadata by key |

### Enums

| Type | Values |
|------|--------|
| `VIPSImageFormat` | `.unknown`, `.jpeg`, `.png`, `.webP`, `.heif`, `.avif`, `.jxl`, `.gif`, `.tiff` (also has `fileExtension` property) |
| `VIPSResizeKernel` | `.nearest`, `.linear`, `.cubic`, `.lanczos2`, `.lanczos3` |
| `VIPSBlendMode` | `.clear`, `.source`, `.over`, `.in`, `.out`, `.atop`, `.dest`, `.destOver`, `.destIn`, `.destOut`, `.destAtop`, `.xor`, `.add`, `.saturate`, `.multiply`, `.screen`, `.overlay`, `.darken`, `.lighten`, `.colourDodge`, `.colourBurn`, `.hardLight`, `.softLight`, `.difference`, `.exclusion` |
| `VIPSInteresting` | `.none`, `.centre`, `.entropy`, `.attention`, `.low`, `.high` |
| `VIPSExtendMode` | `.black`, `.copy`, `.repeat`, `.mirror`, `.white`, `.background` |
| `VIPSCompassDirection` | `.centre`, `.north`, `.east`, `.south`, `.west`, `.northEast`, `.southEast`, `.southWest`, `.northWest` |

### VIPSImageStatistics

| Property | Description |
|----------|-------------|
| `min` | Minimum pixel value |
| `max` | Maximum pixel value |
| `mean` | Mean pixel value |
| `standardDeviation` | Standard deviation |

## Coding Conventions

### Documentation Comments

Every public method and property must have a comprehensive Swift doc comment including:
- A description of what the operation does (not just the method name restated)
- `- Parameter` entries for every parameter, with type/range info where relevant
- `- Returns:` describing what is returned
- Any important behavioral notes (e.g., memory implications, format limitations)

Example of the expected style:
```swift
/// Resize the image to fit within the given dimensions while maintaining aspect ratio.
/// Uses high-quality shrink-on-load when possible for optimal performance.
/// - Parameters:
///   - width: The maximum width of the result
///   - height: The maximum height of the result
/// - Returns: A new image that fits within the specified dimensions
```

When adding new methods to CLAUDE.md's API Reference tables, each entry's Description column should be a concise but informative summary (not just "see sync version" or a bare method name restatement).

## Architecture Notes

### Internal Implementation

- `VIPSImage` wraps an `UnsafeMutablePointer<VipsImage>` (NOT `OpaquePointer` — VipsImage is imported as a concrete C struct through the module map)
- `g_object_ref`/`g_object_unref` require `gpointer()` casts
- `vips_init()` is called directly (the `VIPS_INIT` macro is not callable from Swift)
- Uses `internal import` (Swift 5.9+ `AccessLevelOnImport`) to hide C types from public API
- Enums have `internal var vipsValue` computed properties that map to C counterparts via `rawValue`, eliminating switch boilerplate

### VIPSColor and Ink Conversion

`VIPSColor` stores per-band `Double` values internally (via `values: [Double]`), used both as input (drawing, flatten) and output (averageColor, pixelValues, detectBackgroundColor). Conforms to `RandomAccessCollection` for subscript/iteration. `init(red: UInt8, ...)` converts to Double storage; `init(values:)` takes raw band data. `red`/`green`/`blue` accessors return `Double`. For drawing, `ink(forBands:)` converts to a `[Double]` array matching the image's band count:
- 1-band: luminance approximation `0.2126*R + 0.7152*G + 0.0722*B`
- 3-band: `[R, G, B]`
- 4-band: `[R, G, B, 255.0]` (fully opaque)

### Lazy Evaluation

libvips uses lazy evaluation — operations build a pipeline that only executes when output is needed. Use `copiedToMemory()` to break reference chains and free source images early.

### Threading

Default: VIPS concurrency = 1 (single-threaded per operation). Parallelize at the application layer with `DispatchQueue.concurrentPerform`. For single large images, use `VIPSImage.concurrency = 0` for all cores.

### CGImage Export

`cgImage` (throwing computed property) transfers pixels directly from libvips to CoreGraphics via `CGDataProvider`, avoiding encode/decode overhead. The `CGDataProvider` release callback frees vips memory when the CGImage is deallocated.

### Thread Safety

VIPSImage is `@unchecked Sendable`. Safe to use from multiple threads with each thread processing different images. The vips operation cache uses mutexes internally.

### Async Pattern

All async wrappers use the same `Task.detached` pattern to move work off the calling actor (critical for `@MainActor` callers). `VIPSImage` being `@unchecked Sendable` enables clean crossing of task boundaries. Naming uses past tense (`resize` → `resized`, `crop` → `cropped`). Methods already in past tense (`blurred`, `inverted`) get same-name async overloads differentiated by the `async` keyword. `init` → static factories (`loaded(fromFile:)`) since Swift doesn't support `async init`.

Each async method carries the same comprehensive doc comment as its sync counterpart (description, parameter docs, return docs), plus a standard note: "The work is performed off the calling actor via `Task.detached`."

### Background Color Detection

`detectBackgroundColor(stripWidth:)` uses a two-step approach:

1. **Trim-based** — calls `findTrim()` to detect content margins. If the content rect is inset from the image bounds on any side (e.g., a white spine on a comic page), it samples from those margin areas using a pixel-count-weighted average across all margin strips.
2. **Prominent edge color** (fallback) — when no trim margins exist (content fills to all edges), it reads raw pixels from edge strips via `withPixelData`, quantizes each pixel's RGB into color buckets (step size 32 → 8 levels per channel, 512 buckets), and returns the average actual color of the most frequent bucket. This finds the dominant edge color rather than the average, which avoids content colors pulling the result off.

### vips_cache_drop_all Bug (Workaround)

`Cache.clear()` does NOT call `vips_cache_drop_all()` (which crashes by destroying the hash table). Instead it temporarily sets `vips_cache_set_max(0)` to evict all entries, then restores the limit.

## License

- libvips: LGPL-2.1
- VIPSKit: MIT
