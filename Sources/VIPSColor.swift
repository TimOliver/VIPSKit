/// A color representation for use with VIPSKit operations.
/// Stores per-band values as `Double` for full precision. Supports variable band counts
/// (1-band grayscale, 3-band RGB, 4-band RGBA).
public struct VIPSColor: Sendable, Equatable {
    /// The raw per-band values (0.0–255.0 range for 8-bit images).
    public let values: [Double]

    /// The red component, or the single luminance value for 1-band images.
    public var red: Double { values[0] }
    /// The green component. For 1-band images, returns the luminance value.
    public var green: Double { values[count >= 3 ? 1 : 0] }
    /// The blue component. For 1-band images, returns the luminance value.
    public var blue: Double { values[count >= 3 ? 2 : 0] }
    /// The alpha component, if present.
    public var alpha: Double? { count >= 4 ? values[3] : nil }

    /// Create a color with the given red, green, and blue components.
    public init(red: UInt8, green: UInt8, blue: UInt8) {
        self.values = [Double(red), Double(green), Double(blue)]
    }

    /// Create a color from per-band values.
    /// - Parameter values: An array of band values (typically 0.0–255.0 for 8-bit images)
    public init(values: [Double]) {
        self.values = values
    }

    /// Pure white.
    public static let white = VIPSColor(red: 255, green: 255, blue: 255)
    /// Pure black.
    public static let black = VIPSColor(red: 0, green: 0, blue: 0)

    /// Build an ink array matching the given band count.
    internal func ink(forBands bands: Int) -> [Double] {
        switch bands {
        case 1:
            let luma = 0.2126 * red + 0.7152 * green + 0.0722 * blue
            return [luma]
        case 4:
            return [red, green, blue, 255.0]
        default:
            return [red, green, blue]
        }
    }
}

extension VIPSColor: RandomAccessCollection {
    public var startIndex: Int { 0 }
    public var endIndex: Int { values.count }
    public subscript(position: Int) -> Double { values[position] }
}
