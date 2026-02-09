import Foundation
import CoreGraphics
internal import vips
internal import CVIPS

extension VIPSImage {

    // MARK: - Analysis

    /// Find the bounding box of non-background pixels by detecting content margins.
    /// Useful for trimming whitespace or uniform borders from an image.
    /// - Parameters:
    ///   - threshold: How different a pixel must be from the background to count as
    ///     content (default is 10.0)
    ///   - background: An explicit background color. If `nil`, the background is auto-detected.
    /// - Returns: A rectangle describing the bounding box of the content area
    public func findTrim(threshold: Double = 10.0, background: VIPSColor? = nil) throws -> CGRect {
        var left: Int32 = 0, top: Int32 = 0, width: Int32 = 0, height: Int32 = 0
        let result: Int32

        if let background {
            var bg = background.ink(forBands: bands)
            result = cvips_find_trim_bg(pointer, &left, &top, &width, &height,
                                        threshold, &bg, Int32(bg.count))
        } else {
            result = cvips_find_trim(pointer, &left, &top, &width, &height, threshold)
        }

        guard result == 0 else { throw VIPSError.fromVips() }
        return CGRect(x: Int(left), y: Int(top), width: Int(width), height: Int(height))
    }

    /// Compute basic statistics across all bands of the image.
    /// - Returns: A ``VIPSImageStatistics`` value containing the min, max, mean, and standard deviation
    public func statistics() throws -> VIPSImageStatistics {
        var min: Double = 0, max: Double = 0, mean: Double = 0, stddev: Double = 0
        guard cvips_min(pointer, &min) == 0 else { throw VIPSError.fromVips() }
        guard cvips_max(pointer, &max) == 0 else { throw VIPSError.fromVips() }
        guard cvips_avg(pointer, &mean) == 0 else { throw VIPSError.fromVips() }
        guard cvips_deviate(pointer, &stddev) == 0 else { throw VIPSError.fromVips() }
        return VIPSImageStatistics(min: min, max: max, mean: mean, standardDeviation: stddev)
    }

    /// Calculate the average color of the image as per-band mean values.
    /// For an RGB image, this returns `[R, G, B]`. For RGBA, `[R, G, B, A]`.
    /// - Returns: An array of mean values, one per band
    public func averageColor() throws -> [Double] {
        var statsImage: UnsafeMutablePointer<VipsImage>?
        guard cvips_stats(pointer, &statsImage) == 0, let statsImage else {
            throw VIPSError.fromVips()
        }
        defer { g_object_unref(gpointer(statsImage)) }

        let numBands = Int(vips_image_get_bands(pointer))
        guard let pixel = vips_image_get_data(statsImage) else {
            throw VIPSError("Failed to read stats data")
        }

        let data = pixel.assumingMemoryBound(to: Double.self)
        let statsWidth = numBands + 1
        var result: [Double] = []
        for band in 1...numBands {
            result.append(data[4 * statsWidth + band])
        }
        return result
    }

    /// Detect the background color of the image by sampling pixels along all four edges.
    /// This is useful for setting a viewer background that matches the image's margins.
    /// - Parameter stripWidth: The width of the edge strip to sample in pixels (default is 10)
    /// - Returns: An array of mean color values from the edge pixels, one per band
    public func detectBackgroundColor(stripWidth: Int = 10) throws -> [Double] {
        let w = width
        let h = height
        let sw = max(1, stripWidth)

        if w <= sw * 2 || h <= sw * 2 {
            return try averageColor()
        }

        var topStrip: UnsafeMutablePointer<VipsImage>?
        guard cvips_crop(pointer, &topStrip, 0, 0, Int32(w), Int32(sw)) == 0,
              let topStrip else { throw VIPSError.fromVips() }

        var bottomStrip: UnsafeMutablePointer<VipsImage>?
        guard cvips_crop(pointer, &bottomStrip, 0, Int32(h - sw), Int32(w), Int32(sw)) == 0,
              let bottomStrip else {
            g_object_unref(gpointer(topStrip))
            throw VIPSError.fromVips()
        }

        var leftStrip: UnsafeMutablePointer<VipsImage>?
        guard cvips_crop(pointer, &leftStrip, 0, Int32(sw), Int32(sw), Int32(h - 2 * sw)) == 0,
              let leftStrip else {
            g_object_unref(gpointer(topStrip)); g_object_unref(gpointer(bottomStrip))
            throw VIPSError.fromVips()
        }

        var rightStrip: UnsafeMutablePointer<VipsImage>?
        guard cvips_crop(pointer, &rightStrip, Int32(w - sw), Int32(sw), Int32(sw), Int32(h - 2 * sw)) == 0,
              let rightStrip else {
            g_object_unref(gpointer(topStrip)); g_object_unref(gpointer(bottomStrip)); g_object_unref(gpointer(leftStrip))
            throw VIPSError.fromVips()
        }

        var horizontal: UnsafeMutablePointer<VipsImage>?
        guard cvips_join(topStrip, bottomStrip, &horizontal, VIPS_DIRECTION_VERTICAL) == 0,
              let horizontal else {
            g_object_unref(gpointer(topStrip)); g_object_unref(gpointer(bottomStrip))
            g_object_unref(gpointer(leftStrip)); g_object_unref(gpointer(rightStrip))
            throw VIPSError.fromVips()
        }
        g_object_unref(gpointer(topStrip)); g_object_unref(gpointer(bottomStrip))

        var vertical: UnsafeMutablePointer<VipsImage>?
        guard cvips_join(leftStrip, rightStrip, &vertical, VIPS_DIRECTION_VERTICAL) == 0,
              let vertical else {
            g_object_unref(gpointer(horizontal)); g_object_unref(gpointer(leftStrip)); g_object_unref(gpointer(rightStrip))
            throw VIPSError.fromVips()
        }
        g_object_unref(gpointer(leftStrip)); g_object_unref(gpointer(rightStrip))

        var combined: UnsafeMutablePointer<VipsImage>?
        guard cvips_join(horizontal, vertical, &combined, VIPS_DIRECTION_VERTICAL) == 0,
              let combined else {
            g_object_unref(gpointer(horizontal)); g_object_unref(gpointer(vertical))
            throw VIPSError.fromVips()
        }
        g_object_unref(gpointer(horizontal)); g_object_unref(gpointer(vertical))

        let wrapper = VIPSImage(pointer: combined)
        return try wrapper.averageColor()
    }

    // MARK: - Arithmetic

    /// Perform pixel-wise subtraction of another image from this image (`self - other`).
    /// Both images must have the same dimensions and number of bands.
    /// - Parameter other: The image to subtract
    /// - Returns: A new image containing the difference values
    public func subtract(_ other: VIPSImage) throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_subtract(pointer, other.pointer, &out) == 0, let out else {
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: out)
    }

    /// Compute the absolute value of each pixel. Useful after subtraction
    /// to get the magnitude of differences regardless of sign.
    /// - Returns: A new image with all pixel values made positive
    public func absolute() throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_abs(pointer, &out) == 0, let out else {
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: out)
    }
}
