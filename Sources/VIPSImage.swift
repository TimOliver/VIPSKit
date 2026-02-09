import Foundation
import CoreGraphics
internal import vips
internal import CVIPS

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A high-performance image processing class powered by libvips.
///
/// `VIPSImage` wraps the libvips C library to provide fast, memory-efficient image
/// operations suitable for batch processing and thumbnail generation. Each instance
/// represents an immutable image — all operations return new `VIPSImage` instances.
///
/// You must call ``initialize()`` once before using any other VIPSKit functionality.
///
/// ```swift
/// try VIPSImage.initialize()
/// let image = try VIPSImage(contentsOfFile: "/path/to/photo.jpg")
/// let thumbnail = try image.resizeToFit(width: 200, height: 200)
/// let cgImage = try thumbnail.createCGImage()
/// ```
public final class VIPSImage: @unchecked Sendable {

    /// The underlying libvips image pointer.
    internal let pointer: UnsafeMutablePointer<VipsImage>

    // MARK: - Lifecycle

    /// Wrap an existing VipsImage pointer, taking ownership of the reference.
    /// The caller must not release the pointer after passing it to this initializer.
    /// - Parameter pointer: A VipsImage pointer to take ownership of
    internal init(pointer: UnsafeMutablePointer<VipsImage>) {
        self.pointer = pointer
    }

    /// Wrap an existing VipsImage pointer by adding a new reference.
    /// The caller retains their own reference and must release it independently.
    /// - Parameter pointer: A VipsImage pointer to borrow
    internal init(borrowing pointer: UnsafeMutablePointer<VipsImage>) {
        g_object_ref(gpointer(pointer))
        self.pointer = pointer
    }

    deinit {
        g_object_unref(gpointer(pointer))
    }

    // MARK: - Initialization

    /// Initialize the libvips library. This must be called once before
    /// performing any image operations.
    ///
    /// Configures default cache and concurrency settings optimized for batch processing:
    /// - Operation cache: 100 operations, 50MB, 10 open files
    /// - Concurrency: 1 thread (parallelize at the application layer instead)
    public static func initialize() throws {
        if vips_init("VIPSKit") != 0 {
            throw VIPSError.fromVips()
        }
        vips_cache_set_max(100)
        vips_cache_set_max_mem(50 * 1024 * 1024) // 50MB
        vips_cache_set_max_files(10)
        vips_concurrency_set(1)
    }

    /// Shut down the libvips library and release all associated resources.
    /// Call this at application termination if desired. Optional.
    public static func shutdown() {
        vips_shutdown()
    }

    // MARK: - Properties

    /// The width of the image in pixels.
    public var width: Int { Int(vips_image_get_width(pointer)) }

    /// The height of the image in pixels.
    public var height: Int { Int(vips_image_get_height(pointer)) }

    /// The number of bands (channels) in the image. For example, 3 for RGB and 4 for RGBA.
    public var bands: Int { Int(vips_image_get_bands(pointer)) }

    /// Whether the image contains an alpha transparency channel.
    public var hasAlpha: Bool { vips_image_hasalpha(pointer) != 0 }

    /// The internal loader name used by libvips when this image was loaded
    /// (e.g., `"jpegload"`, `"pngload"`), or `nil` if the image was not loaded from a file or buffer.
    public var loaderName: String? {
        var loader: UnsafePointer<CChar>?
        guard vips_image_get_string(pointer, VIPS_META_LOADER, &loader) == 0,
              let loader else { return nil }
        return String(cString: loader)
    }

    /// The detected source format of the image based on the loader used.
    /// Returns ``VIPSImageFormat/unknown`` if the format could not be determined.
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
    /// Uses a safe workaround that avoids the `vips_cache_drop_all()` crash.
    public static func clearCache() {
        let originalMax = vips_cache_get_max()
        vips_cache_set_max(0)
        vips_cache_set_max(originalMax)
    }

    /// Set the maximum number of operations to keep in the cache.
    /// Set to 0 to disable caching entirely.
    /// - Parameter max: The maximum number of cached operations
    public static func setCacheMaxOperations(_ max: Int) {
        vips_cache_set_max(Int32(max))
    }

    /// Set the maximum amount of memory used by the operation cache.
    /// - Parameter bytes: The maximum cache memory in bytes
    public static func setCacheMaxMemory(_ bytes: Int) {
        vips_cache_set_max_mem(bytes)
    }

    /// Set the maximum number of open files held by the cache.
    /// - Parameter max: The maximum number of open files
    public static func setCacheMaxFiles(_ max: Int) {
        vips_cache_set_max_files(Int32(max))
    }

    /// The current memory usage tracked by libvips in bytes.
    public static var memoryUsage: Int { Int(vips_tracked_get_mem()) }

    /// The peak memory usage tracked by libvips since the last reset, in bytes.
    public static var memoryHighWater: Int { Int(vips_tracked_get_mem_highwater()) }

    /// Reset the peak memory tracking counter back to the current usage level.
    public static func resetMemoryHighWater() {
        _ = vips_tracked_get_mem_highwater()
    }

    /// Set the number of worker threads used by libvips for internal parallelism.
    /// Set to 0 to auto-detect based on available CPU cores.
    /// - Parameter threads: The number of threads to use
    public static func setConcurrency(_ threads: Int) {
        vips_concurrency_set(Int32(threads))
    }

    /// The current number of worker threads used by libvips.
    public static var concurrency: Int { Int(vips_concurrency_get()) }

    // MARK: - Instance Memory Management

    /// Copy the image pixels into a new contiguous memory block, breaking
    /// any lazy evaluation chain. This allows source images to be freed
    /// even if downstream images still exist.
    /// - Returns: A new image with all pixels evaluated and stored in memory
    public func copyToMemory() throws -> VIPSImage {
        guard let out = vips_image_copy_memory(pointer) else {
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: out)
    }

    // MARK: - Pixel Access

    /// Provides zero-copy access to the image's raw pixel data within a closure.
    ///
    /// The pixel data is converted to 8-bit unsigned sRGB format before being passed
    /// to the closure. The data pointer is only valid within the closure's scope.
    ///
    /// - Parameter body: A closure that receives the pixel data and image dimensions.
    ///   The closure parameters are:
    ///   1. `data` — A pointer to the raw pixel bytes
    ///   2. `width` — The image width in pixels
    ///   3. `height` — The image height in pixels
    ///   4. `bytesPerRow` — The number of bytes per row (stride)
    ///   5. `bands` — The number of bands (3 for RGB, 4 for RGBA)
    /// - Returns: The value returned by the closure
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
