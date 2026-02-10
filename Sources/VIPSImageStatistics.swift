/// Statistical measurements computed across all bands of an image,
/// including the minimum, maximum, mean, and standard deviation of pixel values.
public struct VIPSImageStatistics: Sendable {
    /// The minimum pixel value across all bands
    public let min: Double
    /// The maximum pixel value across all bands
    public let max: Double
    /// The mean (average) pixel value across all bands
    public let mean: Double
    /// The standard deviation of pixel values across all bands
    public let standardDeviation: Double
}
