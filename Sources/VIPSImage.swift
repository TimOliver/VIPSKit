import Foundation
import CoreGraphics
internal import vips
internal import CVIPS

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Image processing wrapper for libvips.
public final class VIPSImage: @unchecked Sendable {

    /// The underlying VipsImage pointer.
    internal let pointer: UnsafeMutablePointer<VipsImage>

    // MARK: - Lifecycle

    /// Wrap an existing VipsImage pointer. Takes ownership (does NOT add a ref).
    internal init(pointer: UnsafeMutablePointer<VipsImage>) {
        self.pointer = pointer
    }

    /// Wrap an existing VipsImage pointer with an additional ref.
    internal init(borrowing pointer: UnsafeMutablePointer<VipsImage>) {
        g_object_ref(gpointer(pointer))
        self.pointer = pointer
    }

    deinit {
        g_object_unref(gpointer(pointer))
    }

    // MARK: - Initialization

    /// Initialize the VIPS library. Call once at app startup.
    public static func initialize() throws {
        if vips_init("VIPSKit") != 0 {
            throw VIPSError.fromVips()
        }
        vips_cache_set_max(100)
        vips_cache_set_max_mem(50 * 1024 * 1024) // 50MB
        vips_cache_set_max_files(10)
        vips_concurrency_set(1)
    }

    /// Shutdown the VIPS library. Call at app termination.
    public static func shutdown() {
        vips_shutdown()
    }

    // MARK: - Properties

    /// Width of the image in pixels.
    public var width: Int { Int(vips_image_get_width(pointer)) }

    /// Height of the image in pixels.
    public var height: Int { Int(vips_image_get_height(pointer)) }

    /// Number of bands (channels) in the image.
    public var bands: Int { Int(vips_image_get_bands(pointer)) }

    /// Whether the image has an alpha channel.
    public var hasAlpha: Bool { vips_image_hasalpha(pointer) != 0 }

    /// Loader name used to load the image (e.g., "jpegload", "pngload").
    public var loaderName: String? {
        var loader: UnsafePointer<CChar>?
        guard vips_image_get_string(pointer, VIPS_META_LOADER, &loader) == 0,
              let loader else { return nil }
        return String(cString: loader)
    }

    /// Detected source format of the image.
    public var sourceFormat: VIPSImageFormat {
        guard let loader = loaderName else { return .unknown }
        if loader.hasPrefix("jpeg") || loader.hasPrefix("jpg") {
            return .jpeg
        } else if loader.hasPrefix("png") {
            return .png
        } else if loader.hasPrefix("webp") {
            return .webP
        } else if loader.hasPrefix("heif") {
            var compression: UnsafePointer<CChar>?
            if vips_image_get_string(pointer, "heif-compression", &compression) == 0,
               let compression, strcmp(compression, "av1") == 0 {
                return .avif
            }
            return .heif
        } else if loader.hasPrefix("jxl") {
            return .jxl
        } else if loader.hasPrefix("gif") {
            return .gif
        }
        return .unknown
    }

    // MARK: - Class Memory Management

    /// Clear all cached operations and free associated memory.
    public static func clearCache() {
        let originalMax = vips_cache_get_max()
        vips_cache_set_max(0)
        vips_cache_set_max(originalMax)
    }

    /// Set maximum number of operations to cache.
    public static func setCacheMaxOperations(_ max: Int) {
        vips_cache_set_max(Int32(max))
    }

    /// Set maximum memory used by operation cache in bytes.
    public static func setCacheMaxMemory(_ bytes: Int) {
        vips_cache_set_max_mem(bytes)
    }

    /// Set maximum number of open files in cache.
    public static func setCacheMaxFiles(_ max: Int) {
        vips_cache_set_max_files(Int32(max))
    }

    /// Current memory usage tracked by VIPS in bytes.
    public static var memoryUsage: Int { Int(vips_tracked_get_mem()) }

    /// Peak memory usage tracked by VIPS in bytes.
    public static var memoryHighWater: Int { Int(vips_tracked_get_mem_highwater()) }

    /// Reset peak memory tracking.
    public static func resetMemoryHighWater() {
        _ = vips_tracked_get_mem_highwater()
    }

    /// Set the number of threads used by VIPS for processing.
    public static func setConcurrency(_ threads: Int) {
        vips_concurrency_set(Int32(threads))
    }

    /// Get the current VIPS concurrency setting.
    public static var concurrency: Int { Int(vips_concurrency_get()) }

    // MARK: - Instance Memory Management

    /// Copy image pixels to memory, breaking lazy evaluation chain.
    public func copyToMemory() throws -> VIPSImage {
        guard let out = vips_image_copy_memory(pointer) else {
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: out)
    }

    // MARK: - Pixel Access

    /// Access raw pixel data with zero-copy block-based API.
    /// Data is 8-bit per channel in RGB or RGBA format. Only valid within the closure.
    public func withPixelData<T>(_ body: (UnsafePointer<UInt8>, Int, Int, Int, Int) throws -> T) throws -> T {
        var prepared: UnsafeMutablePointer<VipsImage>

        let interpretation = vips_image_get_interpretation(pointer)
        if interpretation != VIPS_INTERPRETATION_sRGB &&
           interpretation != VIPS_INTERPRETATION_RGB &&
           interpretation != VIPS_INTERPRETATION_B_W {
            var srgb: UnsafeMutablePointer<VipsImage>?
            guard cvips_colourspace(pointer, &srgb, VIPS_INTERPRETATION_sRGB) == 0,
                  let srgb else { throw VIPSError.fromVips() }
            prepared = srgb
        } else {
            g_object_ref(gpointer(pointer))
            prepared = pointer
        }

        if vips_image_get_format(prepared) != VIPS_FORMAT_UCHAR {
            var cast: UnsafeMutablePointer<VipsImage>?
            guard cvips_cast_uchar(prepared, &cast) == 0, let cast else {
                g_object_unref(gpointer(prepared))
                throw VIPSError.fromVips()
            }
            g_object_unref(gpointer(prepared))
            prepared = cast
        }

        let w = Int(vips_image_get_width(prepared))
        let h = Int(vips_image_get_height(prepared))
        let b = Int(vips_image_get_bands(prepared))
        let bytesPerRow = w * b

        var dataSize: Int = 0
        guard let data = vips_image_write_to_memory(prepared, &dataSize) else {
            g_object_unref(gpointer(prepared))
            throw VIPSError.fromVips()
        }
        g_object_unref(gpointer(prepared))

        defer { g_free(data) }
        return try body(data.assumingMemoryBound(to: UInt8.self), w, h, bytesPerRow, b)
    }

    // MARK: - Analysis

    /// Find the bounding box of non-background pixels (trim margins).
    public func findTrim(threshold: Double = 10.0, background: [Double]? = nil) throws -> CGRect {
        var left: Int32 = 0, top: Int32 = 0, width: Int32 = 0, height: Int32 = 0
        let result: Int32

        if var bg = background, !bg.isEmpty {
            result = cvips_find_trim_bg(pointer, &left, &top, &width, &height,
                                        threshold, &bg, Int32(bg.count))
        } else {
            result = cvips_find_trim(pointer, &left, &top, &width, &height, threshold)
        }

        guard result == 0 else { throw VIPSError.fromVips() }
        return CGRect(x: Int(left), y: Int(top), width: Int(width), height: Int(height))
    }

    /// Get image statistics (min, max, mean, standard deviation).
    public func statistics() throws -> VIPSImageStatistics {
        var min: Double = 0, max: Double = 0, mean: Double = 0, stddev: Double = 0
        guard cvips_min(pointer, &min) == 0 else { throw VIPSError.fromVips() }
        guard cvips_max(pointer, &max) == 0 else { throw VIPSError.fromVips() }
        guard cvips_avg(pointer, &mean) == 0 else { throw VIPSError.fromVips() }
        guard cvips_deviate(pointer, &stddev) == 0 else { throw VIPSError.fromVips() }
        return VIPSImageStatistics(min: min, max: max, mean: mean, standardDeviation: stddev)
    }

    /// Get the average color of the image as per-band mean values.
    public func averageColor() throws -> [Double] {
        var statsImage: UnsafeMutablePointer<VipsImage>?
        guard cvips_stats(pointer, &statsImage) == 0, let statsImage else {
            throw VIPSError.fromVips()
        }
        defer { g_object_unref(gpointer(statsImage)) }

        let numBands = Int(vips_image_get_bands(pointer))
        guard let pixel = vips_image_get_data(statsImage) else {
            throw VIPSError("Failed to read stats data")
        }

        let data = pixel.assumingMemoryBound(to: Double.self)
        let statsWidth = numBands + 1
        var result: [Double] = []
        for band in 1...numBands {
            result.append(data[4 * statsWidth + band])
        }
        return result
    }

    /// Detect the background color by sampling edges.
    public func detectBackgroundColor(stripWidth: Int = 10) throws -> [Double] {
        let w = width
        let h = height
        let sw = max(1, stripWidth)

        if w <= sw * 2 || h <= sw * 2 {
            return try averageColor()
        }

        var topStrip: UnsafeMutablePointer<VipsImage>?
        guard cvips_crop(pointer, &topStrip, 0, 0, Int32(w), Int32(sw)) == 0,
              let topStrip else { throw VIPSError.fromVips() }

        var bottomStrip: UnsafeMutablePointer<VipsImage>?
        guard cvips_crop(pointer, &bottomStrip, 0, Int32(h - sw), Int32(w), Int32(sw)) == 0,
              let bottomStrip else {
            g_object_unref(gpointer(topStrip))
            throw VIPSError.fromVips()
        }

        var leftStrip: UnsafeMutablePointer<VipsImage>?
        guard cvips_crop(pointer, &leftStrip, 0, Int32(sw), Int32(sw), Int32(h - 2 * sw)) == 0,
              let leftStrip else {
            g_object_unref(gpointer(topStrip)); g_object_unref(gpointer(bottomStrip))
            throw VIPSError.fromVips()
        }

        var rightStrip: UnsafeMutablePointer<VipsImage>?
        guard cvips_crop(pointer, &rightStrip, Int32(w - sw), Int32(sw), Int32(sw), Int32(h - 2 * sw)) == 0,
              let rightStrip else {
            g_object_unref(gpointer(topStrip)); g_object_unref(gpointer(bottomStrip)); g_object_unref(gpointer(leftStrip))
            throw VIPSError.fromVips()
        }

        var horizontal: UnsafeMutablePointer<VipsImage>?
        guard cvips_join(topStrip, bottomStrip, &horizontal, VIPS_DIRECTION_VERTICAL) == 0,
              let horizontal else {
            g_object_unref(gpointer(topStrip)); g_object_unref(gpointer(bottomStrip))
            g_object_unref(gpointer(leftStrip)); g_object_unref(gpointer(rightStrip))
            throw VIPSError.fromVips()
        }
        g_object_unref(gpointer(topStrip)); g_object_unref(gpointer(bottomStrip))

        var vertical: UnsafeMutablePointer<VipsImage>?
        guard cvips_join(leftStrip, rightStrip, &vertical, VIPS_DIRECTION_VERTICAL) == 0,
              let vertical else {
            g_object_unref(gpointer(horizontal)); g_object_unref(gpointer(leftStrip)); g_object_unref(gpointer(rightStrip))
            throw VIPSError.fromVips()
        }
        g_object_unref(gpointer(leftStrip)); g_object_unref(gpointer(rightStrip))

        var combined: UnsafeMutablePointer<VipsImage>?
        guard cvips_join(horizontal, vertical, &combined, VIPS_DIRECTION_VERTICAL) == 0,
              let combined else {
            g_object_unref(gpointer(horizontal)); g_object_unref(gpointer(vertical))
            throw VIPSError.fromVips()
        }
        g_object_unref(gpointer(horizontal)); g_object_unref(gpointer(vertical))

        let wrapper = VIPSImage(pointer: combined)
        return try wrapper.averageColor()
    }

    // MARK: - Arithmetic

    /// Subtract another image from this image (pixel-wise: self - other).
    public func subtract(_ other: VIPSImage) throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_subtract(pointer, other.pointer, &out) == 0, let out else {
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: out)
    }

    /// Compute absolute value of each pixel.
    public func absolute() throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_abs(pointer, &out) == 0, let out else {
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: out)
    }
}

// MARK: - Debugger Quick Look

extension VIPSImage {
    @objc func debugQuickLookObject() -> Any? {
        guard let cgImage = try? self.createCGImage() else {
            return "VIPSImage(\(width)x\(height), \(bands) bands)"
        }
        #if canImport(UIKit)
        return UIImage(cgImage: cgImage)
        #elseif canImport(AppKit)
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        #else
        return "VIPSImage(\(width)x\(height), \(bands) bands)"
        #endif
    }
}
