/// A simple RGB color representation for use with VIPSKit operations.
public struct VIPSColor: Sendable {
    /// The red component (0–255).
    public let red: UInt8
    /// The green component (0–255).
    public let green: UInt8
    /// The blue component (0–255).
    public let blue: UInt8

    /// Create a color with the given red, green, and blue components.
    public init(red: UInt8, green: UInt8, blue: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    /// Pure white.
    public static let white = VIPSColor(red: 255, green: 255, blue: 255)
    /// Pure black.
    public static let black = VIPSColor(red: 0, green: 0, blue: 0)

    /// Build an ink array matching the given band count.
    /// For 1-band images, uses the luminance approximation.
    /// For 3-band images, returns `[R, G, B]`.
    /// For 4-band images, returns `[R, G, B, 255]` (fully opaque).
    internal func ink(forBands bands: Int) -> [Double] {
        switch bands {
        case 1:
            let luma = 0.2126 * Double(red) + 0.7152 * Double(green) + 0.0722 * Double(blue)
            return [luma]
        case 4:
            return [Double(red), Double(green), Double(blue), 255.0]
        default:
            return [Double(red), Double(green), Double(blue)]
        }
    }
}
