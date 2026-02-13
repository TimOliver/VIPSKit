import Foundation
internal import vips
internal import CVIPS

extension VIPSImage {

    /// Join the bands of this image with the bands of another image.
    /// The two images must have the same width and height.
    /// - Parameter other: The image whose bands to append
    /// - Returns: A new image with the combined bands of both images
    public func joinBands(with other: VIPSImage) throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_bandjoin2(pointer, other.pointer, &out) == 0, let out else {
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: out)
    }

    /// Append a constant-value band to the image. Useful for adding a solid
    /// alpha channel or an extra data channel.
    /// - Parameter constant: The constant value for the new band
    /// - Returns: A new image with the extra band appended
    public func appendBand(constant: Double) throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_bandjoin_const1(pointer, &out, constant) == 0, let out else {
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: out)
    }

    /// Add a fully opaque alpha channel to the image.
    /// If the image already has an alpha channel, returns a copy without adding another.
    /// - Returns: A new image with an alpha channel
    public func addingAlpha() throws -> VIPSImage {
        if hasAlpha { return try copiedToMemory() }
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_addalpha(pointer, &out) == 0, let out else {
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: out)
    }

    /// Premultiply the RGB channels by the alpha channel.
    /// This is required before certain operations (like resizing) to avoid
    /// dark fringes around semi-transparent edges.
    /// - Returns: A new image with premultiplied alpha
    public func premultiplied() throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_premultiply(pointer, &out) == 0, let out else {
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: out)
    }

    /// Undo premultiplication, dividing RGB channels by the alpha channel.
    /// Call this after performing operations on premultiplied images to restore
    /// normal (straight) alpha.
    /// - Returns: A new image with straight (unpremultiplied) alpha
    public func unpremultiplied() throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_unpremultiply(pointer, &out) == 0, let out else {
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: out)
    }

    // MARK: - Async

    /// Premultiply the RGB channels by the alpha channel.
    /// This is required before certain operations (like resizing) to avoid
    /// dark fringes around semi-transparent edges.
    /// The work is performed off the calling actor via `Task.detached`.
    /// - Returns: A new image with premultiplied alpha
    public func premultiplied() async throws -> VIPSImage {
        try await Task.detached {
            try self.premultiplied()
        }.value
    }

    /// Undo premultiplication, dividing RGB channels by the alpha channel.
    /// Call this after performing operations on premultiplied images to restore
    /// normal (straight) alpha.
    /// The work is performed off the calling actor via `Task.detached`.
    /// - Returns: A new image with straight (unpremultiplied) alpha
    public func unpremultiplied() async throws -> VIPSImage {
        try await Task.detached {
            try self.unpremultiplied()
        }.value
    }
}
