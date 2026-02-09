import Foundation
import CoreGraphics
internal import vips
internal import CVIPS

extension VIPSImage {

    // MARK: - Analysis

    /// Find the bounding box of non-background pixels (trim margins).
    public func findTrim(threshold: Double = 10.0, background: [Double]? = nil) throws -> CGRect {
        var left: Int32 = 0, top: Int32 = 0, width: Int32 = 0, height: Int32 = 0
        let result: Int32

        if var bg = background, !bg.isEmpty {
            result = cvips_find_trim_bg(pointer, &left, &top, &width, &height,
                                        threshold, &bg, Int32(bg.count))
        } else {
            result = cvips_find_trim(pointer, &left, &top, &width, &height, threshold)
        }

        guard result == 0 else { throw VIPSError.fromVips() }
        return CGRect(x: Int(left), y: Int(top), width: Int(width), height: Int(height))
    }

    /// Get image statistics (min, max, mean, standard deviation).
    public func statistics() throws -> VIPSImageStatistics {
        var min: Double = 0, max: Double = 0, mean: Double = 0, stddev: Double = 0
        guard cvips_min(pointer, &min) == 0 else { throw VIPSError.fromVips() }
        guard cvips_max(pointer, &max) == 0 else { throw VIPSError.fromVips() }
        guard cvips_avg(pointer, &mean) == 0 else { throw VIPSError.fromVips() }
        guard cvips_deviate(pointer, &stddev) == 0 else { throw VIPSError.fromVips() }
        return VIPSImageStatistics(min: min, max: max, mean: mean, standardDeviation: stddev)
    }

    /// Get the average color of the image as per-band mean values.
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

    /// Detect the background color by sampling edges.
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

    /// Subtract another image from this image (pixel-wise: self - other).
    public func subtract(_ other: VIPSImage) throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_subtract(pointer, other.pointer, &out) == 0, let out else {
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: out)
    }

    /// Compute absolute value of each pixel.
    public func absolute() throws -> VIPSImage {
        var out: UnsafeMutablePointer<VipsImage>?
        guard cvips_abs(pointer, &out) == 0, let out else {
            throw VIPSError.fromVips()
        }
        return VIPSImage(pointer: out)
    }
}
