import Foundation
internal import vips
internal import CVIPS

extension VIPSImage {

    /// Convert to grayscale.
    public func grayscale() throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_colourspace(pointer, &out, VIPS_INTERPRETATION_B_W) == 0, let out else {
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: out)
    }

    /// Flatten alpha against a background color.
    public func flatten(red: Int, green: Int, blue: Int) throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_flatten(pointer, &out, Double(red), Double(green), Double(blue)) == 0,
              let out else { throw VIPSError.fromVips() }
        return VIPSImage(pointer: out)
    }

    /// Invert colors (negative).
    public func invert() throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_invert(pointer, &out) == 0, let out else {
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: out)
    }

    /// Adjust brightness (-1.0 to 1.0).
    public func adjustBrightness(_ brightness: Double) throws -> VIPSImage {
        let offset = brightness * 255.0
        let n = hasAlpha ? 3 : bands
        var a = [Double](repeating: 1.0, count: n)
        var b = [Double](repeating: offset, count: n)

        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_linear(pointer, &out, &a, &b, Int32(n)) == 0, let out else {
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: out)
    }

    /// Adjust contrast (0.5 to 2.0).
    public func adjustContrast(_ contrast: Double) throws -> VIPSImage {
        let offset = 127.5 * (1.0 - contrast)
        let n = hasAlpha ? 3 : bands
        var a = [Double](repeating: contrast, count: n)
        var b = [Double](repeating: offset, count: n)

        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_linear(pointer, &out, &a, &b, Int32(n)) == 0, let out else {
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: out)
    }

    /// Adjust saturation (0 = grayscale, 1.0 = normal, > 1.0 = more saturated).
    public func adjustSaturation(_ saturation: Double) throws -> VIPSImage {
        var lch: UnsafeMutablePointer<VipsImage>?
        guard cvips_colourspace(pointer, &lch, VIPS_INTERPRETATION_LCH) == 0, let lch else {
            throw VIPSError.fromVips()
        }

        var a: [Double] = [1.0, saturation, 1.0]
        var b: [Double] = [0.0, 0.0, 0.0]
        var adjusted: UnsafeMutablePointer<VipsImage>?
        guard cvips_linear(lch, &adjusted, &a, &b, 3) == 0, let adjusted else {
            g_object_unref(gpointer(lch))
            throw VIPSError.fromVips()
        }
        g_object_unref(gpointer(lch))

        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_colourspace(adjusted, &out, VIPS_INTERPRETATION_sRGB) == 0, let out else {
            g_object_unref(gpointer(adjusted))
            throw VIPSError.fromVips()
        }
        g_object_unref(gpointer(adjusted))
        return VIPSImage(pointer: out)
    }

    /// Adjust gamma curve.
    public func adjustGamma(_ gamma: Double) throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_gamma(pointer, &out, 1.0 / gamma) == 0, let out else {
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: out)
    }

    /// Combined brightness, contrast, and saturation adjustment (more efficient).
    public func adjust(brightness: Double, contrast: Double, saturation: Double) throws -> VIPSImage {
        let offset = 127.5 * (1.0 - contrast) + brightness * 255.0
        let n = hasAlpha ? 3 : bands
        var a = [Double](repeating: contrast, count: n)
        var b = [Double](repeating: offset, count: n)

        var bcAdjusted: UnsafeMutablePointer<VipsImage>?
        guard cvips_linear(pointer, &bcAdjusted, &a, &b, Int32(n)) == 0, let bcAdjusted else {
            throw VIPSError.fromVips()
        }

        if abs(saturation - 1.0) < 0.001 {
            return VIPSImage(pointer: bcAdjusted)
        }

        var lch: UnsafeMutablePointer<VipsImage>?
        guard cvips_colourspace(bcAdjusted, &lch, VIPS_INTERPRETATION_LCH) == 0, let lch else {
            g_object_unref(gpointer(bcAdjusted))
            throw VIPSError.fromVips()
        }
        g_object_unref(gpointer(bcAdjusted))

        var sa: [Double] = [1.0, saturation, 1.0]
        var sb: [Double] = [0.0, 0.0, 0.0]
        var satAdjusted: UnsafeMutablePointer<VipsImage>?
        guard cvips_linear(lch, &satAdjusted, &sa, &sb, 3) == 0, let satAdjusted else {
            g_object_unref(gpointer(lch))
            throw VIPSError.fromVips()
        }
        g_object_unref(gpointer(lch))

        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_colourspace(satAdjusted, &out, VIPS_INTERPRETATION_sRGB) == 0, let out else {
            g_object_unref(gpointer(satAdjusted))
            throw VIPSError.fromVips()
        }
        g_object_unref(gpointer(satAdjusted))
        return VIPSImage(pointer: out)
    }
}
