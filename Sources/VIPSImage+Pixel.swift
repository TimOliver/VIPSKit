import Foundation
internal import vips
internal import CVIPS

extension VIPSImage {

    /// Read the pixel values at the specified coordinate.
    /// Returns one value per band (e.g., `[R, G, B]` for an RGB image).
    /// - Parameters:
    ///   - x: The x-coordinate of the pixel (0-based)
    ///   - y: The y-coordinate of the pixel (0-based)
    /// - Returns: An array of band values as `Double`
    public func pixelValues(atX x: Int, y: Int) throws -> [Double] {
        var vector: UnsafeMutablePointer<Double>?
        var n: Int32 = 0
        guard cvips_getpoint(pointer, &vector, &n, Int32(x), Int32(y)) == 0,
              let vector else {
            throw VIPSError.fromVips()
        }
        defer { g_free(vector) }
        return Array(UnsafeBufferPointer(start: vector, count: Int(n)))
    }
}
