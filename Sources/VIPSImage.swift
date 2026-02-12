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
/// let cgImage = try thumbnail.cgImage
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
        } else if loader.hasPrefix("tiff") {
            return .tiff
        }
        return .unknown
    }

    // MARK: - Cache

    /// Controls for the libvips operation cache.
    public struct Cache {
        /// The maximum number of operations to keep in the cache.
        /// Set to 0 to disable caching entirely.
        public static var maxOperations: Int {
            get { Int(vips_cache_get_max()) }
            set { vips_cache_set_max(Int32(newValue)) }
        }

        /// The maximum amount of memory used by the operation cache, in bytes.
        public static var maxMemory: Int {
            get { vips_cache_get_max_mem() }
            set { vips_cache_set_max_mem(newValue) }
        }

        /// The maximum number of open files held by the cache.
        public static var maxFiles: Int {
            get { Int(vips_cache_get_max_files()) }
            set { vips_cache_set_max_files(Int32(newValue)) }
        }

        /// Clear all cached operations and free associated memory.
        /// Uses a safe workaround that avoids the `vips_cache_drop_all()` crash.
        public static func clear() {
            let originalMax = vips_cache_get_max()
            vips_cache_set_max(0)
            vips_cache_set_max(originalMax)
        }
    }

    /// The current memory usage tracked by libvips in bytes.
    public static var memoryUsage: Int { Int(vips_tracked_get_mem()) }

    /// The peak memory usage tracked by libvips since the last reset, in bytes.
    public static var memoryHighWater: Int { Int(vips_tracked_get_mem_highwater()) }

    /// Reset the peak memory tracking counter back to the current usage level.
    public static func resetMemoryHighWater() {
        _ = vips_tracked_get_mem_highwater()
    }

    /// The number of worker threads used by libvips for internal parallelism.
    /// Set to 0 to auto-detect based on available CPU cores.
    public static var concurrency: Int {
        get { Int(vips_concurrency_get()) }
        set { vips_concurrency_set(Int32(newValue)) }
    }

    // MARK: - Instance Memory Management

    /// Copy the image pixels into a new contiguous memory block, breaking
    /// any lazy evaluation chain. This allows source images to be freed
    /// even if downstream images still exist.
    /// - Returns: A new image with all pixels evaluated and stored in memory
    public func copiedToMemory() throws -> VIPSImage {
        guard let out = vips_image_copy_memory(pointer) else {
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: out)
    }

    // MARK: - Pixel Access

    /// A snapshot of raw pixel data, valid only within the `withPixelData` closure.
    public struct PixelBuffer {
        /// A pointer to the raw pixel bytes.
        public let data: UnsafePointer<UInt8>
        /// The image width in pixels.
        public let width: Int
        /// The image height in pixels.
        public let height: Int
        /// The number of bytes per row (stride).
        public let bytesPerRow: Int
        /// The number of bands (3 for RGB, 4 for RGBA).
        public let bands: Int
    }

    /// Provides zero-copy access to the image's raw pixel data within a closure.
    ///
    /// The pixel data is converted to 8-bit unsigned sRGB format before being passed
    /// to the closure. The ``PixelBuffer`` is only valid within the closure's scope.
    ///
    /// - Parameter body: A closure that receives a ``PixelBuffer`` with the pixel data
    /// - Returns: The value returned by the closure
    public func withPixelData<T>(_ body: (PixelBuffer) throws -> T) throws -> T {
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
        let buffer = PixelBuffer(data: data.assumingMemoryBound(to: UInt8.self),
                                 width: w, height: h, bytesPerRow: bytesPerRow, bands: b)
        return try body(buffer)
    }

}

// MARK: - Debug Description

extension VIPSImage: CustomDebugStringConvertible {

    public var debugDescription: String {
        var lines: [String] = []
        lines.append("VIPSImage: \(width)x\(height) pixels, \(bands) band\(bands == 1 ? "" : "s")\(hasAlpha ? " (with alpha)" : "")")

        // Source format and loader
        let format = sourceFormat
        if format != .unknown {
            lines.append("  Format: \(format.debugLabel)\(loaderName.map { " (loader: \($0))" } ?? "")")
        } else if let loader = loaderName {
            lines.append("  Loader: \(loader)")
        }

        // Pixel format and interpretation
        let interp = vips_image_get_interpretation(pointer)
        let bandFmt = vips_image_get_format(pointer)
        lines.append("  Interpretation: \(Self.interpretationLabel(interp))")
        lines.append("  Band format: \(Self.bandFormatLabel(bandFmt))")

        // Resolution (only if non-default)
        let xres = xResolution
        let yres = yResolution
        if xres > 0 || yres > 0 {
            let dpiX = xres * 25.4
            let dpiY = yres * 25.4
            if abs(dpiX - dpiY) < 0.01 {
                lines.append("  Resolution: \(String(format: "%.1f", dpiX)) DPI")
            } else {
                lines.append("  Resolution: \(String(format: "%.1f", dpiX)) x \(String(format: "%.1f", dpiY)) DPI")
            }
        }

        // Orientation
        if let orient = orientation, orient != 1 {
            lines.append("  Orientation: \(orient) (\(Self.orientationLabel(orient)))")
        }

        // Multi-page
        let pages = pageCount
        if pages > 1 {
            lines.append("  Pages: \(pages)\(pageHeight.map { ", page height: \($0)px" } ?? "")")
        }

        // Embedded data
        var embeds: [String] = []
        if exifData != nil { embeds.append("EXIF") }
        if xmpData != nil { embeds.append("XMP") }
        if iccProfile != nil { embeds.append("ICC") }
        if !embeds.isEmpty {
            lines.append("  Embedded data: \(embeds.joined(separator: ", "))")
        }

        // Memory
        let estimatedBytes = width * height * bands * Self.bytesPerBand(bandFmt)
        lines.append("  Estimated size: \(Self.formatBytes(estimatedBytes))")

        return lines.joined(separator: "\n")
    }

    // MARK: - Debug Label Helpers

    private static func interpretationLabel(_ interp: VipsInterpretation) -> String {
        switch interp {
        case VIPS_INTERPRETATION_sRGB:       return "sRGB"
        case VIPS_INTERPRETATION_RGB:        return "RGB (linear)"
        case VIPS_INTERPRETATION_RGB16:      return "RGB16"
        case VIPS_INTERPRETATION_B_W:        return "Grayscale"
        case VIPS_INTERPRETATION_GREY16:     return "Grayscale 16-bit"
        case VIPS_INTERPRETATION_CMYK:       return "CMYK"
        case VIPS_INTERPRETATION_LAB:        return "CIE Lab"
        case VIPS_INTERPRETATION_LABS:       return "CIE LabS"
        case VIPS_INTERPRETATION_LCH:        return "CIE LCh"
        case VIPS_INTERPRETATION_XYZ:        return "CIE XYZ"
        case VIPS_INTERPRETATION_scRGB:      return "scRGB (linear)"
        case VIPS_INTERPRETATION_HSV:        return "HSV"
        case VIPS_INTERPRETATION_MULTIBAND:  return "Multiband"
        case VIPS_INTERPRETATION_FOURIER:    return "Fourier"
        case VIPS_INTERPRETATION_MATRIX:     return "Matrix"
        default:                             return "Unknown (\(interp.rawValue))"
        }
    }

    private static func bandFormatLabel(_ fmt: VipsBandFormat) -> String {
        switch fmt {
        case VIPS_FORMAT_UCHAR:    return "8-bit unsigned"
        case VIPS_FORMAT_CHAR:     return "8-bit signed"
        case VIPS_FORMAT_USHORT:   return "16-bit unsigned"
        case VIPS_FORMAT_SHORT:    return "16-bit signed"
        case VIPS_FORMAT_UINT:     return "32-bit unsigned"
        case VIPS_FORMAT_INT:      return "32-bit signed"
        case VIPS_FORMAT_FLOAT:    return "32-bit float"
        case VIPS_FORMAT_DOUBLE:   return "64-bit float"
        case VIPS_FORMAT_COMPLEX:  return "64-bit complex"
        case VIPS_FORMAT_DPCOMPLEX: return "128-bit complex"
        default:                   return "Unknown (\(fmt.rawValue))"
        }
    }

    private static func orientationLabel(_ value: Int) -> String {
        switch value {
        case 1: return "normal"
        case 2: return "flipped horizontal"
        case 3: return "rotated 180°"
        case 4: return "flipped vertical"
        case 5: return "transposed"
        case 6: return "rotated 90° CW"
        case 7: return "transverse"
        case 8: return "rotated 270° CW"
        default: return "unknown"
        }
    }

    private static func bytesPerBand(_ fmt: VipsBandFormat) -> Int {
        switch fmt {
        case VIPS_FORMAT_UCHAR, VIPS_FORMAT_CHAR: return 1
        case VIPS_FORMAT_USHORT, VIPS_FORMAT_SHORT: return 2
        case VIPS_FORMAT_UINT, VIPS_FORMAT_INT, VIPS_FORMAT_FLOAT: return 4
        case VIPS_FORMAT_DOUBLE, VIPS_FORMAT_COMPLEX: return 8
        case VIPS_FORMAT_DPCOMPLEX: return 16
        default: return 1
        }
    }

    private static func formatBytes(_ bytes: Int) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        let kb = Double(bytes) / 1024
        if kb < 1024 { return String(format: "%.1f KB", kb) }
        let mb = kb / 1024
        if mb < 1024 { return String(format: "%.1f MB", mb) }
        let gb = mb / 1024
        return String(format: "%.2f GB", gb)
    }
}

// MARK: - Debugger Quick Look

extension VIPSImage {
    @objc func debugQuickLookObject() -> Any? {
        guard let cgImage = try? self.cgImage else {
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
