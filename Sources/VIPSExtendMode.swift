/// How to extend the edges of an image when embedding or padding.
/// These correspond to the `VipsExtend` enum in libvips.
public enum VIPSExtendMode: Int, Sendable {
    /// Extend with black (zero) pixels
    case black = 0
    /// Copy the nearest edge pixel outward
    case copy
    /// Tile the image repeatedly
    case `repeat`
    /// Mirror the image at each edge
    case mirror
    /// Extend with white (max value) pixels
    case white
    /// Extend with a specified background color
    case background
}
