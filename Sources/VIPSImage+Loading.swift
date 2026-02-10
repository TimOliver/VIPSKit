import Foundation
import CoreGraphics
internal import vips
internal import CVIPS

extension VIPSImage {

    // MARK: - Image Info

    /// Get the dimensions and format of an image file without decoding its pixels.
    /// This is a fast, low-memory operation suitable for preflight checks.
    /// - Parameter path: The file path of the image to inspect
    /// - Returns: A tuple containing the image width, height, and detected format
    public static func imageInfo(atPath path: String) throws -> (width: Int, height: Int, format: VIPSImageFormat) {
        guard let image = cvips_image_new_from_file_sequential(path) else {
            throw VIPSError.fromVips()
        }
        defer { g_object_unref(gpointer(image)) }

        let w = Int(vips_image_get_width(image))
        let h = Int(vips_image_get_height(image))

        var format: VIPSImageFormat = .unknown
        var loader: UnsafePointer<CChar>?
        if vips_image_get_string(image, VIPS_META_LOADER, &loader) == 0, let loader {
            let name = String(cString: loader)
            if name.hasPrefix("jpeg") || name.hasPrefix("jpg") {
                format = .jpeg
            } else if name.hasPrefix("png") {
                format = .png
            } else if name.hasPrefix("webp") {
                format = .webP
            } else if name.hasPrefix("heif") {
                var compression: UnsafePointer<CChar>?
                if vips_image_get_string(image, "heif-compression", &compression) == 0,
                   let compression, strcmp(compression, "av1") == 0 {
                    format = .avif
                } else {
                    format = .heif
                }
            } else if name.hasPrefix("jxl") {
                format = .jxl
            } else if name.hasPrefix("gif") {
                format = .gif
            } else if name.hasPrefix("tiff") {
                format = .tiff
            }
        }

        return (w, h, format)
    }

    // MARK: - File Loading

    /// Load an image from a file path, fully decoding it into memory.
    /// - Parameter path: The file path of the image to load
    public convenience init(contentsOfFile path: String) throws {
        guard let image = cvips_image_new_from_file(path) else {
            throw VIPSError.fromVips()
        }
        self.init(pointer: image)
    }

    /// Load an image with sequential (streaming) access, reading pixels row-by-row.
    /// This uses less memory than random access but only supports top-to-bottom reading.
    /// - Parameter path: The file path of the image to load
    public convenience init(contentsOfFileSequential path: String) throws {
        guard let image = cvips_image_new_from_file_sequential(path) else {
            throw VIPSError.fromVips()
        }
        self.init(pointer: image)
    }

    /// Create a thumbnail from a file using shrink-on-load, which decodes
    /// the image at a reduced resolution for minimal memory usage. The result
    /// fits within the specified dimensions while maintaining aspect ratio.
    /// - Parameters:
    ///   - path: The file path of the source image
    ///   - width: The maximum width of the thumbnail
    ///   - height: The maximum height of the thumbnail
    /// - Returns: A new thumbnail image that fits within the specified dimensions
    public static func thumbnail(fromFile path: String, width: Int, height: Int) throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_thumbnail(path, &out, Int32(width), Int32(height)) == 0, let out else {
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: out)
    }

    /// Create a thumbnail from in-memory data using shrink-on-load, which decodes
    /// the image at a reduced resolution for minimal memory usage. The result
    /// fits within the specified dimensions while maintaining aspect ratio.
    /// - Parameters:
    ///   - data: The encoded image data
    ///   - width: The maximum width of the thumbnail
    ///   - height: The maximum height of the thumbnail
    /// - Returns: A new thumbnail image that fits within the specified dimensions
    public static func thumbnail(fromData data: Data, width: Int, height: Int) throws -> VIPSImage {
        try data.withUnsafeBytes { buffer in
            var out: UnsafeMutablePointer<VipsImage>?
            guard cvips_thumbnail_buffer(buffer.baseAddress, buffer.count, &out, Int32(width), Int32(height)) == 0,
                  let out else {
                throw VIPSError.fromVips()
            }
            return VIPSImage(pointer: out)
        }
    }

    /// Create a thumbnail from a file using shrink-on-load.
    /// - Parameters:
    ///   - path: The file path of the source image
    ///   - size: The maximum size of the thumbnail
    /// - Returns: A new thumbnail image that fits within the specified size
    public static func thumbnail(fromFile path: String, size: CGSize) throws -> VIPSImage {
        try thumbnail(fromFile: path, width: Int(size.width), height: Int(size.height))
    }

    /// Create a thumbnail from in-memory data using shrink-on-load.
    /// - Parameters:
    ///   - data: The encoded image data
    ///   - size: The maximum size of the thumbnail
    /// - Returns: A new thumbnail image that fits within the specified size
    public static func thumbnail(fromData data: Data, size: CGSize) throws -> VIPSImage {
        try thumbnail(fromData: data, width: Int(size.width), height: Int(size.height))
    }

    // MARK: - Data Loading

    /// Load an image from encoded data (JPEG, PNG, WebP, etc.).
    /// The format is detected automatically from the data contents.
    /// - Parameter data: The encoded image data
    public convenience init(data: Data) throws {
        let image: UnsafeMutablePointer<VipsImage>? = data.withUnsafeBytes { buffer in
            cvips_image_new_from_buffer(buffer.baseAddress, buffer.count)
        }
        guard let image else { throw VIPSError.fromVips() }
        self.init(pointer: image)
    }

    /// Create an image from a raw pixel buffer containing 8-bit unsigned data.
    /// The buffer is copied, so the caller may release it after initialization.
    /// - Parameters:
    ///   - buffer: A pointer to the raw pixel data
    ///   - width: The image width in pixels
    ///   - height: The image height in pixels
    ///   - bands: The number of bands (channels) per pixel (e.g., 3 for RGB, 4 for RGBA)
    public convenience init(buffer: UnsafeRawPointer, width: Int, height: Int, bands: Int) throws {
        let size = width * height * bands
        guard let image = vips_image_new_from_memory_copy(buffer, size, Int32(width), Int32(height),
                                                          Int32(bands), VIPS_FORMAT_UCHAR) else {
            throw VIPSError.fromVips()
        }
        // Set color interpretation (images from memory default to MULTIBAND)
        image.pointee.Type = bands <= 2 ? VIPS_INTERPRETATION_B_W : VIPS_INTERPRETATION_sRGB
        self.init(pointer: image)
    }

    // MARK: - Async

    /// Get the dimensions and format of an image file without decoding its pixels.
    /// This is a fast, low-memory operation suitable for preflight checks.
    /// The work is performed off the calling actor via `Task.detached`.
    /// - Parameter path: The file path of the image to inspect
    /// - Returns: A tuple containing the image width, height, and detected format
    public static func imageInfo(atPath path: String) async throws -> (width: Int, height: Int, format: VIPSImageFormat) {
        try await Task.detached {
            try Self.imageInfo(atPath: path)
        }.value
    }

    /// Load an image from a file path, fully decoding it into memory.
    /// The work is performed off the calling actor via `Task.detached`.
    /// - Parameter path: The file path of the image to load
    /// - Returns: A new image loaded from the file
    public static func loaded(fromFile path: String) async throws -> VIPSImage {
        try await Task.detached {
            try VIPSImage(contentsOfFile: path)
        }.value
    }

    /// Load an image with sequential (streaming) access, reading pixels row-by-row.
    /// This uses less memory than random access but only supports top-to-bottom reading.
    /// The work is performed off the calling actor via `Task.detached`.
    /// - Parameter path: The file path of the image to load
    /// - Returns: A new image loaded with sequential access
    public static func loaded(fromFileSequential path: String) async throws -> VIPSImage {
        try await Task.detached {
            try VIPSImage(contentsOfFileSequential: path)
        }.value
    }

    /// Load an image from encoded data (JPEG, PNG, WebP, etc.).
    /// The format is detected automatically from the data contents.
    /// The work is performed off the calling actor via `Task.detached`.
    /// - Parameter data: The encoded image data
    /// - Returns: A new image decoded from the data
    public static func loaded(data: Data) async throws -> VIPSImage {
        try await Task.detached {
            try VIPSImage(data: data)
        }.value
    }

    /// Create a thumbnail from a file using shrink-on-load, which decodes
    /// the image at a reduced resolution for minimal memory usage. The result
    /// fits within the specified dimensions while maintaining aspect ratio.
    /// The work is performed off the calling actor via `Task.detached`.
    /// - Parameters:
    ///   - path: The file path of the source image
    ///   - width: The maximum width of the thumbnail
    ///   - height: The maximum height of the thumbnail
    /// - Returns: A new thumbnail image that fits within the specified dimensions
    public static func thumbnail(fromFile path: String, width: Int, height: Int) async throws -> VIPSImage {
        try await Task.detached {
            try Self.thumbnail(fromFile: path, width: width, height: height)
        }.value
    }

    /// Create a thumbnail from a file using shrink-on-load.
    /// The work is performed off the calling actor via `Task.detached`.
    /// - Parameters:
    ///   - path: The file path of the source image
    ///   - size: The maximum size of the thumbnail
    /// - Returns: A new thumbnail image that fits within the specified size
    public static func thumbnail(fromFile path: String, size: CGSize) async throws -> VIPSImage {
        try await Task.detached {
            try Self.thumbnail(fromFile: path, size: size)
        }.value
    }

    /// Create a thumbnail from in-memory data using shrink-on-load, which decodes
    /// the image at a reduced resolution for minimal memory usage. The result
    /// fits within the specified dimensions while maintaining aspect ratio.
    /// The work is performed off the calling actor via `Task.detached`.
    /// - Parameters:
    ///   - data: The encoded image data
    ///   - width: The maximum width of the thumbnail
    ///   - height: The maximum height of the thumbnail
    /// - Returns: A new thumbnail image that fits within the specified dimensions
    public static func thumbnail(fromData data: Data, width: Int, height: Int) async throws -> VIPSImage {
        try await Task.detached {
            try Self.thumbnail(fromData: data, width: width, height: height)
        }.value
    }

    /// Create a thumbnail from in-memory data using shrink-on-load.
    /// The work is performed off the calling actor via `Task.detached`.
    /// - Parameters:
    ///   - data: The encoded image data
    ///   - size: The maximum size of the thumbnail
    /// - Returns: A new thumbnail image that fits within the specified size
    public static func thumbnail(fromData data: Data, size: CGSize) async throws -> VIPSImage {
        try await Task.detached {
            try Self.thumbnail(fromData: data, size: size)
        }.value
    }
}
