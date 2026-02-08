import Foundation
internal import vips
internal import CVIPS

extension VIPSImage {

    /// Composite with overlay at position using blend mode.
    public func composite(withOverlay overlay: VIPSImage, mode: VIPSBlendMode, x: Int, y: Int) throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_composite2(pointer, overlay.pointer, &out,
                               VipsBlendMode(rawValue: UInt32(mode.rawValue)),
                               Int32(x), Int32(y)) == 0,
              let out else { throw VIPSError.fromVips() }
        return VIPSImage(pointer: out)
    }

    /// Composite with overlay centered using blend mode.
    public func composite(withOverlay overlay: VIPSImage, mode: VIPSBlendMode) throws -> VIPSImage {
        let x = (width - overlay.width) / 2
        let y = (height - overlay.height) / 2
        return try composite(withOverlay: overlay, mode: mode, x: x, y: y)
    }
}
