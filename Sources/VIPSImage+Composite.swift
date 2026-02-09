import Foundation
internal import vips
internal import CVIPS

extension VIPSImage {

    /// Composite an overlay image on top of this image at the specified position
    /// using the given blend mode.
    /// - Parameters:
    ///   - overlay: The image to composite on top
    ///   - mode: The blend mode to use for compositing
    ///   - x: The horizontal offset for placing the overlay (in pixels from the left)
    ///   - y: The vertical offset for placing the overlay (in pixels from the top)
    /// - Returns: A new composited image
    public func composite(withOverlay overlay: VIPSImage, mode: VIPSBlendMode, x: Int, y: Int) throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_composite2(pointer, overlay.pointer, &out,
                               VipsBlendMode(rawValue: UInt32(mode.rawValue)),
                               Int32(x), Int32(y)) == 0,
              let out else { throw VIPSError.fromVips() }
        return VIPSImage(pointer: out)
    }

    /// Composite an overlay image centered on top of this image using the given blend mode.
    /// - Parameters:
    ///   - overlay: The image to composite on top
    ///   - mode: The blend mode to use for compositing
    /// - Returns: A new composited image with the overlay centered
    public func composite(withOverlay overlay: VIPSImage, mode: VIPSBlendMode) throws -> VIPSImage {
        let x = (width - overlay.width) / 2
        let y = (height - overlay.height) / 2
        return try composite(withOverlay: overlay, mode: mode, x: x, y: y)
    }
}
