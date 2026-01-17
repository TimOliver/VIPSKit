# vips-cocoa

Build system for compiling libvips as a universal XCFramework for iOS, iOS Simulator, and Mac Catalyst.

## Overview

This project automates building libvips and all its dependencies for Apple platforms, producing a single `VIPSKit.xcframework` with an Objective-C wrapper for easy integration into Swift/Objective-C projects.

## Supported Platforms

| Platform | Architectures | SDK |
|----------|--------------|-----|
| iOS Device | arm64 | iphoneos |
| iOS Simulator | arm64, x86_64 | iphonesimulator |
| Mac Catalyst | arm64, x86_64 | macosx (with -macabi target) |

- **Minimum deployment target:** iOS 15.0

## Image Format Support

- JPEG (libjpeg-turbo with SIMD acceleration)
- PNG (libpng)
- WebP (libwebp)
- JPEG-XL (libjxl)
- AVIF (decode-only via dav1d + libheif)
- HEIF (libheif)
- GIF (built-in)

## Dependencies (Build Order)

### Tier 1 - No dependencies
1. **expat** (2.7.3) - XML parser
2. **libffi** (3.5.2) - Foreign function interface
3. **pcre2** (10.47) - Regular expressions
4. **libjpeg-turbo** (3.1.3) - JPEG codec with SIMD
5. **libpng** (1.6.54) - PNG codec
6. **brotli** (1.2.0) - Compression library
7. **highway** (1.3.0) - SIMD library

### Tier 2 - Depends on Tier 1
8. **glib** (2.87.1) - Core utility library (needs libffi, pcre2)
9. **libwebp** (1.6.0) - WebP codec
10. **dav1d** (1.5.1) - AV1 decoder

### Tier 3 - Depends on Tier 2
11. **libjxl** (0.11.1) - JPEG-XL codec (needs brotli, highway)
12. **libheif** (1.21.2) - HEIF/AVIF container (needs dav1d)

### Final
13. **libvips** (8.18.0) - Image processing library

## Project Structure

```
vips-cocoa/
├── CLAUDE.md                   # This file
├── build.sh                    # Main build orchestrator
├── Scripts/
│   ├── env.sh                  # Environment, paths, versions
│   ├── utils.sh                # Common build functions
│   ├── download-sources.sh     # Download all source tarballs
│   ├── build-expat.sh
│   ├── build-libffi.sh
│   ├── build-pcre2.sh
│   ├── build-libjpeg-turbo.sh
│   ├── build-libpng.sh
│   ├── build-brotli.sh
│   ├── build-highway.sh
│   ├── build-glib.sh
│   ├── build-libwebp.sh
│   ├── build-dav1d.sh
│   ├── build-libjxl.sh
│   ├── build-libheif.sh
│   ├── build-libvips.sh
│   ├── create-xcframework.sh   # Creates final xcframework
│   ├── cross-files/            # Meson cross-compilation files
│   │   ├── ios.ini
│   │   ├── ios-sim-arm64.ini
│   │   ├── ios-sim-x86_64.ini
│   │   ├── catalyst-arm64.ini
│   │   └── catalyst-x86_64.ini
│   └── toolchains/             # CMake toolchain files
│       └── ios.toolchain.cmake # From leetal/ios-cmake
├── Sources/                    # Project source code
│   ├── VIPSImage.h             # Public header
│   └── VIPSImage.m             # Implementation
├── Vendor/                     # Downloaded source archives
├── build/
│   ├── output/                 # Build artifacts (per lib/target)
│   └── staging/                # Installed libs (per lib/target)
└── VIPSKit.xcframework/        # Final output (after build)
```

## Building

### Prerequisites

- Xcode with command-line tools
- Homebrew packages: `brew install meson ninja cmake nasm glib`
  - `nasm` is required for dav1d assembly
  - `glib` provides glib-mkenums for building target glib

### Full Build

```bash
./build.sh
```

### Build Options

```bash
./build.sh --clean          # Clean all build artifacts first
./build.sh --skip-download  # Skip downloading sources (use existing)
./build.sh --jobs 8         # Set parallel job count
./build.sh -f               # Rebuild framework only (fast)
```

### Build Individual Libraries

```bash
./Scripts/build-libpng.sh   # Build just libpng
```

## Output

The build produces `VIPSKit.xcframework` in the project root:

```
VIPSKit.xcframework/
├── Info.plist
├── ios-arm64/
│   └── VIPSKit.framework/
│       ├── VIPSKit                 # Dynamic library
│       ├── Headers/VIPSKit.h       # VIPSImage public header
│       ├── Modules/module.modulemap
│       └── Info.plist
├── ios-arm64_x86_64-simulator/
│   └── VIPSKit.framework/
└── ios-arm64_x86_64-maccatalyst/
    └── VIPSKit.framework/
```

## Integration

1. Drag `VIPSKit.xcframework` into your Xcode project
2. Add to "Frameworks, Libraries, and Embedded Content"
3. Set "Embed" to "Embed & Sign"

### Swift Usage

```swift
import VIPSKit

// Initialize once at app start
try VIPSImage.initialize()

// Get image info without loading pixels (fast, low memory)
var width: Int = 0
var height: Int = 0
var format: VIPSImageFormat = .unknown
try VIPSImage.getImageInfo(atPath: path, width: &width, height: &height, format: &format)
print("Image is \(width)x\(height), format: \(format)")

// Load image from file (full load for processing)
let image = try VIPSImage(contentsOfFile: path)

// Load image from Data
let image = try VIPSImage(data: imageData)

// Get image properties
print("Size: \(image.width)x\(image.height)")
print("Bands: \(image.bands), hasAlpha: \(image.hasAlpha)")
print("Format: \(image.sourceFormat), loader: \(image.loaderName ?? "unknown")")

// Resize to fit (maintains aspect ratio) - high quality
let fitted = try image.resizeToFit(width: 200, height: 200)

// Resize by scale factor
let scaled = try image.resize(scale: 0.5)

// Resize to exact dimensions
let resized = try image.resize(toWidth: 400, height: 300)

// Crop region
let cropped = try image.crop(x: 10, y: 10, width: 100, height: 100)

// Rotate (90, 180, 270 degrees)
let rotated = try image.rotate(byDegrees: 90)

// Flip
let flippedH = try image.flipHorizontal()
let flippedV = try image.flipVertical()

// Auto-rotate based on EXIF
let oriented = try image.autoRotate()

// Smart crop - content-aware cropping that finds interesting regions
let smartCropped = try image.smartCrop(toWidth: 400, height: 400, interesting: .attention)
// Strategies: .attention (edges/skin/colors), .entropy, .centre, .low, .high

// Composite images (watermarks, overlays)
let watermarked = try baseImage.composite(withOverlay: watermark, mode: .over, x: 10, y: 10)
let centered = try baseImage.composite(withOverlay: logo, mode: .over)  // Centers overlay
// Blend modes: .over, .multiply, .screen, .overlay, .darken, .lighten, .add, etc.

// Color adjustments
let brighter = try image.adjustBrightness(0.2)       // -1.0 to 1.0
let highContrast = try image.adjustContrast(1.5)    // 0.5 to 2.0
let saturated = try image.adjustSaturation(1.3)     // 0 = grayscale, 1.0 = normal
let gammaCorrected = try image.adjustGamma(2.2)     // < 1 lightens, > 1 darkens
let inverted = try image.invert()

// Combined color adjustment (more efficient)
let adjusted = try image.adjust(brightness: 0.1, contrast: 1.2, saturation: 1.1)

// Edge detection
let edges = try image.sobel()                        // Fast edge detection
let cannyEdges = try image.canny(sigma: 1.4)        // Sophisticated edge detection

// Convert to grayscale
let gray = try image.grayscale()

// Flatten alpha against background
let flattened = try image.flatten(red: 255, green: 255, blue: 255)

// Apply blur
let blurred = try image.blur(sigma: 2.0)

// Sharpen
let sharpened = try image.sharpen(sigma: 1.0)

// Export to Data
let jpegData = try image.data(format: .jpeg, quality: 85)
let pngData = try image.data(format: .png, quality: 0)
let webpData = try image.data(format: .webP, quality: 80)
let heifData = try image.data(format: .heif, quality: 85)
let avifData = try image.data(format: .avif, quality: 80)
let jxlData = try image.data(format: .jxl, quality: 90)

// Save to file
try image.write(toFile: "/path/to/output.jpg")
try image.write(toFile: "/path/to/output.png", format: .png, quality: 0)

// Create CGImage directly (most efficient for display)
if let cgImage = try image.createCGImage() {
    let uiImage = UIImage(cgImage: cgImage)
    // Use the image...
    // CGImage is automatically released when cgImage goes out of scope
}

// BEST: Decode directly to thumbnail CGImage (minimal peak memory)
// This is the most memory-efficient path for batch thumbnail generation
if let cgImage = try VIPSImage.createThumbnail(fromFile: path, width: 200, height: 200) {
    let uiImage = UIImage(cgImage: cgImage)
    // Decode buffers already released - only thumbnail pixels in memory
}

// Process very large images (e.g., 500x30000) in strips
let stripHeight = 1000
let numStrips = image.numberOfStrips(withHeight: stripHeight)
for i in 0..<numStrips {
    let strip = try image.strip(atIndex: i, height: stripHeight)
    // Process each strip independently...
}

// Or extract a region directly from file (most memory efficient)
let region = try VIPSImage.extractRegion(fromFile: path, x: 0, y: 5000, width: 500, height: 1000)

// Get tile coordinates for splitting image into grid
let tiles = image.tileRects(withTileWidth: 256, tileHeight: 256)
for tileRect in tiles {
    let rect = tileRect.cgRectValue
    let tile = try image.crop(x: Int(rect.origin.x), y: Int(rect.origin.y),
                               width: Int(rect.width), height: Int(rect.height))
    // Process tile...
}

// Cache processed images (default: lossless WebP, ~30% smaller than PNG)
let cacheData = try thumbnail.cacheData()  // Lossless WebP
try thumbnail.writeToCache(file: "/path/to/cache/thumb")  // Auto-adds .webp

// Cache with explicit format control
let webpLossless = try thumbnail.cacheData(format: .webP, quality: 0, lossless: true)
let webpLossy = try thumbnail.cacheData(format: .webP, quality: 85, lossless: false)
let jxlLossless = try thumbnail.cacheData(format: .jxl, quality: 0, lossless: true)
let png = try thumbnail.cacheData(format: .png, quality: 0, lossless: true)  // PNG always lossless

// Write cache files with format control (auto-appends correct extension)
try thumbnail.writeToCache(file: "/path/to/cache/thumb", format: .webP, quality: 80, lossless: false)
try thumbnail.writeToCache(file: "/path/to/cache/thumb", format: .jxl, quality: 0, lossless: true)

// Memory management - break reference chain after resizing
let resized = try image.resizeToFit(width: 200, height: 200)
let copied = try resized.copyToMemory()  // Allows source to be freed
// Now 'image' can be released without keeping pixel data in memory

// Clear operation cache to free memory
VIPSImage.clearCache()

// Monitor memory usage
print("VIPS memory: \(VIPSImage.memoryUsage()) bytes")

// Disable caching entirely for memory-constrained environments
VIPSImage.setCacheMaxOperations(0)

// Cleanup at app termination (optional)
VIPSImage.shutdown()
```

### Objective-C Usage

```objc
@import VIPSKit;

// Initialize
NSError *error;
[VIPSImage initializeWithError:&error];

// Load image
VIPSImage *image = [VIPSImage imageWithContentsOfFile:path error:&error];
VIPSImage *image = [VIPSImage imageWithData:data error:&error];

// Properties
NSLog(@"Size: %ldx%ld", image.width, image.height);

// Process
VIPSImage *resized = [image resizeToFitWidth:200 height:200 error:&error];
VIPSImage *rotated = [image rotateByDegrees:90 error:&error];

// Smart crop - content-aware
VIPSImage *smartCropped = [image smartCropToWidth:400 height:400
                                      interesting:VIPSInterestingAttention error:&error];

// Composite (watermarks, overlays)
VIPSImage *watermarked = [baseImage compositeWithOverlay:watermark
                                                    mode:VIPSBlendModeOver
                                                       x:10 y:10 error:&error];

// Color adjustments
VIPSImage *brighter = [image adjustBrightness:0.2 error:&error];
VIPSImage *adjusted = [image adjustBrightness:0.1 contrast:1.2 saturation:1.1 error:&error];
VIPSImage *inverted = [image invertWithError:&error];

// Edge detection
VIPSImage *edges = [image sobelWithError:&error];
VIPSImage *cannyEdges = [image cannyWithSigma:1.4 error:&error];

// Export
NSData *jpegData = [image dataWithFormat:VIPSImageFormatJPEG quality:85 error:&error];
[image writeToFile:@"/path/to/output.jpg" error:&error];

// Create CGImage directly (most efficient for display)
CGImageRef cgImage = [image createCGImageWithError:&error];
if (cgImage) {
    UIImage *uiImage = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);  // Must release when done
}

// BEST: Decode directly to thumbnail CGImage (minimal peak memory)
CGImageRef thumbCG = [VIPSImage createThumbnailFromFile:path
                                                  width:200
                                                 height:200
                                                  error:&error];
if (thumbCG) {
    UIImage *thumbnail = [UIImage imageWithCGImage:thumbCG];
    CGImageRelease(thumbCG);
}

// Cache processed images (default: lossless WebP)
NSData *cacheData = [image cacheDataWithError:&error];
[image writeToCacheFile:@"/path/to/cache/thumb" error:&error];  // Auto-adds .webp

// Cache with explicit format control
NSData *webpData = [image cacheDataWithFormat:VIPSImageFormatWebP quality:85 lossless:NO error:&error];
NSData *jxlData = [image cacheDataWithFormat:VIPSImageFormatJXL quality:0 lossless:YES error:&error];
[image writeToCacheFile:@"/path/to/cache/thumb" format:VIPSImageFormatWebP quality:80 lossless:NO error:&error];

// Shutdown
[VIPSImage shutdown];
```

## API Reference

### VIPSImage Class

| Method | Description |
|--------|-------------|
| `+initialize` | Initialize libvips (call once at app start) |
| `+shutdown` | Cleanup libvips (optional, call at app termination) |
| `+getImageInfoAtPath:width:height:format:error:` | Get dimensions without loading pixels |
| `+imageWithContentsOfFile:error:` | Load image from file path |
| `+imageWithContentsOfFileSequential:error:` | Load with streaming (row-by-row) |
| `+thumbnailFromFile:width:height:error:` | Shrink-on-load thumbnail (low memory) |
| `+thumbnailFromData:width:height:error:` | Shrink-on-load thumbnail from NSData (low memory) |
| `+createThumbnailFromFile:width:height:error:` | Decode directly to CGImage (minimal memory) |
| `+imageWithData:error:` | Load image from NSData |
| `+imageWithBuffer:width:height:bands:error:` | Create from raw pixel buffer |
| `width`, `height`, `bands`, `hasAlpha` | Image dimensions and channels |
| `sourceFormat` | Detected source format (VIPSImageFormat enum) |
| `loaderName` | Raw loader name (e.g., "jpegload", "pngload") |
| `-writeToFile:error:` | Save to file (format from extension) |
| `-writeToFile:format:quality:error:` | Save with explicit format |
| `-dataWithFormat:quality:error:` | Export to NSData |
| `-createCGImageWithError:` | Create CGImage (most efficient for display) |
| `-resizeToFitWidth:height:error:` | Resize maintaining aspect ratio (high quality) |
| `-resizeWithScale:error:` | Scale by factor |
| `-resizeToWidth:height:error:` | Resize to exact dimensions |
| `-cropWithX:y:width:height:error:` | Crop region |
| `-rotateByDegrees:error:` | Rotate 90/180/270 degrees |
| `-flipHorizontalWithError:` | Mirror horizontally |
| `-flipVerticalWithError:` | Mirror vertically |
| `-autoRotateWithError:` | Apply EXIF orientation |
| `-smartCropToWidth:height:interesting:error:` | Content-aware smart crop |
| `-compositeWithOverlay:mode:x:y:error:` | Composite with blend mode at position |
| `-compositeWithOverlay:mode:error:` | Composite centered with blend mode |
| `-grayscaleWithError:` | Convert to grayscale |
| `-flattenWithRed:green:blue:error:` | Flatten alpha to background |
| `-invertWithError:` | Invert colors (negative) |
| `-adjustBrightness:error:` | Adjust brightness (-1.0 to 1.0) |
| `-adjustContrast:error:` | Adjust contrast (0.5 to 2.0) |
| `-adjustSaturation:error:` | Adjust saturation (0 to 2.0) |
| `-adjustGamma:error:` | Adjust gamma curve |
| `-adjustBrightness:contrast:saturation:error:` | Combined adjustment (efficient) |
| `-blurWithSigma:error:` | Gaussian blur |
| `-sharpenWithSigma:error:` | Sharpen |
| `-sobelWithError:` | Sobel edge detection |
| `-cannyWithSigma:error:` | Canny edge detection |
| `-copyToMemoryWithError:` | Copy pixels to memory, breaking lazy chain |
| `-tileRectsWithTileWidth:tileHeight:` | Calculate tile rects for dividing image |
| `-numberOfStripsWithHeight:` | Number of horizontal strips for given height |
| `-stripAtIndex:height:error:` | Extract horizontal strip by index |
| `+extractRegionFromFile:x:y:width:height:error:` | Extract region from file (memory efficient) |
| `+extractRegionFromData:x:y:width:height:error:` | Extract region from NSData (memory efficient) |
| `-cacheDataWithError:` | Export as lossless WebP for caching |
| `-cacheDataWithFormat:quality:lossless:error:` | Export with explicit format control |
| `-writeToCacheFile:error:` | Write lossless WebP cache file |
| `-writeToCacheFile:format:quality:lossless:error:` | Write cache file with format control |

### Memory Management (Class Methods)

| Method | Description |
|--------|-------------|
| `+clearCache` | Clear operation cache, free memory |
| `+setCacheMaxOperations:` | Set max cached operations (0 to disable) |
| `+setCacheMaxMemory:` | Set max cache memory in bytes |
| `+setCacheMaxFiles:` | Set max open files in cache |
| `+memoryUsage` | Current tracked memory in bytes |
| `+memoryHighWater` | Peak tracked memory in bytes |
| `+resetMemoryHighWater` | Reset peak memory tracking |
| `+setConcurrency:` | Set vips thread pool size (affects JXL, etc.) |
| `+concurrency` | Get current vips thread pool size |

### Image Formats

| Format | Constant | Notes |
|--------|----------|-------|
| Unknown | `VIPSImageFormatUnknown` | Format not detected (-1) |
| JPEG | `VIPSImageFormatJPEG` | Quality 1-100 |
| PNG | `VIPSImageFormatPNG` | Quality ignored |
| WebP | `VIPSImageFormatWebP` | Quality 1-100 |
| HEIF | `VIPSImageFormatHEIF` | Quality 1-100 |
| AVIF | `VIPSImageFormatAVIF` | Quality 1-100 |
| JPEG-XL | `VIPSImageFormatJXL` | Quality 1-100 |
| GIF | `VIPSImageFormatGIF` | Quality ignored |

### Resize Kernels

| Kernel | Constant | Use Case |
|--------|----------|----------|
| Nearest | `VIPSResizeKernelNearest` | Pixel art, fastest |
| Linear | `VIPSResizeKernelLinear` | Fast, acceptable quality |
| Cubic | `VIPSResizeKernelCubic` | Good quality |
| Lanczos2 | `VIPSResizeKernelLanczos2` | High quality |
| Lanczos3 | `VIPSResizeKernelLanczos3` | Best quality (default) |

### Smart Crop Strategies

| Strategy | Constant | Description |
|----------|----------|-------------|
| None | `VIPSInterestingNone` | Don't look for interesting areas |
| Centre | `VIPSInterestingCentre` | Crop from center |
| Entropy | `VIPSInterestingEntropy` | Maximize entropy (detail) |
| Attention | `VIPSInterestingAttention` | Detect edges, skin tones, saturated colors |
| Low | `VIPSInterestingLow` | Crop from low coordinate |
| High | `VIPSInterestingHigh` | Crop from high coordinate |

### Blend Modes

| Mode | Constant | Description |
|------|----------|-------------|
| Over | `VIPSBlendModeOver` | Standard alpha compositing (most common) |
| Multiply | `VIPSBlendModeMultiply` | Darken by multiplying colors |
| Screen | `VIPSBlendModeScreen` | Lighten (inverse of multiply) |
| Overlay | `VIPSBlendModeOverlay` | Multiply or screen based on base |
| Add | `VIPSBlendModeAdd` | Add colors together |
| Darken | `VIPSBlendModeDarken` | Keep darker pixels |
| Lighten | `VIPSBlendModeLighten` | Keep lighter pixels |
| Soft Light | `VIPSBlendModeSoftLight` | Subtle contrast adjustment |
| Hard Light | `VIPSBlendModeHardLight` | Strong contrast adjustment |
| Difference | `VIPSBlendModeDifference` | Absolute difference |
| Exclusion | `VIPSBlendModeExclusion` | Similar to difference, lower contrast |

## Architecture Notes

### Lazy Evaluation and Memory Management

libvips uses lazy evaluation - operations don't compute pixels until output is needed. This provides efficiency but has memory implications:

```
// Problem: source image stays in memory
let source = try VIPSImage(contentsOfFile: largeImage)  // ~50MB decoded
let thumb = try source.thumbnail(width: 200, height: 200)  // Creates pipeline
// Both source AND thumb data may be in memory due to reference chain
```

**Solutions:**

1. **Copy to memory** - breaks the reference chain:
```swift
let thumb = try source.thumbnail(width: 200, height: 200)
let copied = try thumb.copyToMemory()  // Forces evaluation, breaks chain
source = nil  // Now source can be fully freed
```

2. **Clear cache** after processing batches:
```swift
VIPSImage.clearCache()  // Frees cached operations
```

3. **Disable caching** for memory-constrained environments:
```swift
VIPSImage.setCacheMaxOperations(0)  // Disable operation cache
VIPSImage.setCacheMaxMemory(50 * 1024 * 1024)  // Or limit to 50MB
```

4. **Monitor memory**:
```swift
print("VIPS using: \(VIPSImage.memoryUsage() / 1024 / 1024)MB")
```

### Threading and Batch Processing

**Defaults are optimized for batch processing (set on initialize):**
- VIPS concurrency: 1 thread
- Operation cache: disabled (no memory held between operations)

```swift
// Just initialize - defaults are already optimal for batch processing
try VIPSImage.initialize()

// For thumbnails, use shrink-on-load (decodes at reduced resolution):
let thumb = try VIPSImage.thumbnail(fromFile: path, width: 200, height: 200)
// This is MUCH more memory efficient than loading full image then resizing

// Parallelize at your application layer:
DispatchQueue.concurrentPerform(iterations: images.count) { i in
    let thumb = try? VIPSImage.thumbnail(fromFile: images[i], width: 200, height: 200)
    // process...
}
```

**For single-image processing** (maximum speed for one large image):
```swift
VIPSImage.setConcurrency(0)  // Auto-detect (all cores)
```

**Memory optimization tips:**
- Use `thumbnailFromFile:` instead of loading then thumbnailing
- Use `createThumbnailFromFile:` for the most memory-efficient thumbnail-to-display path
- Release images promptly (set to nil)
- Use `copyToMemory` to break lazy reference chains
- Single-threaded default prevents per-thread buffer allocation

### Format-Specific Memory Characteristics

Different formats have different memory profiles when thumbnailing:

| Format | Shrink-on-Load | Peak Memory Notes |
|--------|---------------|-------------------|
| JPEG | Yes (8x, 4x, 2x) | Excellent - decodes directly at reduced resolution |
| PNG | No | Full decode required, then resize |
| WebP | Limited | Partial shrink-on-load support |
| AVIF | No | Full AV1 frame decode required |
| JXL | No | Full decode required (inherent to format) |
| HEIF | No | Full decode required |
| GIF | No | Full decode required |

**JPEG-XL Memory:** JXL does not support true shrink-on-load. Unlike JPEG which can decode DCT coefficients at reduced resolution, JXL's architecture requires decoding significant portions of the image regardless of target size. A 6000x3300 JXL will require ~500MB peak memory during decode even when thumbnailing. For memory-constrained batch processing of large JXL files, consider:
- Decoding one JXL at a time (don't parallelize JXL decodes)
- Using `createThumbnailFromFile:` to release decode buffers immediately after CGImage creation
- Storing source images in JPEG format if memory is critical

**AVIF Memory:** AVIF uses the dav1d AV1 decoder which allocates frame buffers. For a 4K AVIF, expect ~100-150MB peak during decode.

### CGImage Export (Zero-Copy Display)

The `createCGImage` method provides the most efficient path for displaying images:

```
VIPSImage → vips_image_write_to_memory → CGDataProvider → CGImage → UIImage
```

This avoids the encode/decode cycle that would occur with:
```
VIPSImage → JPEG/PNG encode → NSData → UIImage decode → CGImage (slower)
```

The pixel data is transferred directly from libvips memory to CoreGraphics with a single copy. The `CGDataProvider` release callback automatically frees the vips memory when the CGImage is deallocated.

### Why a Dynamic Framework with Wrapper?

1. **License compliance**: libvips is LGPL, requiring dynamic linking for proprietary apps
2. **Header complexity**: libvips depends on glib which has complex header structures that don't work well with Clang modules
3. **Clean API**: The Objective-C wrapper provides a simple, idiomatic API without exposing internal complexity

### Build Approach

1. All 13 dependencies are compiled as static libraries for each target architecture
2. The Objective-C wrapper (`VIPSImage.m`) is compiled against these static libraries
3. Everything is linked into a single dynamic library (`VIPSKit.framework/VIPSKit`)
4. Only `VIPSImage.h` is exposed as the public header
5. The framework is packaged as an xcframework for multi-platform distribution

### Cross-Compilation

- **CMake builds** use `Scripts/toolchains/ios.toolchain.cmake` from leetal/ios-cmake
- **Meson builds** use custom cross-files in `Scripts/cross-files/`
- **Autotools builds** use configure flags with appropriate CC/CFLAGS

### Target Identifiers

| Target ID | Description |
|-----------|-------------|
| `ios` | iOS Device arm64 |
| `ios-sim-arm64` | iOS Simulator arm64 |
| `ios-sim-x86_64` | iOS Simulator x86_64 |
| `catalyst-arm64` | Mac Catalyst arm64 |
| `catalyst-x86_64` | Mac Catalyst x86_64 |

## Troubleshooting

### Build fails with "glib-mkenums not found"
```bash
brew install glib
```

### Build fails with "nasm not found" (dav1d)
```bash
brew install nasm
```

### libjxl build fails with "Please run deps.sh"
The build script automatically runs `deps.sh` to fetch libjxl's third-party dependencies. If this fails, run manually:
```bash
cd Vendor/libjxl-*/
./deps.sh
```

### Undefined symbols for architecture
Check that all dependencies built successfully for the failing target. The build scripts create static libraries in `build/staging/<library>/<target>/lib/`.

### Framework not loading at runtime
Ensure "Embed & Sign" is selected in Xcode's "Frameworks, Libraries, and Embedded Content" section.

## Cleaning

```bash
./build.sh --clean              # Clean and rebuild
rm -rf build VIPSKit.xcframework   # Manual clean
```

## License

- libvips: LGPL-2.1
- Dependencies have various open-source licenses (MIT, BSD, etc.)
- This build system: MIT
