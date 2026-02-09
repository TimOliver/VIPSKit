import Foundation
internal import vips
internal import CVIPS

extension VIPSImage {

    // MARK: - Canvas Creation

    /// Create a new blank (black) image with the specified dimensions.
    /// - Parameters:
    ///   - width: The width in pixels
    ///   - height: The height in pixels
    ///   - bands: The number of bands/channels (default is 3 for RGB)
    /// - Returns: A new black image
    public static func blank(width: Int, height: Int, bands: Int = 3) throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_black(&out, Int32(width), Int32(height), Int32(bands)) == 0,
              let out else { throw VIPSError.fromVips() }
        return VIPSImage(pointer: out)
    }

    // MARK: - Drawing

    /// Draw a rectangle on the image.
    /// - Parameters:
    ///   - x: The left edge of the rectangle
    ///   - y: The top edge of the rectangle
    ///   - width: The width of the rectangle
    ///   - height: The height of the rectangle
    ///   - color: The color as an array of band values (e.g., `[255, 0, 0]` for red)
    ///   - fill: Whether to fill the rectangle (`true`) or just draw the outline (`false`, default)
    /// - Returns: A new image with the rectangle drawn
    public func drawRect(x: Int, y: Int, width: Int, height: Int, color: [Double], fill: Bool = false) throws -> VIPSImage {
        guard let copy = vips_image_copy_memory(pointer) else {
            throw VIPSError.fromVips()
        }
        var ink = color
        let result = cvips_draw_rect(copy, &ink, Int32(ink.count),
                                     Int32(x), Int32(y), Int32(width), Int32(height),
                                     fill ? 1 : 0)
        guard result == 0 else {
            g_object_unref(gpointer(copy))
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: copy)
    }

    /// Draw a line between two points on the image.
    /// - Parameters:
    ///   - from: The starting point as `(x, y)`
    ///   - to: The ending point as `(x, y)`
    ///   - color: The color as an array of band values (e.g., `[255, 0, 0]` for red)
    /// - Returns: A new image with the line drawn
    public func drawLine(from: (x: Int, y: Int), to: (x: Int, y: Int), color: [Double]) throws -> VIPSImage {
        guard let copy = vips_image_copy_memory(pointer) else {
            throw VIPSError.fromVips()
        }
        var ink = color
        let result = cvips_draw_line(copy, &ink, Int32(ink.count),
                                     Int32(from.x), Int32(from.y),
                                     Int32(to.x), Int32(to.y))
        guard result == 0 else {
            g_object_unref(gpointer(copy))
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: copy)
    }

    /// Draw a circle on the image.
    /// - Parameters:
    ///   - cx: The x-coordinate of the circle center
    ///   - cy: The y-coordinate of the circle center
    ///   - radius: The radius of the circle in pixels
    ///   - color: The color as an array of band values (e.g., `[255, 0, 0]` for red)
    ///   - fill: Whether to fill the circle (`true`) or just draw the outline (`false`, default)
    /// - Returns: A new image with the circle drawn
    public func drawCircle(cx: Int, cy: Int, radius: Int, color: [Double], fill: Bool = false) throws -> VIPSImage {
        guard let copy = vips_image_copy_memory(pointer) else {
            throw VIPSError.fromVips()
        }
        var ink = color
        let result = cvips_draw_circle(copy, &ink, Int32(ink.count),
                                       Int32(cx), Int32(cy), Int32(radius),
                                       fill ? 1 : 0)
        guard result == 0 else {
            g_object_unref(gpointer(copy))
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: copy)
    }

    /// Flood-fill a region of the image starting from the specified point.
    /// All connected pixels that match the color at the starting point will
    /// be replaced with the specified color.
    /// - Parameters:
    ///   - x: The x-coordinate of the starting point
    ///   - y: The y-coordinate of the starting point
    ///   - color: The fill color as an array of band values
    /// - Returns: A new image with the flood fill applied
    public func floodFill(x: Int, y: Int, color: [Double]) throws -> VIPSImage {
        guard let copy = vips_image_copy_memory(pointer) else {
            throw VIPSError.fromVips()
        }
        var ink = color
        let result = cvips_draw_flood(copy, &ink, Int32(ink.count), Int32(x), Int32(y))
        guard result == 0 else {
            g_object_unref(gpointer(copy))
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: copy)
    }
}
