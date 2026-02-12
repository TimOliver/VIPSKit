import CoreGraphics

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

// MARK: - CGColor Interop

extension VIPSColor {

    /// Create a VIPSColor from a CGColor, converting to sRGB.
    /// Returns nil if the color cannot be converted to the sRGB color space.
    public init?(cgColor: CGColor) {
        guard let srgb = CGColorSpace(name: CGColorSpace.sRGB),
              let converted = cgColor.converted(to: srgb, intent: .defaultIntent, options: nil),
              let components = converted.components,
              components.count >= 3 else {
            return nil
        }
        let r = components[0] * 255.0
        let g = components[1] * 255.0
        let b = components[2] * 255.0
        let a = components.count >= 4 ? components[3] : 1.0
        if a < 1.0 {
            self.init(values: [r, g, b, a * 255.0])
        } else {
            self.init(values: [r, g, b])
        }
    }

    /// The color as a CGColor in the sRGB color space.
    public var cgColor: CGColor {
        let a = alpha ?? 255.0
        return CGColor(srgbRed: red / 255.0,
                       green: green / 255.0,
                       blue: blue / 255.0,
                       alpha: a / 255.0)
    }
}

// MARK: - UIColor Interop

#if canImport(UIKit)
import UIKit

extension VIPSColor {

    /// Create a VIPSColor from a UIColor.
    /// Returns nil if the color cannot be converted to sRGB.
    public init?(uiColor: UIColor) {
        self.init(cgColor: uiColor.cgColor)
    }

    /// The color as a UIColor.
    public var uiColor: UIColor {
        UIColor(cgColor: cgColor)
    }
}
#endif

// MARK: - NSColor Interop

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

extension VIPSColor {

    /// Create a VIPSColor from an NSColor.
    /// Returns nil if the color cannot be converted to sRGB.
    public init?(nsColor: NSColor) {
        self.init(cgColor: nsColor.cgColor)
    }

    /// The color as an NSColor.
    public var nsColor: NSColor {
        NSColor(cgColor: cgColor)!
    }
}
#endif

// MARK: - Debug Description

extension VIPSColor: CustomDebugStringConvertible {
    public var debugDescription: String {
        let components = values.map { String(format: "%.1f", $0) }.joined(separator: ", ")
        return "<VIPSColor: (\(components))>"
    }
}

// MARK: - RandomAccessCollection

extension VIPSColor: RandomAccessCollection {
    public var startIndex: Int { 0 }
    public var endIndex: Int { values.count }
    public subscript(position: Int) -> Double { values[position] }
}
