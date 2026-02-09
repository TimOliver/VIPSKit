import Foundation
internal import vips
internal import CVIPS

extension VIPSImage {

    /// Convert the image to grayscale (single-band luminance).
    /// - Returns: A new grayscale image
    public func grayscale() throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_colourspace(pointer, &out, VIPS_INTERPRETATION_B_W) == 0, let out else {
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: out)
    }

    /// Flatten the alpha channel against a solid background color.
    /// Fully transparent pixels become the background color, and semi-transparent
    /// pixels are blended accordingly.
    /// - Parameters:
    ///   - red: The red component of the background color (0-255)
    ///   - green: The green component of the background color (0-255)
    ///   - blue: The blue component of the background color (0-255)
    /// - Returns: A new image with the alpha channel removed
    public func flatten(red: Int, green: Int, blue: Int) throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_flatten(pointer, &out, Double(red), Double(green), Double(blue)) == 0,
              let out else { throw VIPSError.fromVips() }
        return VIPSImage(pointer: out)
    }

    /// Invert the colors of the image, producing a photographic negative effect.
    /// - Returns: A new image with inverted colors
    public func invert() throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_invert(pointer, &out) == 0, let out else {
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: out)
    }

    /// Adjust the brightness of the image by applying a uniform offset to all color channels.
    /// - Parameter brightness: The brightness adjustment value (-1.0 to 1.0, where 0 is unchanged)
    /// - Returns: A new image with adjusted brightness
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

    /// Adjust the contrast of the image by scaling pixel values around the midpoint.
    /// - Parameter contrast: The contrast multiplier (0.5 to 2.0, where 1.0 is unchanged)
    /// - Returns: A new image with adjusted contrast
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

    /// Adjust the color saturation by converting to LCH color space and scaling the chroma channel.
    /// - Parameter saturation: The saturation multiplier (0 = grayscale, 1.0 = unchanged, >1.0 = more saturated)
    /// - Returns: A new image with adjusted saturation
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

    /// Adjust the gamma curve of the image. Values less than 1.0 lighten
    /// the image, while values greater than 1.0 darken it.
    /// - Parameter gamma: The gamma exponent value
    /// - Returns: A new image with the adjusted gamma curve
    public func adjustGamma(_ gamma: Double) throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_gamma(pointer, &out, 1.0 / gamma) == 0, let out else {
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: out)
    }

    /// Apply brightness, contrast, and saturation adjustments in a single
    /// efficient operation. This is faster than applying each adjustment separately.
    /// - Parameters:
    ///   - brightness: The brightness adjustment (-1.0 to 1.0, where 0 is unchanged)
    ///   - contrast: The contrast multiplier (0.5 to 2.0, where 1.0 is unchanged)
    ///   - saturation: The saturation multiplier (0 = grayscale, 1.0 = unchanged, >1.0 = more saturated)
    /// - Returns: A new image with all three adjustments applied
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
