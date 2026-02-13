import XCTest
import CoreGraphics
@testable import VIPSKit

final class VIPSColorTests: XCTestCase {

    // MARK: - Initialization

    func testInitWithRGB() {
        let color = VIPSColor(red: 128, green: 64, blue: 32)
        XCTAssertEqual(color.values, [128.0, 64.0, 32.0])
        XCTAssertEqual(color.count, 3)
    }

    func testInitWithValues() {
        let color = VIPSColor(values: [10.0, 20.0, 30.0, 40.0])
        XCTAssertEqual(color.values, [10.0, 20.0, 30.0, 40.0])
        XCTAssertEqual(color.count, 4)
    }

    func testInitWithSingleBandValues() {
        let color = VIPSColor(values: [128.0])
        XCTAssertEqual(color.count, 1)
        XCTAssertEqual(color.red, 128.0)
    }

    // MARK: - Component Accessors

    func testRGBAccessors() {
        let color = VIPSColor(red: 100, green: 150, blue: 200)
        XCTAssertEqual(color.red, 100.0)
        XCTAssertEqual(color.green, 150.0)
        XCTAssertEqual(color.blue, 200.0)
    }

    func testAlphaPresent() {
        let color = VIPSColor(values: [255.0, 128.0, 64.0, 200.0])
        XCTAssertEqual(color.alpha, 200.0)
    }

    func testAlphaAbsent() {
        let color = VIPSColor(red: 255, green: 128, blue: 64)
        XCTAssertNil(color.alpha)
    }

    func testSingleBandAccessors() {
        let color = VIPSColor(values: [100.0])
        // For 1-band, green and blue return the same value as red
        XCTAssertEqual(color.red, 100.0)
        XCTAssertEqual(color.green, 100.0)
        XCTAssertEqual(color.blue, 100.0)
        XCTAssertNil(color.alpha)
    }

    // MARK: - Constants

    func testWhite() {
        XCTAssertEqual(VIPSColor.white.red, 255.0)
        XCTAssertEqual(VIPSColor.white.green, 255.0)
        XCTAssertEqual(VIPSColor.white.blue, 255.0)
        XCTAssertNil(VIPSColor.white.alpha)
    }

    func testBlack() {
        XCTAssertEqual(VIPSColor.black.red, 0.0)
        XCTAssertEqual(VIPSColor.black.green, 0.0)
        XCTAssertEqual(VIPSColor.black.blue, 0.0)
        XCTAssertNil(VIPSColor.black.alpha)
    }

    // MARK: - Equatable

    func testEqualColors() {
        let a = VIPSColor(red: 10, green: 20, blue: 30)
        let b = VIPSColor(red: 10, green: 20, blue: 30)
        XCTAssertEqual(a, b)
    }

    func testUnequalColors() {
        let a = VIPSColor(red: 10, green: 20, blue: 30)
        let b = VIPSColor(red: 10, green: 20, blue: 31)
        XCTAssertNotEqual(a, b)
    }

    func testUnequalBandCount() {
        let rgb = VIPSColor(values: [100.0, 100.0, 100.0])
        let rgba = VIPSColor(values: [100.0, 100.0, 100.0, 255.0])
        XCTAssertNotEqual(rgb, rgba)
    }

    // MARK: - RandomAccessCollection

    func testCollectionCount() {
        let color = VIPSColor(red: 1, green: 2, blue: 3)
        XCTAssertEqual(color.count, 3)
    }

    func testCollectionIndices() {
        let color = VIPSColor(values: [10.0, 20.0, 30.0, 40.0])
        XCTAssertEqual(color.startIndex, 0)
        XCTAssertEqual(color.endIndex, 4)
    }

    func testSubscript() {
        let color = VIPSColor(red: 50, green: 100, blue: 150)
        XCTAssertEqual(color[0], 50.0)
        XCTAssertEqual(color[1], 100.0)
        XCTAssertEqual(color[2], 150.0)
    }

    func testIteration() {
        let color = VIPSColor(red: 10, green: 20, blue: 30)
        let collected = Array(color)
        XCTAssertEqual(collected, [10.0, 20.0, 30.0])
    }

    func testMapOverBands() {
        let color = VIPSColor(values: [100.0, 200.0, 50.0])
        let doubled = color.map { $0 * 2 }
        XCTAssertEqual(doubled, [200.0, 400.0, 100.0])
    }

    // MARK: - CGColor Interop

    func testInitFromCGColor() {
        let cgColor = CGColor(srgbRed: 1.0, green: 0.5, blue: 0.0, alpha: 1.0)
        let color = VIPSColor(cgColor: cgColor)
        XCTAssertNotNil(color)
        XCTAssertEqual(color!.red, 255.0, accuracy: 0.5)
        XCTAssertEqual(color!.green, 127.5, accuracy: 0.5)
        XCTAssertEqual(color!.blue, 0.0, accuracy: 0.5)
        // Fully opaque → no alpha band
        XCTAssertNil(color!.alpha)
    }

    func testInitFromCGColorWithAlpha() {
        let cgColor = CGColor(srgbRed: 0.0, green: 1.0, blue: 0.0, alpha: 0.5)
        let color = VIPSColor(cgColor: cgColor)
        XCTAssertNotNil(color)
        XCTAssertEqual(color!.count, 4)
        XCTAssertEqual(color!.green, 255.0, accuracy: 0.5)
        XCTAssertEqual(color!.alpha!, 127.5, accuracy: 0.5)
    }

    func testInitFromInvalidCGColor() {
        // A grayscale CGColor with only 2 components (gray + alpha) — < 3 RGB components
        let graySpace = CGColorSpace(name: CGColorSpace.genericGrayGamma2_2)!
        let cgColor = CGColor(colorSpace: graySpace, components: [0.5, 1.0])!
        let color = VIPSColor(cgColor: cgColor)
        // Grayscale CGColor can't convert to sRGB with 3+ components
        // Behavior may vary by platform, so just verify it doesn't crash
        _ = color
    }

    func testToCGColor() {
        let color = VIPSColor(red: 255, green: 0, blue: 128)
        let cgColor = color.cgColor
        let components = cgColor.components!
        XCTAssertEqual(components[0], 1.0, accuracy: 0.01) // red
        XCTAssertEqual(components[1], 0.0, accuracy: 0.01) // green
        XCTAssertEqual(components[2], 128.0 / 255.0, accuracy: 0.01) // blue
        XCTAssertEqual(components[3], 1.0, accuracy: 0.01) // alpha (opaque)
    }

    func testToCGColorWithAlpha() {
        let color = VIPSColor(values: [255.0, 0.0, 0.0, 127.5])
        let cgColor = color.cgColor
        let components = cgColor.components!
        XCTAssertEqual(components[3], 0.5, accuracy: 0.01)
    }

    func testCGColorRoundTrip() {
        let original = VIPSColor(red: 64, green: 128, blue: 192)
        let cgColor = original.cgColor
        let restored = VIPSColor(cgColor: cgColor)
        XCTAssertNotNil(restored)
        XCTAssertEqual(restored!.red, 64.0, accuracy: 1.0)
        XCTAssertEqual(restored!.green, 128.0, accuracy: 1.0)
        XCTAssertEqual(restored!.blue, 192.0, accuracy: 1.0)
    }

    // MARK: - Platform Color Interop

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    func testNSColorRoundTrip() {
        let original = VIPSColor(red: 100, green: 150, blue: 200)
        let nsColor = original.nsColor
        let restored = VIPSColor(nsColor: nsColor)
        XCTAssertNotNil(restored)
        XCTAssertEqual(restored!.red, 100.0, accuracy: 1.0)
        XCTAssertEqual(restored!.green, 150.0, accuracy: 1.0)
        XCTAssertEqual(restored!.blue, 200.0, accuracy: 1.0)
    }
    #endif

    #if canImport(UIKit)
    func testUIColorRoundTrip() {
        let original = VIPSColor(red: 100, green: 150, blue: 200)
        let uiColor = original.uiColor
        let restored = VIPSColor(uiColor: uiColor)
        XCTAssertNotNil(restored)
        XCTAssertEqual(restored!.red, 100.0, accuracy: 1.0)
        XCTAssertEqual(restored!.green, 150.0, accuracy: 1.0)
        XCTAssertEqual(restored!.blue, 200.0, accuracy: 1.0)
    }
    #endif

    // MARK: - Ink Conversion

    func testInkFor1Band() {
        let color = VIPSColor(red: 100, green: 200, blue: 50)
        let ink = color.ink(forBands: 1)
        XCTAssertEqual(ink.count, 1)
        // Luminance: 0.2126*100 + 0.7152*200 + 0.0722*50
        let expected = 0.2126 * 100.0 + 0.7152 * 200.0 + 0.0722 * 50.0
        XCTAssertEqual(ink[0], expected, accuracy: 0.01)
    }

    func testInkFor3Bands() {
        let color = VIPSColor(red: 10, green: 20, blue: 30)
        let ink = color.ink(forBands: 3)
        XCTAssertEqual(ink, [10.0, 20.0, 30.0])
    }

    func testInkFor4Bands() {
        let color = VIPSColor(red: 10, green: 20, blue: 30)
        let ink = color.ink(forBands: 4)
        XCTAssertEqual(ink, [10.0, 20.0, 30.0, 255.0])
    }

    // MARK: - Debug Description

    func testDebugDescription() {
        let color = VIPSColor(red: 255, green: 128, blue: 0)
        let desc = color.debugDescription
        XCTAssertTrue(desc.contains("255.0"))
        XCTAssertTrue(desc.contains("128.0"))
        XCTAssertTrue(desc.contains("0.0"))
        XCTAssertTrue(desc.hasPrefix("<VIPSColor:"))
    }

    func testDebugDescriptionWithAlpha() {
        let color = VIPSColor(values: [100.0, 200.0, 50.0, 128.0])
        let desc = color.debugDescription
        XCTAssertTrue(desc.contains("128.0"))
    }

    // MARK: - Edge Cases

    func testEmptyValues() {
        let color = VIPSColor(values: [])
        XCTAssertEqual(color.count, 0)
    }

    func testTwoBandColor() {
        let color = VIPSColor(values: [100.0, 200.0])
        XCTAssertEqual(color.count, 2)
        XCTAssertEqual(color.red, 100.0)
        // With < 3 bands, green and blue return first band
        XCTAssertEqual(color.green, 100.0)
        XCTAssertNil(color.alpha)
    }

    func testBoundaryValues() {
        let color = VIPSColor(red: 0, green: 0, blue: 0)
        XCTAssertEqual(color.red, 0.0)
        let color2 = VIPSColor(red: 255, green: 255, blue: 255)
        XCTAssertEqual(color2.red, 255.0)
    }

    // MARK: - CGColor Edge Cases

    func testCGColorFromBlack() {
        let color = VIPSColor.black
        let cg = color.cgColor
        let components = cg.components!
        XCTAssertEqual(components[0], 0.0, accuracy: 0.01)
        XCTAssertEqual(components[1], 0.0, accuracy: 0.01)
        XCTAssertEqual(components[2], 0.0, accuracy: 0.01)
        XCTAssertEqual(components[3], 1.0, accuracy: 0.01)
    }

    func testCGColorFromWhite() {
        let color = VIPSColor.white
        let cg = color.cgColor
        let components = cg.components!
        XCTAssertEqual(components[0], 1.0, accuracy: 0.01)
        XCTAssertEqual(components[1], 1.0, accuracy: 0.01)
        XCTAssertEqual(components[2], 1.0, accuracy: 0.01)
    }

    func testCGColorRoundTripWithAlpha() {
        let original = VIPSColor(values: [128.0, 64.0, 32.0, 127.5])
        let cg = original.cgColor
        let restored = VIPSColor(cgColor: cg)
        XCTAssertNotNil(restored)
        XCTAssertEqual(restored!.red, 128.0, accuracy: 1.0)
        XCTAssertEqual(restored!.green, 64.0, accuracy: 1.0)
        XCTAssertEqual(restored!.blue, 32.0, accuracy: 1.0)
        XCTAssertNotNil(restored!.alpha)
        XCTAssertEqual(restored!.alpha!, 127.5, accuracy: 1.0)
    }

    // MARK: - Sendable

    func testSendable() async {
        let color = VIPSColor(red: 42, green: 128, blue: 200)
        let result = await Task.detached {
            return color.red
        }.value
        XCTAssertEqual(result, 42.0)
    }
}
