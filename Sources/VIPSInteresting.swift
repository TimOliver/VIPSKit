/// Smart crop strategy for finding interesting regions.
public enum VIPSInteresting: Int, Sendable {
    /// Don't look for interesting areas
    case none = 0
    /// Crop from center
    case centre
    /// Crop to maximize entropy
    case entropy
    /// Crop using attention strategy (edges, skin tones, saturated colors)
    case attention
    /// Crop from low coordinate
    case low
    /// Crop from high coordinate
    case high
}
