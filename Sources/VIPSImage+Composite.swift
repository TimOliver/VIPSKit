import Foundation
import CoreGraphics
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
        guard cvips_composite2(pointer, overlay.pointer, &out, mode.vipsValue,
                               Int32(x), Int32(y)) == 0,
              let out else { throw VIPSError.fromVips() }
        return VIPSImage(pointer: out)
    }

    /// Composite an overlay image on top of this image at the specified point.
    /// - Parameters:
    ///   - overlay: The image to composite on top
    ///   - mode: The blend mode to use for compositing
    ///   - point: The position for placing the overlay
    /// - Returns: A new composited image
    public func composite(withOverlay overlay: VIPSImage, mode: VIPSBlendMode, at point: CGPoint) throws -> VIPSImage {
        try composite(withOverlay: overlay, mode: mode, x: Int(point.x), y: Int(point.y))
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

    // MARK: - Async

    /// Composite an overlay image on top of this image at the specified position
    /// using the given blend mode.
    /// The work is performed off the calling actor via `Task.detached`.
    /// - Parameters:
    ///   - overlay: The image to composite on top
    ///   - mode: The blend mode to use for compositing
    ///   - x: The horizontal offset for placing the overlay (in pixels from the left)
    ///   - y: The vertical offset for placing the overlay (in pixels from the top)
    /// - Returns: A new composited image
    public func composited(withOverlay overlay: VIPSImage, mode: VIPSBlendMode, x: Int, y: Int) async throws -> VIPSImage {
        try await Task.detached {
            try self.composite(withOverlay: overlay, mode: mode, x: x, y: y)
        }.value
    }

    /// Composite an overlay image on top of this image at the specified point.
    /// The work is performed off the calling actor via `Task.detached`.
    /// - Parameters:
    ///   - overlay: The image to composite on top
    ///   - mode: The blend mode to use for compositing
    ///   - point: The position for placing the overlay
    /// - Returns: A new composited image
    public func composited(withOverlay overlay: VIPSImage, mode: VIPSBlendMode, at point: CGPoint) async throws -> VIPSImage {
        try await Task.detached {
            try self.composite(withOverlay: overlay, mode: mode, at: point)
        }.value
    }

    /// Composite an overlay image centered on top of this image using the given blend mode.
    /// The work is performed off the calling actor via `Task.detached`.
    /// - Parameters:
    ///   - overlay: The image to composite on top
    ///   - mode: The blend mode to use for compositing
    /// - Returns: A new composited image with the overlay centered
    public func composited(withOverlay overlay: VIPSImage, mode: VIPSBlendMode) async throws -> VIPSImage {
        try await Task.detached {
            try self.composite(withOverlay: overlay, mode: mode)
        }.value
    }
}
