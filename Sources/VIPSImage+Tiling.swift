import Foundation
import CoreGraphics
internal import vips
internal import CVIPS

extension VIPSImage {

    /// Calculate tile rectangles for dividing the image into a uniform grid.
    /// Edge tiles may be smaller if the image dimensions are not evenly divisible.
    /// - Parameters:
    ///   - tileWidth: The width of each tile in pixels
    ///   - tileHeight: The height of each tile in pixels
    /// - Returns: An array of rectangles representing each tile's position and size
    public func tileRects(tileWidth: Int, tileHeight: Int) -> [CGRect] {
        guard tileWidth > 0, tileHeight > 0 else { return [] }

        let cols = (width + tileWidth - 1) / tileWidth
        let rows = (height + tileHeight - 1) / tileHeight
        var rects: [CGRect] = []
        rects.reserveCapacity(rows * cols)

        for row in 0..<rows {
            for col in 0..<cols {
                let x = col * tileWidth
                let y = row * tileHeight
                let w = min(tileWidth, width - x)
                let h = min(tileHeight, height - y)
                rects.append(CGRect(x: x, y: y, width: w, height: h))
            }
        }
        return rects
    }

    /// Calculate how many horizontal strips the image can be divided into
    /// for the given strip height.
    /// - Parameter stripHeight: The height of each strip in pixels
    /// - Returns: The total number of strips
    public func numberOfStrips(withHeight stripHeight: Int) -> Int {
        guard stripHeight > 0 else { return 0 }
        return (height + stripHeight - 1) / stripHeight
    }

    /// Extract a horizontal strip from the image by its index.
    /// The last strip may be shorter if the image height is not evenly divisible.
    /// - Parameters:
    ///   - index: The zero-based index of the strip to extract
    ///   - stripHeight: The height of each strip in pixels
    /// - Returns: A new image containing the specified strip
    public func strip(atIndex index: Int, height stripHeight: Int) throws -> VIPSImage {
        guard stripHeight > 0 else { throw VIPSError("Strip height must be positive") }
        let numStrips = numberOfStrips(withHeight: stripHeight)
        guard index >= 0, index < numStrips else {
            throw VIPSError("Strip index \(index) out of range [0, \(numStrips))")
        }

        let y = index * stripHeight
        let actualHeight = min(stripHeight, height - y)
        return try crop(x: 0, y: y, width: width, height: actualHeight)
    }

    /// Extract a rectangular region from an image file without loading the entire
    /// image into memory. This is the most memory-efficient way to read a portion
    /// of a large image.
    /// - Parameters:
    ///   - path: The file path of the source image
    ///   - x: The left edge of the region in pixels
    ///   - y: The top edge of the region in pixels
    ///   - width: The width of the region in pixels
    ///   - height: The height of the region in pixels
    /// - Returns: A new image containing only the specified region
    public static func extractRegion(fromFile path: String,
                                     x: Int, y: Int, width: Int, height: Int) throws -> VIPSImage {
        guard let source = cvips_image_new_from_file_sequential(path) else {
            throw VIPSError.fromVips()
        }

        let sw = Int(vips_image_get_width(source))
        let sh = Int(vips_image_get_height(source))
        guard x >= 0, y >= 0, x + width <= sw, y + height <= sh else {
            g_object_unref(gpointer(source))
            throw VIPSError("Region (\(x),\(y),\(width),\(height)) exceeds image bounds (\(sw),\(sh))")
        }

        var region: UnsafeMutablePointer<VipsImage>?
        guard cvips_extract_area(source, &region, Int32(x), Int32(y), Int32(width), Int32(height)) == 0,
              let region else {
            g_object_unref(gpointer(source))
            throw VIPSError.fromVips()
        }

        guard let copied = vips_image_copy_memory(region) else {
            g_object_unref(gpointer(region))
            g_object_unref(gpointer(source))
            throw VIPSError.fromVips()
        }
        g_object_unref(gpointer(region))
        g_object_unref(gpointer(source))
        return VIPSImage(pointer: copied)
    }

    /// Extract a rectangular region from in-memory image data without fully
    /// decoding the entire image. This is the most memory-efficient way to
    /// read a portion of a large image from a data buffer.
    /// - Parameters:
    ///   - data: The encoded image data
    ///   - x: The left edge of the region in pixels
    ///   - y: The top edge of the region in pixels
    ///   - width: The width of the region in pixels
    ///   - height: The height of the region in pixels
    /// - Returns: A new image containing only the specified region
    public static func extractRegion(fromData data: Data,
                                     x: Int, y: Int, width: Int, height: Int) throws -> VIPSImage {
        let source: UnsafeMutablePointer<VipsImage>? = data.withUnsafeBytes { buffer in
            cvips_image_new_from_buffer_sequential(buffer.baseAddress, buffer.count)
        }
        guard let source else { throw VIPSError.fromVips() }

        let sw = Int(vips_image_get_width(source))
        let sh = Int(vips_image_get_height(source))
        guard x >= 0, y >= 0, x + width <= sw, y + height <= sh else {
            g_object_unref(gpointer(source))
            throw VIPSError("Region (\(x),\(y),\(width),\(height)) exceeds image bounds (\(sw),\(sh))")
        }

        var region: UnsafeMutablePointer<VipsImage>?
        guard cvips_extract_area(source, &region, Int32(x), Int32(y), Int32(width), Int32(height)) == 0,
              let region else {
            g_object_unref(gpointer(source))
            throw VIPSError.fromVips()
        }

        guard let copied = vips_image_copy_memory(region) else {
            g_object_unref(gpointer(region))
            g_object_unref(gpointer(source))
            throw VIPSError.fromVips()
        }
        g_object_unref(gpointer(region))
        g_object_unref(gpointer(source))
        return VIPSImage(pointer: copied)
    }

    // MARK: - Async

    /// Asynchronously extract a rectangular region from an image file.
    public static func extractedRegion(fromFile path: String,
                                       x: Int, y: Int, width: Int, height: Int) async throws -> VIPSImage {
        try await Task.detached {
            try Self.extractRegion(fromFile: path, x: x, y: y, width: width, height: height)
        }.value
    }

    /// Asynchronously extract a rectangular region from in-memory image data.
    public static func extractedRegion(fromData data: Data,
                                       x: Int, y: Int, width: Int, height: Int) async throws -> VIPSImage {
        try await Task.detached {
            try Self.extractRegion(fromData: data, x: x, y: y, width: width, height: height)
        }.value
    }
}
