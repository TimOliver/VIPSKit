import Foundation
internal import vips
internal import CVIPS

extension VIPSImage {

    /// Embed the image within a larger canvas at the specified position.
    /// The extra space is filled according to the extend mode.
    /// - Parameters:
    ///   - x: The horizontal offset to place the image at within the new canvas
    ///   - y: The vertical offset to place the image at within the new canvas
    ///   - width: The total width of the output canvas
    ///   - height: The total height of the output canvas
    ///   - extend: How to fill the extra space (default is ``VIPSExtendMode/black``)
    /// - Returns: A new image with the original embedded in a larger canvas
    public func embed(x: Int, y: Int, width: Int, height: Int, extend: VIPSExtendMode = .black) throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_embed(pointer, &out, Int32(x), Int32(y), Int32(width), Int32(height),
                          VipsExtend(rawValue: UInt32(extend.rawValue))) == 0,
              let out else { throw VIPSError.fromVips() }
        return VIPSImage(pointer: out)
    }

    /// Place the image within a larger canvas using a compass direction for alignment.
    /// - Parameters:
    ///   - direction: Where to position the image within the canvas
    ///   - width: The total width of the output canvas
    ///   - height: The total height of the output canvas
    ///   - extend: How to fill the extra space (default is ``VIPSExtendMode/black``)
    /// - Returns: A new image positioned within a larger canvas
    public func gravity(direction: VIPSCompassDirection, width: Int, height: Int, extend: VIPSExtendMode = .black) throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_gravity(pointer, &out,
                            VipsCompassDirection(rawValue: UInt32(direction.rawValue)),
                            Int32(width), Int32(height),
                            VipsExtend(rawValue: UInt32(extend.rawValue))) == 0,
              let out else { throw VIPSError.fromVips() }
        return VIPSImage(pointer: out)
    }

    /// Add uniform padding around the image.
    /// - Parameters:
    ///   - top: Padding above the image in pixels
    ///   - left: Padding to the left of the image in pixels
    ///   - bottom: Padding below the image in pixels
    ///   - right: Padding to the right of the image in pixels
    ///   - extend: How to fill the padding area (default is ``VIPSExtendMode/black``)
    /// - Returns: A new padded image
    public func pad(top: Int = 0, left: Int = 0, bottom: Int = 0, right: Int = 0, extend: VIPSExtendMode = .black) throws -> VIPSImage {
        let newWidth = width + left + right
        let newHeight = height + top + bottom
        return try embed(x: left, y: top, width: newWidth, height: newHeight, extend: extend)
    }
}
