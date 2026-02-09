import Foundation
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
    public func flipHorizontal() throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_flip(pointer, &out, VIPS_DIRECTION_HORIZONTAL) == 0, let out else {
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: out)
    }

    /// Flip the image vertically (mirror along the horizontal axis).
    /// - Returns: A new vertically flipped image
    public func flipVertical() throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_flip(pointer, &out, VIPS_DIRECTION_VERTICAL) == 0, let out else {
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: out)
    }

    /// Automatically rotate the image based on its EXIF orientation metadata,
    /// then remove the orientation tag so it won't be applied again.
    /// - Returns: A new correctly oriented image
    public func autoRotate() throws -> VIPSImage {
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
        let vipsInteresting: VipsInteresting
        switch interesting {
        case .none:      vipsInteresting = VIPS_INTERESTING_NONE
        case .centre:    vipsInteresting = VIPS_INTERESTING_CENTRE
        case .entropy:   vipsInteresting = VIPS_INTERESTING_ENTROPY
        case .attention: vipsInteresting = VIPS_INTERESTING_ATTENTION
        case .low:       vipsInteresting = VIPS_INTERESTING_LOW
        case .high:      vipsInteresting = VIPS_INTERESTING_HIGH
        }

        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_smartcrop(pointer, &out, Int32(width), Int32(height), vipsInteresting) == 0,
              let out else { throw VIPSError.fromVips() }
        return VIPSImage(pointer: out)
    }
}
