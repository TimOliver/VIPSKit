import Foundation
internal import vips
internal import CVIPS

extension VIPSImage {

    /// Gaussian blur.
    public func blur(sigma: Double) throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_gaussblur(pointer, &out, sigma) == 0, let out else {
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: out)
    }

    /// Sharpen.
    public func sharpen(sigma: Double) throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_sharpen(pointer, &out, sigma) == 0, let out else {
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: out)
    }

    /// Sobel edge detection.
    public func sobel() throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_sobel(pointer, &out) == 0, let out else {
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: out)
    }

    /// Canny edge detection.
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
