import Foundation
internal import vips
internal import CVIPS

extension VIPSImage {

    /// Resize the image to fit within the given dimensions while maintaining aspect ratio.
    /// Uses high-quality shrink-on-load when possible for optimal performance.
    /// - Parameters:
    ///   - width: The maximum width of the result
    ///   - height: The maximum height of the result
    /// - Returns: A new image that fits within the specified dimensions
    public func resizeToFit(width: Int, height: Int) throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_thumbnail_image(pointer, &out, Int32(width), Int32(height)) == 0,
              let out else { throw VIPSError.fromVips() }
        return VIPSImage(pointer: out)
    }

    /// Resize the image by a scale factor using the specified interpolation kernel.
    /// - Parameters:
    ///   - scale: The scale factor to apply (e.g., 0.5 for half size, 2.0 for double size)
    ///   - kernel: The interpolation kernel to use (default is ``VIPSResizeKernel/lanczos3``)
    /// - Returns: A new image scaled by the given factor
    public func resize(scale: Double, kernel: VIPSResizeKernel = .lanczos3) throws -> VIPSImage {
        let vipsKernel: VipsKernel
        switch kernel {
        case .nearest:  vipsKernel = VIPS_KERNEL_NEAREST
        case .linear:   vipsKernel = VIPS_KERNEL_LINEAR
        case .cubic:    vipsKernel = VIPS_KERNEL_CUBIC
        case .lanczos2: vipsKernel = VIPS_KERNEL_LANCZOS2
        case .lanczos3: vipsKernel = VIPS_KERNEL_LANCZOS3
        }

        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_resize(pointer, &out, scale, vipsKernel) == 0, let out else {
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: out)
    }

    /// Resize the image to exact dimensions, potentially changing the aspect ratio.
    /// - Parameters:
    ///   - width: The target width in pixels
    ///   - height: The target height in pixels
    /// - Returns: A new image with the exact specified dimensions
    public func resize(toWidth width: Int, height: Int) throws -> VIPSImage {
        let hScale = Double(width) / Double(self.width)
        let vScale = Double(height) / Double(self.height)

        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_resize_wh(pointer, &out, hScale, vScale) == 0, let out else {
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: out)
    }
}
