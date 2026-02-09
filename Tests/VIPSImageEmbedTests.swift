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
}
