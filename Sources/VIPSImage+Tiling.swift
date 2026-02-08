import Foundation
import CoreGraphics
@_implementationOnly import vips
@_implementationOnly import CVIPS

extension VIPSImage {

    /// Calculate tile rects for dividing image into a grid.
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

    /// Number of horizontal strips for given height.
    public func numberOfStrips(withHeight stripHeight: Int) -> Int {
        guard stripHeight > 0 else { return 0 }
        return (height + stripHeight - 1) / stripHeight
    }

    /// Extract horizontal strip by index.
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

    /// Extract region from file (memory efficient).
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

    /// Extract region from data (memory efficient).
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
}
