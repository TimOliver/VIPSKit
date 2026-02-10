import XCTest
@testable import VIPSKit

final class VIPSImageCompositeTests: VIPSImageTestCase {

    func testCompositeAtPosition() throws {
        let base = createTestImage(width: 200, height: 200, bands: 4)
        let overlay = createSolidColorImage(width: 50, height: 50, r: 255, g: 0, b: 0, a: 128)
        let result = try base.composite(withOverlay: overlay, mode: .over, x: 10, y: 10)
        XCTAssertEqual(result.width, 200)
        XCTAssertEqual(result.height, 200)
    }

    func testCompositeCentered() throws {
        let base = createTestImage(width: 200, height: 200, bands: 4)
        let overlay = createSolidColorImage(width: 50, height: 50, r: 0, g: 255, b: 0, a: 128)
        let result = try base.composite(withOverlay: overlay, mode: .over)
        XCTAssertEqual(result.width, 200)
        XCTAssertEqual(result.height, 200)
    }

    func testBlendModeMultiply() throws {
        let base = createTestImage(width: 100, height: 100, bands: 4)
        let overlay = createSolidColorImage(width: 100, height: 100, r: 128, g: 128, b: 128, a: 255)
        let result = try base.composite(withOverlay: overlay, mode: .multiply, x: 0, y: 0)
        XCTAssertEqual(result.width, 100)
    }

    func testBlendModeScreen() throws {
        let base = createTestImage(width: 100, height: 100, bands: 4)
        let overlay = createSolidColorImage(width: 100, height: 100, r: 128, g: 128, b: 128, a: 255)
        let result = try base.composite(withOverlay: overlay, mode: .screen, x: 0, y: 0)
        XCTAssertEqual(result.width, 100)
    }

    func testBlendModeAdd() throws {
        let base = createTestImage(width: 100, height: 100, bands: 4)
        let overlay = createSolidColorImage(width: 100, height: 100, r: 50, g: 50, b: 50, a: 255)
        let result = try base.composite(withOverlay: overlay, mode: .add, x: 0, y: 0)
        XCTAssertEqual(result.width, 100)
    }

    func testBlendModeDifference() throws {
        let base = createTestImage(width: 100, height: 100, bands: 4)
        let overlay = createSolidColorImage(width: 100, height: 100, r: 100, g: 100, b: 100, a: 255)
        let result = try base.composite(withOverlay: overlay, mode: .difference, x: 0, y: 0)
        XCTAssertEqual(result.width, 100)
    }

    func testCompositeExport() throws {
        let base = createTestImage(width: 100, height: 100, bands: 4)
        let overlay = createSolidColorImage(width: 50, height: 50, r: 255, g: 0, b: 0, a: 200)
        let composited = try base.composite(withOverlay: overlay, mode: .over, x: 25, y: 25)
        let data = try composited.data(format: .png)
        XCTAssertGreaterThan(data.count, 0)
    }

    // MARK: - Async

    func testAsyncCompositedAtPosition() async throws {
        let base = createTestImage(width: 200, height: 200, bands: 4)
        let overlay = createSolidColorImage(width: 50, height: 50, r: 255, g: 0, b: 0, a: 128)
        let result = try await base.composited(withOverlay: overlay, mode: .over, x: 10, y: 10)
        XCTAssertEqual(result.width, 200)
        XCTAssertEqual(result.height, 200)
    }

    func testAsyncCompositedAtPoint() async throws {
        let base = createTestImage(width: 200, height: 200, bands: 4)
        let overlay = createSolidColorImage(width: 50, height: 50, r: 255, g: 0, b: 0, a: 128)
        let result = try await base.composited(withOverlay: overlay, mode: .over, at: CGPoint(x: 10, y: 10))
        XCTAssertEqual(result.width, 200)
        XCTAssertEqual(result.height, 200)
    }

    func testAsyncCompositedCentered() async throws {
        let base = createTestImage(width: 200, height: 200, bands: 4)
        let overlay = createSolidColorImage(width: 50, height: 50, r: 0, g: 255, b: 0, a: 128)
        let result = try await base.composited(withOverlay: overlay, mode: .over)
        XCTAssertEqual(result.width, 200)
        XCTAssertEqual(result.height, 200)
    }
}
