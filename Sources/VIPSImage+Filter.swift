import Foundation
internal import vips
internal import CVIPS

extension VIPSImage {

    /// Apply a Gaussian blur to the image.
    /// - Parameter sigma: The standard deviation of the Gaussian kernel.
    ///   Larger values produce a stronger blur.
    /// - Returns: A new blurred image
    public func blurred(sigma: Double) throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_gaussblur(pointer, &out, sigma) == 0, let out else {
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: out)
    }

    /// Sharpen the image using an unsharp mask.
    /// - Parameter sigma: The standard deviation of the sharpening kernel.
    ///   Larger values sharpen a wider area.
    /// - Returns: A new sharpened image
    public func sharpened(sigma: Double) throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_sharpen(pointer, &out, sigma) == 0, let out else {
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: out)
    }

    /// Apply Sobel edge detection to produce a grayscale image
    /// where edges appear as bright lines on a dark background.
    /// - Returns: A new image highlighting detected edges
    public func sobel() throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_sobel(pointer, &out) == 0, let out else {
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: out)
    }

    /// Apply Canny edge detection, a more sophisticated edge detector that
    /// produces thin, well-localized edges.
    /// - Parameter sigma: The standard deviation of the Gaussian smoothing
    ///   applied before edge detection (default is 1.4)
    /// - Returns: A new 8-bit image highlighting detected edges
    public func canny(sigma: Double = 1.4) throws -> VIPSImage {
        var cannyOut: UnsafeMutablePointer<VipsImage>?
        guard cvips_canny(pointer, &cannyOut, sigma) == 0, let cannyOut else {
            throw VIPSError.fromVips()
        }

        // vips_canny outputs a float image - cast to uchar
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_cast_uchar(cannyOut, &out) == 0, let out else {
            g_object_unref(gpointer(cannyOut))
            throw VIPSError.fromVips()
        }
        g_object_unref(gpointer(cannyOut))
        return VIPSImage(pointer: out)
    }
}
