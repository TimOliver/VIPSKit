import Foundation
@_implementationOnly import vips
@_implementationOnly import CVIPS

extension VIPSImage {

    /// Crop a region from the image.
    public func crop(x: Int, y: Int, width: Int, height: Int) throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_crop(pointer, &out, Int32(x), Int32(y), Int32(width), Int32(height)) == 0,
              let out else { throw VIPSError.fromVips() }
        return VIPSImage(pointer: out)
    }

    /// Rotate by 90, 180, or 270 degrees.
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

    /// Mirror horizontally.
    public func flipHorizontal() throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_flip(pointer, &out, VIPS_DIRECTION_HORIZONTAL) == 0, let out else {
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: out)
    }

    /// Mirror vertically.
    public func flipVertical() throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_flip(pointer, &out, VIPS_DIRECTION_VERTICAL) == 0, let out else {
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: out)
    }

    /// Auto-rotate based on EXIF orientation.
    public func autoRotate() throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_autorot(pointer, &out) == 0, let out else {
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: out)
    }

    /// Content-aware smart crop.
    public func smartCrop(toWidth width: Int, height: Int, interesting: Interesting = .attention) throws -> VIPSImage {
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
