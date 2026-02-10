import Foundation
import CoreGraphics
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

    /// Create a new blank (black) image with the specified size.
    /// - Parameters:
    ///   - size: The size of the image
    ///   - bands: The number of bands/channels (default is 3 for RGB)
    /// - Returns: A new black image
    public static func blank(size: CGSize, bands: Int = 3) throws -> VIPSImage {
        try blank(width: Int(size.width), height: Int(size.height), bands: bands)
    }

    // MARK: - Drawing
    //
    // Draw operations mutate the image in-place, matching the underlying
    // libvips behaviour. Use `blank(width:height:)` to create a canvas,
    // then chain draw calls on it. Each method returns `self` so calls
    // can be chained:
    //
    //     let canvas = try VIPSImage.blank(width: 200, height: 200)
    //     try canvas
    //         .drawRect(x: 10, y: 10, width: 50, height: 50, color: .white, fill: true)
    //         .drawCircle(cx: 100, cy: 100, radius: 30, color: .black, fill: true)
    //

    /// Draw a rectangle on the image (mutates in-place).
    /// - Parameters:
    ///   - x: The left edge of the rectangle
    ///   - y: The top edge of the rectangle
    ///   - width: The width of the rectangle
    ///   - height: The height of the rectangle
    ///   - color: The fill/stroke color
    ///   - fill: Whether to fill the rectangle (`true`) or just draw the outline (`false`, default)
    /// - Returns: `self` for chaining
    @discardableResult
    public func drawRect(x: Int, y: Int, width: Int, height: Int, color: VIPSColor, fill: Bool = false) throws -> VIPSImage {
        try ensureWritable()
        var ink = color.ink(forBands: bands)
        let result = cvips_draw_rect(pointer, &ink, Int32(ink.count),
                                     Int32(x), Int32(y), Int32(width), Int32(height),
                                     fill ? 1 : 0)
        guard result == 0 else { throw VIPSError.fromVips() }
        return self
    }

    /// Draw a line between two points on the image (mutates in-place).
    /// - Parameters:
    ///   - from: The starting point
    ///   - to: The ending point
    ///   - color: The line color
    /// - Returns: `self` for chaining
    @discardableResult
    public func drawLine(from: CGPoint, to: CGPoint, color: VIPSColor) throws -> VIPSImage {
        try ensureWritable()
        var ink = color.ink(forBands: bands)
        let result = cvips_draw_line(pointer, &ink, Int32(ink.count),
                                     Int32(from.x), Int32(from.y),
                                     Int32(to.x), Int32(to.y))
        guard result == 0 else { throw VIPSError.fromVips() }
        return self
    }

    /// Draw a circle on the image (mutates in-place).
    /// - Parameters:
    ///   - cx: The x-coordinate of the circle center
    ///   - cy: The y-coordinate of the circle center
    ///   - radius: The radius of the circle in pixels
    ///   - color: The fill/stroke color
    ///   - fill: Whether to fill the circle (`true`) or just draw the outline (`false`, default)
    /// - Returns: `self` for chaining
    @discardableResult
    public func drawCircle(cx: Int, cy: Int, radius: Int, color: VIPSColor, fill: Bool = false) throws -> VIPSImage {
        try ensureWritable()
        var ink = color.ink(forBands: bands)
        let result = cvips_draw_circle(pointer, &ink, Int32(ink.count),
                                       Int32(cx), Int32(cy), Int32(radius),
                                       fill ? 1 : 0)
        guard result == 0 else { throw VIPSError.fromVips() }
        return self
    }

    /// Draw a circle on the image (mutates in-place).
    /// - Parameters:
    ///   - center: The center point of the circle
    ///   - radius: The radius of the circle in pixels
    ///   - color: The fill/stroke color
    ///   - fill: Whether to fill the circle (`true`) or just draw the outline (`false`, default)
    /// - Returns: `self` for chaining
    @discardableResult
    public func drawCircle(center: CGPoint, radius: Int, color: VIPSColor, fill: Bool = false) throws -> VIPSImage {
        try drawCircle(cx: Int(center.x), cy: Int(center.y), radius: radius, color: color, fill: fill)
    }

    /// Flood-fill a region of the image starting from the specified point
    /// (mutates in-place). All connected pixels that match the color at the
    /// starting point will be replaced with the specified color.
    /// - Parameters:
    ///   - x: The x-coordinate of the starting point
    ///   - y: The y-coordinate of the starting point
    ///   - color: The fill color
    /// - Returns: `self` for chaining
    @discardableResult
    public func floodFill(x: Int, y: Int, color: VIPSColor) throws -> VIPSImage {
        try ensureWritable()
        var ink = color.ink(forBands: bands)
        let result = cvips_draw_flood(pointer, &ink, Int32(ink.count), Int32(x), Int32(y))
        guard result == 0 else { throw VIPSError.fromVips() }
        return self
    }

    /// Flood-fill a region of the image starting from the specified point
    /// (mutates in-place).
    /// - Parameters:
    ///   - point: The starting point
    ///   - color: The fill color
    /// - Returns: `self` for chaining
    @discardableResult
    public func floodFill(at point: CGPoint, color: VIPSColor) throws -> VIPSImage {
        try floodFill(x: Int(point.x), y: Int(point.y), color: color)
    }
}
