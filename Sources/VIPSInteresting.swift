/// Strategies for selecting the most interesting region when performing a smart crop.
/// Used by ``VIPSImage/smartCrop(toWidth:height:interesting:)`` to determine
/// which part of the image to keep.
public enum VIPSInteresting: Int, Sendable {
    /// Don't look for interesting areas; crop from the default position
    case none = 0
    /// Crop from the center of the image
    case centre
    /// Crop to maximize entropy (keeps the most detailed region)
    case entropy
    /// Use attention strategy to detect edges, skin tones, and saturated colors
    case attention
    /// Crop from the low (top-left) coordinate
    case low
    /// Crop from the high (bottom-right) coordinate
    case high
}
