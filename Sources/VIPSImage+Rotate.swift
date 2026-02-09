import Foundation
internal import vips
internal import CVIPS

extension VIPSImage {

    /// Rotate the image by an arbitrary angle in degrees.
    /// Unlike ``rotate(degrees:)`` which only supports 90-degree multiples,
    /// this method can rotate by any angle. The output image is enlarged
    /// to contain the entire rotated result, with black fill in the corners.
    /// - Parameter degrees: The rotation angle in degrees (positive is counter-clockwise)
    /// - Returns: A new rotated image
    public func rotate(byAngle degrees: Double) throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_rotate(pointer, &out, degrees) == 0, let out else {
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: out)
    }
}
