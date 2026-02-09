internal import vips

/// Compass directions for positioning an image within a larger canvas.
/// These correspond to the `VipsCompassDirection` enum in libvips.
public enum VIPSCompassDirection: Int, Sendable {
    /// Center the image
    case centre = 0
    /// Align to the top (north) edge
    case north
    /// Align to the right (east) edge
    case east
    /// Align to the bottom (south) edge
    case south
    /// Align to the left (west) edge
    case west
    /// Align to the top-right corner
    case northEast
    /// Align to the bottom-right corner
    case southEast
    /// Align to the bottom-left corner
    case southWest
    /// Align to the top-left corner
    case northWest

    /// The corresponding libvips `VipsCompassDirection` value.
    internal var vipsValue: VipsCompassDirection {
        VipsCompassDirection(rawValue: UInt32(rawValue))
    }
}
