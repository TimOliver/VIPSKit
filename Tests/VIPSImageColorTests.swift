import XCTest
@testable import VIPSKit

final class VIPSImageColorTests: VIPSImageTestCase {

    func testGrayscaled() throws {
        let image = createTestImage(width: 100, height: 100)
        let gray = try image.grayscaled()
        XCTAssertEqual(gray.width, 100)
        XCTAssertEqual(gray.bands, 1)
    }

    func testGrayscaledWithAlpha() throws {
        let image = createTestImage(width: 100, height: 100, bands: 4)
        let gray = try image.grayscaled()
        XCTAssertEqual(gray.width, 100)
    }

    func testFlatten() throws {
        let image = createTestImage(width: 100, height: 100, bands: 4)
        let flat = try image.flatten(background: .white)
        XCTAssertEqual(flat.width, 100)
        XCTAssertFalse(flat.hasAlpha)
    }

    func testInverted() throws {
        let image = createTestImage(width: 100, height: 100)
        let inverted = try image.inverted()
        XCTAssertEqual(inverted.width, image.width)
        XCTAssertEqual(inverted.height, image.height)
    }

    func testAdjustBrightness() throws {
        let image = createTestImage(width: 100, height: 100)
        let brighter = try image.adjustBrightness(0.2)
        XCTAssertEqual(brighter.width, 100)
        let darker = try image.adjustBrightness(-0.2)
        XCTAssertEqual(darker.width, 100)
    }

    func testAdjustContrast() throws {
        let image = createTestImage(width: 100, height: 100)
        let high = try image.adjustContrast(1.5)
        XCTAssertEqual(high.width, 100)
        let low = try image.adjustContrast(0.5)
        XCTAssertEqual(low.width, 100)
    }

    func testAdjustSaturation() throws {
        let image = createTestImage(width: 100, height: 100)
        let saturated = try image.adjustSaturation(1.5)
        XCTAssertEqual(saturated.width, 100)
        let desaturated = try image.adjustSaturation(0.0)
        XCTAssertEqual(desaturated.width, 100)
    }

    func testAdjustGamma() throws {
        let image = createTestImage(width: 100, height: 100)
        let corrected = try image.adjustGamma(2.2)
        XCTAssertEqual(corrected.width, 100)
    }

    func testCombinedAdjustment() throws {
        let image = createTestImage(width: 100, height: 100)
        let adjusted = try image.adjust(brightness: 0.1, contrast: 1.2, saturation: 1.1)
        XCTAssertEqual(adjusted.width, 100)
    }

    func testCombinedAdjustmentNoSaturation() throws {
        let image = createTestImage(width: 100, height: 100)
        let adjusted = try image.adjust(brightness: 0.1, contrast: 1.2, saturation: 1.0)
        XCTAssertEqual(adjusted.width, 100)
    }

    // MARK: - Async

    func testAsyncGrayscaled() async throws {
        let image = createTestImage(width: 100, height: 100)
        let gray = try await image.grayscaled()
        XCTAssertEqual(gray.width, 100)
        XCTAssertEqual(gray.bands, 1)
    }

    func testAsyncFlattened() async throws {
        let image = createTestImage(width: 100, height: 100, bands: 4)
        let flat = try await image.flattened(background: .white)
        XCTAssertEqual(flat.width, 100)
        XCTAssertFalse(flat.hasAlpha)
    }

    func testAsyncInverted() async throws {
        let image = createTestImage(width: 100, height: 100)
        let inverted = try await image.inverted()
        XCTAssertEqual(inverted.width, image.width)
        XCTAssertEqual(inverted.height, image.height)
    }

    func testAsyncAdjustedBrightness() async throws {
        let image = createTestImage(width: 100, height: 100)
        let brighter = try await image.adjustedBrightness(0.2)
        XCTAssertEqual(brighter.width, 100)
    }

    func testAsyncAdjustedContrast() async throws {
        let image = createTestImage(width: 100, height: 100)
        let high = try await image.adjustedContrast(1.5)
        XCTAssertEqual(high.width, 100)
    }

    func testAsyncAdjustedSaturation() async throws {
        let image = createTestImage(width: 100, height: 100)
        let saturated = try await image.adjustedSaturation(1.5)
        XCTAssertEqual(saturated.width, 100)
    }

    func testAsyncAdjustedGamma() async throws {
        let image = createTestImage(width: 100, height: 100)
        let corrected = try await image.adjustedGamma(2.2)
        XCTAssertEqual(corrected.width, 100)
    }

    func testAsyncAdjusted() async throws {
        let image = createTestImage(width: 100, height: 100)
        let adjusted = try await image.adjusted(brightness: 0.1, contrast: 1.2, saturation: 1.1)
        XCTAssertEqual(adjusted.width, 100)
    }
}
