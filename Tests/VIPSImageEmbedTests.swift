import XCTest
@testable import VIPSKit

final class VIPSImageEmbedTests: VIPSImageTestCase {

    func testEmbedBasic() throws {
        let image = createTestImage(width: 50, height: 50)
        let embedded = try image.embed(x: 25, y: 25, width: 100, height: 100)
        XCTAssertEqual(embedded.width, 100)
        XCTAssertEqual(embedded.height, 100)
    }

    func testEmbedWithCopyExtend() throws {
        let image = createTestImage(width: 50, height: 50)
        let embedded = try image.embed(x: 25, y: 25, width: 100, height: 100, extend: .copy)
        XCTAssertEqual(embedded.width, 100)
        XCTAssertEqual(embedded.height, 100)
    }

    func testEmbedWithWhiteExtend() throws {
        let image = createTestImage(width: 50, height: 50)
        let embedded = try image.embed(x: 10, y: 10, width: 70, height: 70, extend: .white)
        XCTAssertEqual(embedded.width, 70)
        XCTAssertEqual(embedded.height, 70)
    }

    func testEmbedWithMirrorExtend() throws {
        let image = createTestImage(width: 50, height: 50)
        let embedded = try image.embed(x: 25, y: 25, width: 100, height: 100, extend: .mirror)
        XCTAssertEqual(embedded.width, 100)
        XCTAssertEqual(embedded.height, 100)
    }

    func testGravityCentre() throws {
        let image = createTestImage(width: 50, height: 50)
        let result = try image.gravity(direction: .centre, width: 100, height: 100)
        XCTAssertEqual(result.width, 100)
        XCTAssertEqual(result.height, 100)
    }

    func testGravityNorthWest() throws {
        let image = createTestImage(width: 50, height: 50)
        let result = try image.gravity(direction: .northWest, width: 100, height: 100)
        XCTAssertEqual(result.width, 100)
        XCTAssertEqual(result.height, 100)
    }

    func testGravitySouthEast() throws {
        let image = createTestImage(width: 50, height: 50)
        let result = try image.gravity(direction: .southEast, width: 100, height: 100)
        XCTAssertEqual(result.width, 100)
        XCTAssertEqual(result.height, 100)
    }

    func testPadUniform() throws {
        let image = createTestImage(width: 50, height: 50)
        let padded = try image.pad(top: 10, left: 10, bottom: 10, right: 10)
        XCTAssertEqual(padded.width, 70)
        XCTAssertEqual(padded.height, 70)
    }

    func testPadAsymmetric() throws {
        let image = createTestImage(width: 100, height: 80)
        let padded = try image.pad(top: 5, left: 10, bottom: 15, right: 20)
        XCTAssertEqual(padded.width, 130)
        XCTAssertEqual(padded.height, 100)
    }

    func testPadWithCopyExtend() throws {
        let image = createTestImage(width: 50, height: 50)
        let padded = try image.pad(top: 10, left: 10, bottom: 10, right: 10, extend: .copy)
        XCTAssertEqual(padded.width, 70)
        XCTAssertEqual(padded.height, 70)
    }

    // MARK: - Embed Edge Cases

    func testEmbedAtOrigin() throws {
        let image = createTestImage(width: 50, height: 50)
        let embedded = try image.embed(x: 0, y: 0, width: 100, height: 100)
        XCTAssertEqual(embedded.width, 100)
        XCTAssertEqual(embedded.height, 100)
    }

    func testEmbedPreservesPixels() throws {
        let image = createSolidColorImage(width: 10, height: 10, r: 200, g: 100, b: 50)
        let embedded = try image.embed(x: 5, y: 5, width: 20, height: 20)
        // Check that the original pixel content is at the embedded position
        let pixel = try embedded.pixelValues(atX: 7, y: 7)
        XCTAssertEqual(pixel.red, 200.0, accuracy: 1.0)
        XCTAssertEqual(pixel.green, 100.0, accuracy: 1.0)
        XCTAssertEqual(pixel.blue, 50.0, accuracy: 1.0)
    }

    func testEmbedBlackFillDefault() throws {
        let image = createSolidColorImage(width: 10, height: 10, r: 200, g: 100, b: 50)
        let embedded = try image.embed(x: 10, y: 10, width: 30, height: 30)
        // Check that the padding area is black (default extend mode)
        let pixel = try embedded.pixelValues(atX: 0, y: 0)
        XCTAssertEqual(pixel.red, 0.0, accuracy: 1.0)
        XCTAssertEqual(pixel.green, 0.0, accuracy: 1.0)
        XCTAssertEqual(pixel.blue, 0.0, accuracy: 1.0)
    }

    func testEmbedWithRepeatExtend() throws {
        let image = createTestImage(width: 50, height: 50)
        let embedded = try image.embed(x: 25, y: 25, width: 100, height: 100, extend: .repeat)
        XCTAssertEqual(embedded.width, 100)
        XCTAssertEqual(embedded.height, 100)
    }

    // MARK: - Gravity Additional Directions

    func testGravityNorth() throws {
        let image = createTestImage(width: 50, height: 50)
        let result = try image.gravity(direction: .north, width: 100, height: 100)
        XCTAssertEqual(result.width, 100)
        XCTAssertEqual(result.height, 100)
    }

    func testGravitySouth() throws {
        let image = createTestImage(width: 50, height: 50)
        let result = try image.gravity(direction: .south, width: 100, height: 100)
        XCTAssertEqual(result.width, 100)
        XCTAssertEqual(result.height, 100)
    }

    func testGravityCGSize() throws {
        let image = createTestImage(width: 50, height: 50)
        let result = try image.gravity(direction: .centre, size: CGSize(width: 100, height: 100))
        XCTAssertEqual(result.width, 100)
        XCTAssertEqual(result.height, 100)
    }

    func testGravityWithWhiteExtend() throws {
        let image = createSolidColorImage(width: 10, height: 10, r: 0, g: 0, b: 0)
        let result = try image.gravity(direction: .centre, width: 30, height: 30, extend: .white)
        // Corner should be white
        let pixel = try result.pixelValues(atX: 0, y: 0)
        XCTAssertEqual(pixel.red, 255.0, accuracy: 1.0)
    }

    // MARK: - Pad Edge Cases

    func testPadZero() throws {
        let image = createTestImage(width: 50, height: 50)
        let padded = try image.pad()
        XCTAssertEqual(padded.width, 50)
        XCTAssertEqual(padded.height, 50)
    }

    func testPadTopOnly() throws {
        let image = createTestImage(width: 50, height: 50)
        let padded = try image.pad(top: 20)
        XCTAssertEqual(padded.width, 50)
        XCTAssertEqual(padded.height, 70)
    }

    func testPadLeftOnly() throws {
        let image = createTestImage(width: 50, height: 50)
        let padded = try image.pad(left: 15)
        XCTAssertEqual(padded.width, 65)
        XCTAssertEqual(padded.height, 50)
    }

    // MARK: - Async

    func testAsyncEmbedded() async throws {
        let image = createTestImage(width: 50, height: 50)
        let embedded = try await image.embedded(x: 25, y: 25, width: 100, height: 100)
        XCTAssertEqual(embedded.width, 100)
        XCTAssertEqual(embedded.height, 100)
    }

    func testAsyncGravity() async throws {
        let image = createTestImage(width: 50, height: 50)
        let result = try await image.gravity(direction: .centre, width: 100, height: 100)
        XCTAssertEqual(result.width, 100)
        XCTAssertEqual(result.height, 100)
    }

    func testAsyncGravityCGSize() async throws {
        let image = createTestImage(width: 50, height: 50)
        let result = try await image.gravity(direction: .centre, size: CGSize(width: 100, height: 100))
        XCTAssertEqual(result.width, 100)
        XCTAssertEqual(result.height, 100)
    }

    func testAsyncPadded() async throws {
        let image = createTestImage(width: 50, height: 50)
        let padded = try await image.padded(top: 10, left: 10, bottom: 10, right: 10)
        XCTAssertEqual(padded.width, 70)
        XCTAssertEqual(padded.height, 70)
    }
}
