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
    /// For an RGB image, this returns a 3-band color `[R, G, B]`. For RGBA, `[R, G, B, A]`.
    /// - Returns: A ``VIPSColor`` containing the mean value for each band
    public func averageColor() throws -> VIPSColor {
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
        let statsWidth = Int(vips_image_get_width(statsImage))
        var result: [Double] = []
        for band in 1...numBands {
            result.append(data[4 + (statsWidth * band)])
        }
        return VIPSColor(values: result)
    }

    /// Detect the background color of the image.
    ///
    /// Uses a two-step approach:
    /// 1. Attempts ``findTrim(threshold:background:)`` to locate content margins.
    ///    If margins exist, samples from those margin areas for an accurate background color.
    /// 2. If no margins are found (content fills to all edges), identifies the most
    ///    prominent color along the image edges by quantizing pixels into color buckets
    ///    and selecting the most frequent one.
    ///
    /// - Parameter stripWidth: The width of the edge strip to sample in pixels (default is 10).
    ///   Used in step 2 when no trim margins are found.
    /// - Returns: A ``VIPSColor`` representing the detected background color
    public func detectBackgroundColor(stripWidth: Int = 10) throws -> VIPSColor {
        let sw = max(1, stripWidth)

        if width <= sw * 2 || height <= sw * 2 {
            return try averageColor()
        }

        // Step 1: Use findTrim to detect margin areas
        if let color = try? backgroundColorFromTrim() {
            return color
        }

        // Step 2: Find the most prominent color along edges
        return try prominentEdgeColor(stripWidth: sw)
    }

    /// Sample from margin areas identified by findTrim.
    /// Returns nil if there are no margins (content fills to all edges).
    private func backgroundColorFromTrim() throws -> VIPSColor? {
        let trimRect = try findTrim()
        guard !trimRect.isEmpty else { return nil }

        let w = width
        let h = height
        let numBands = bands
        let tx = Int(trimRect.origin.x)
        let ty = Int(trimRect.origin.y)
        let tw = Int(trimRect.width)
        let th = Int(trimRect.height)

        // Bail if the trim rect spans the full image (no margins)
        guard tx > 0 || ty > 0 || (tx + tw) < w || (ty + th) < h else { return nil }

        var weightedSum = [Double](repeating: 0, count: numBands)
        var totalPixels = 0

        // Top margin
        if ty > 0 {
            let avg = try crop(x: 0, y: 0, width: w, height: ty).averageColor()
            let count = w * ty
            for i in 0..<min(avg.count, numBands) { weightedSum[i] += avg[i] * Double(count) }
            totalPixels += count
        }

        // Bottom margin
        let bottomStart = ty + th
        if bottomStart < h {
            let bottomH = h - bottomStart
            let avg = try crop(x: 0, y: bottomStart, width: w, height: bottomH).averageColor()
            let count = w * bottomH
            for i in 0..<min(avg.count, numBands) { weightedSum[i] += avg[i] * Double(count) }
            totalPixels += count
        }

        // Left margin (between top and bottom to avoid double-counting corners)
        if tx > 0 && th > 0 {
            let avg = try crop(x: 0, y: ty, width: tx, height: th).averageColor()
            let count = tx * th
            for i in 0..<min(avg.count, numBands) { weightedSum[i] += avg[i] * Double(count) }
            totalPixels += count
        }

        // Right margin
        let rightStart = tx + tw
        if rightStart < w && th > 0 {
            let rightW = w - rightStart
            let avg = try crop(x: rightStart, y: ty, width: rightW, height: th).averageColor()
            let count = rightW * th
            for i in 0..<min(avg.count, numBands) { weightedSum[i] += avg[i] * Double(count) }
            totalPixels += count
        }

        guard totalPixels > 0 else { return nil }
        return VIPSColor(values: weightedSum.map { $0 / Double(totalPixels) })
    }

    /// Find the most prominent color along the image edges by quantizing pixels
    /// into color buckets and returning the average color of the most frequent bucket.
    private func prominentEdgeColor(stripWidth sw: Int) throws -> VIPSColor {
        let w = width
        let h = height
        let numBands = bands
        let step = 32
        let levels = (255 / step) + 1

        // Collect edge strips
        var strips = [VIPSImage]()
        strips.append(try crop(x: 0, y: 0, width: w, height: sw))
        strips.append(try crop(x: 0, y: h - sw, width: w, height: sw))
        if h > sw * 2 {
            strips.append(try crop(x: 0, y: sw, width: sw, height: h - 2 * sw))
            strips.append(try crop(x: w - sw, y: sw, width: sw, height: h - 2 * sw))
        }

        // Count quantized color occurrences and accumulate actual values
        var bucketCounts = [Int: Int]()
        var bucketSums = [Int: [Double]]()

        for strip in strips {
            try strip.withPixelData { buffer in
                for y in 0..<buffer.height {
                    let rowBase = y * buffer.bytesPerRow
                    for x in 0..<buffer.width {
                        let offset = rowBase + x * numBands

                        // Quantize on up to 3 bands (RGB) to build a bucket key
                        var key = 0
                        for b in 0..<min(numBands, 3) {
                            key = key * levels + Int(buffer.data[offset + b]) / step
                        }

                        bucketCounts[key, default: 0] += 1
                        if bucketSums[key] == nil {
                            bucketSums[key] = [Double](repeating: 0, count: numBands)
                        }
                        for b in 0..<numBands {
                            bucketSums[key]![b] += Double(buffer.data[offset + b])
                        }
                    }
                }
            }
        }

        guard let (topKey, topCount) = bucketCounts.max(by: { $0.value < $1.value }),
              topCount > 0,
              let sums = bucketSums[topKey] else {
            return try averageColor()
        }

        return VIPSColor(values: sums.map { $0 / Double(topCount) })
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
