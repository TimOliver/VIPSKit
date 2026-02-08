import Foundation
internal import vips
internal import CVIPS

extension VIPSImage {

    // MARK: - Image Info

    /// Get image dimensions and format without loading pixels.
    public static func getImageInfo(atPath path: String) throws -> (width: Int, height: Int, format: VIPSImageFormat) {
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
            }
        }

        return (w, h, format)
    }

    // MARK: - File Loading

    /// Load image from file path.
    public convenience init(contentsOfFile path: String) throws {
        guard let image = cvips_image_new_from_file(path) else {
            throw VIPSError.fromVips()
        }
        self.init(pointer: image)
    }

    /// Load image with sequential access (streaming, row-by-row).
    public convenience init(contentsOfFileSequential path: String) throws {
        guard let image = cvips_image_new_from_file_sequential(path) else {
            throw VIPSError.fromVips()
        }
        self.init(pointer: image)
    }

    /// Create thumbnail from file using shrink-on-load (most memory efficient).
    public static func thumbnail(fromFile path: String, width: Int, height: Int) throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_thumbnail(path, &out, Int32(width), Int32(height)) == 0, let out else {
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: out)
    }

    /// Create thumbnail from data using shrink-on-load.
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

    // MARK: - Data Loading

    /// Load image from Data.
    public convenience init(data: Data) throws {
        let image: UnsafeMutablePointer<VipsImage>? = data.withUnsafeBytes { buffer in
            cvips_image_new_from_buffer(buffer.baseAddress, buffer.count)
        }
        guard let image else { throw VIPSError.fromVips() }
        self.init(pointer: image)
    }

    /// Create image from raw pixel buffer (assumes 8-bit unsigned data).
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
}
