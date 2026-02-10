import Foundation
import CoreGraphics
internal import vips
internal import CVIPS

extension VIPSImage {

    /// Read the pixel values at the specified coordinate.
    /// Returns one value per band (e.g., 3-band `[R, G, B]` for an RGB image).
    /// - Parameters:
    ///   - x: The x-coordinate of the pixel (0-based)
    ///   - y: The y-coordinate of the pixel (0-based)
    /// - Returns: A ``VIPSColor`` containing one value per band
    public func pixelValues(atX x: Int, y: Int) throws -> VIPSColor {
        var vector: UnsafeMutablePointer<Double>?
        var n: Int32 = 0
        guard cvips_getpoint(pointer, &vector, &n, Int32(x), Int32(y)) == 0,
              let vector else {
            throw VIPSError.fromVips()
        }
        defer { g_free(vector) }
        return VIPSColor(values: Array(UnsafeBufferPointer(start: vector, count: Int(n))))
    }

    /// Read the pixel values at the specified point.
    /// - Parameter point: The pixel coordinate
    /// - Returns: A ``VIPSColor`` containing one value per band
    public func pixelValues(at point: CGPoint) throws -> VIPSColor {
        try pixelValues(atX: Int(point.x), y: Int(point.y))
    }
}
