import Foundation
internal import vips
internal import CVIPS

extension VIPSImage {

    /// Resize to fit within dimensions, maintaining aspect ratio (high quality).
    public func resizeToFit(width: Int, height: Int) throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_thumbnail_image(pointer, &out, Int32(width), Int32(height)) == 0,
              let out else { throw VIPSError.fromVips() }
        return VIPSImage(pointer: out)
    }

    /// Resize by scale factor.
    public func resize(scale: Double, kernel: ResizeKernel = .lanczos3) throws -> VIPSImage {
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

    /// Resize to exact dimensions (may change aspect ratio).
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
