import Foundation
import CoreGraphics
internal import vips
internal import CVIPS

extension VIPSImage {

    /// Crop a rectangular region from the image.
    /// - Parameters:
    ///   - x: The left edge of the crop area in pixels
    ///   - y: The top edge of the crop area in pixels
    ///   - width: The width of the crop area in pixels
    ///   - height: The height of the crop area in pixels
    /// - Returns: A new image containing only the cropped region
    public func crop(x: Int, y: Int, width: Int, height: Int) throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_crop(pointer, &out, Int32(x), Int32(y), Int32(width), Int32(height)) == 0,
              let out else { throw VIPSError.fromVips() }
        return VIPSImage(pointer: out)
    }

    /// Crop a rectangular region from the image.
    /// - Parameter rect: The crop rectangle
    /// - Returns: A new image containing only the cropped region
    public func crop(_ rect: CGRect) throws -> VIPSImage {
        try crop(x: Int(rect.origin.x), y: Int(rect.origin.y),
                 width: Int(rect.size.width), height: Int(rect.size.height))
    }

    /// Rotate the image by a multiple of 90 degrees.
    /// Values that are not multiples of 90 are rounded to the nearest right angle.
    /// - Parameter degrees: The rotation angle (90, 180, or 270)
    /// - Returns: A new rotated image
    public func rotate(degrees: Int) throws -> VIPSImage {
        let angle: VipsAngle
        switch degrees % 360 {
        case 90, -270:   angle = VIPS_ANGLE_D90
        case 180, -180:  angle = VIPS_ANGLE_D180
        case 270, -90:   angle = VIPS_ANGLE_D270
        default:         angle = VIPS_ANGLE_D0
        }

        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_rot(pointer, &out, angle) == 0, let out else {
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: out)
    }

    /// Flip the image horizontally (mirror along the vertical axis).
    /// - Returns: A new horizontally flipped image
    public func flippedHorizontally() throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_flip(pointer, &out, VIPS_DIRECTION_HORIZONTAL) == 0, let out else {
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: out)
    }

    /// Flip the image vertically (mirror along the horizontal axis).
    /// - Returns: A new vertically flipped image
    public func flippedVertically() throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_flip(pointer, &out, VIPS_DIRECTION_VERTICAL) == 0, let out else {
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: out)
    }

    /// Automatically rotate the image based on its EXIF orientation metadata,
    /// then remove the orientation tag so it won't be applied again.
    /// - Returns: A new correctly oriented image
    public func autoRotated() throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_autorot(pointer, &out) == 0, let out else {
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: out)
    }

    /// Perform a content-aware smart crop to the specified dimensions.
    /// Unlike a regular crop, this analyzes the image to keep the most
    /// visually important region.
    /// - Parameters:
    ///   - width: The target width in pixels
    ///   - height: The target height in pixels
    ///   - interesting: The strategy for selecting the interesting region
    ///     (default is ``VIPSInteresting/attention``)
    /// - Returns: A new image cropped to the target dimensions around the most interesting region
    public func smartCrop(toWidth width: Int, height: Int, interesting: VIPSInteresting = .attention) throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_smartcrop(pointer, &out, Int32(width), Int32(height), interesting.vipsValue) == 0,
              let out else { throw VIPSError.fromVips() }
        return VIPSImage(pointer: out)
    }

    /// Perform a content-aware smart crop to the specified size.
    /// - Parameters:
    ///   - size: The target size
    ///   - interesting: The strategy for selecting the interesting region
    ///     (default is ``VIPSInteresting/attention``)
    /// - Returns: A new image cropped to the target dimensions around the most interesting region
    public func smartCrop(to size: CGSize, interesting: VIPSInteresting = .attention) throws -> VIPSImage {
        try smartCrop(toWidth: Int(size.width), height: Int(size.height), interesting: interesting)
    }

    // MARK: - Join

    /// Join this image with another side by side horizontally.
    /// The two images are placed left-to-right; the result width is the sum of both
    /// widths and the result height is the maximum of both heights.
    /// - Parameter other: The image to place to the right
    /// - Returns: A new image with the two images joined horizontally
    public func joinedHorizontally(with other: VIPSImage) throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_join(pointer, other.pointer, &out, VIPS_DIRECTION_HORIZONTAL) == 0,
              let out else { throw VIPSError.fromVips() }
        return VIPSImage(pointer: out)
    }

    /// Join this image with another stacked vertically.
    /// The two images are placed top-to-bottom; the result height is the sum of both
    /// heights and the result width is the maximum of both widths.
    /// - Parameter other: The image to place below
    /// - Returns: A new image with the two images joined vertically
    public func joinedVertically(with other: VIPSImage) throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_join(pointer, other.pointer, &out, VIPS_DIRECTION_VERTICAL) == 0,
              let out else { throw VIPSError.fromVips() }
        return VIPSImage(pointer: out)
    }

    // MARK: - Async

    /// Crop a rectangular region from the image.
    /// The work is performed off the calling actor via `Task.detached`.
    /// - Parameters:
    ///   - x: The left edge of the crop area in pixels
    ///   - y: The top edge of the crop area in pixels
    ///   - width: The width of the crop area in pixels
    ///   - height: The height of the crop area in pixels
    /// - Returns: A new image containing only the cropped region
    public func cropped(x: Int, y: Int, width: Int, height: Int) async throws -> VIPSImage {
        try await Task.detached {
            try self.crop(x: x, y: y, width: width, height: height)
        }.value
    }

    /// Crop a rectangular region from the image.
    /// The work is performed off the calling actor via `Task.detached`.
    /// - Parameter rect: The crop rectangle
    /// - Returns: A new image containing only the cropped region
    public func cropped(_ rect: CGRect) async throws -> VIPSImage {
        try await Task.detached {
            try self.crop(rect)
        }.value
    }

    /// Perform a content-aware smart crop to the specified dimensions.
    /// Unlike a regular crop, this analyzes the image to keep the most
    /// visually important region.
    /// The work is performed off the calling actor via `Task.detached`.
    /// - Parameters:
    ///   - width: The target width in pixels
    ///   - height: The target height in pixels
    ///   - interesting: The strategy for selecting the interesting region
    ///     (default is ``VIPSInteresting/attention``)
    /// - Returns: A new image cropped to the target dimensions around the most interesting region
    public func smartCropped(toWidth width: Int, height: Int, interesting: VIPSInteresting = .attention) async throws -> VIPSImage {
        try await Task.detached {
            try self.smartCrop(toWidth: width, height: height, interesting: interesting)
        }.value
    }

    /// Perform a content-aware smart crop to the specified size.
    /// The work is performed off the calling actor via `Task.detached`.
    /// - Parameters:
    ///   - size: The target size
    ///   - interesting: The strategy for selecting the interesting region
    ///     (default is ``VIPSInteresting/attention``)
    /// - Returns: A new image cropped to the target dimensions around the most interesting region
    public func smartCropped(to size: CGSize, interesting: VIPSInteresting = .attention) async throws -> VIPSImage {
        try await Task.detached {
            try self.smartCrop(to: size, interesting: interesting)
        }.value
    }

    /// Join this image with another side by side horizontally.
    /// The work is performed off the calling actor via `Task.detached`.
    /// - Parameter other: The image to place to the right
    /// - Returns: A new image with the two images joined horizontally
    public func joinedHorizontally(with other: VIPSImage) async throws -> VIPSImage {
        try await Task.detached {
            try self.joinedHorizontally(with: other)
        }.value
    }

    /// Join this image with another stacked vertically.
    /// The work is performed off the calling actor via `Task.detached`.
    /// - Parameter other: The image to place below
    /// - Returns: A new image with the two images joined vertically
    public func joinedVertically(with other: VIPSImage) async throws -> VIPSImage {
        try await Task.detached {
            try self.joinedVertically(with: other)
        }.value
    }
}
