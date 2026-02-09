import Foundation
internal import vips
internal import CVIPS

extension VIPSImage {

    /// Apply histogram equalization to improve the contrast of the image.
    /// This redistributes pixel intensities so that the histogram is more uniform,
    /// which is especially useful for images with poor contrast.
    /// - Returns: A new image with equalized histogram
    public func equalizeHistogram() throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_hist_equal(pointer, &out) == 0, let out else {
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: out)
    }
}
