import XCTest
@testable import VIPSKit

final class VIPSImageBandTests: VIPSImageTestCase {

    func testJoinBands() throws {
        let image1 = createTestImage(width: 50, height: 50, bands: 3)
        let image2 = createTestImage(width: 50, height: 50, bands: 1)
        let joined = try image1.joinBands(with: image2)
        XCTAssertEqual(joined.width, 50)
        XCTAssertEqual(joined.height, 50)
        XCTAssertEqual(joined.bands, 4)
    }

    func testAppendBandConstant() throws {
        let image = createTestImage(width: 50, height: 50, bands: 3)
        let result = try image.appendBand(constant: 255.0)
        XCTAssertEqual(result.bands, 4)
        XCTAssertEqual(result.width, 50)
        XCTAssertEqual(result.height, 50)
    }

    func testAddAlpha() throws {
        let image = createTestImage(width: 50, height: 50, bands: 3)
        XCTAssertFalse(image.hasAlpha)
        let result = try image.addingAlpha()
        XCTAssertTrue(result.hasAlpha)
        XCTAssertEqual(result.bands, 4)
    }

    func testAddAlphaIdempotent() throws {
        let image = createTestImage(width: 50, height: 50, bands: 4)
        XCTAssertTrue(image.hasAlpha)
        let result = try image.addingAlpha()
        // Should still have 4 bands (alpha already present)
        XCTAssertEqual(result.bands, 4)
    }

    func testPremultiply() throws {
        let image = createSolidColorImage(width: 50, height: 50, r: 200, g: 100, b: 50, a: 128)
        let premultiplied = try image.premultiplied()
        XCTAssertEqual(premultiplied.width, 50)
        XCTAssertEqual(premultiplied.height, 50)
    }

    func testUnpremultiply() throws {
        let image = createSolidColorImage(width: 50, height: 50, r: 200, g: 100, b: 50, a: 128)
        let premultiplied = try image.premultiplied()
        let unpremultiplied = try premultiplied.unpremultiplied()
        XCTAssertEqual(unpremultiplied.width, 50)
        XCTAssertEqual(unpremultiplied.height, 50)
    }

    func testPremultiplyRoundtrip() throws {
        let image = createSolidColorImage(width: 50, height: 50, r: 200, g: 100, b: 50, a: 255)
        let premultiplied = try image.premultiplied()
        let unpremultiplied = try premultiplied.unpremultiplied()
        XCTAssertEqual(unpremultiplied.bands, image.bands)
    }

    // MARK: - Real Image Alpha Tests

    func testLoadPNGWithAlpha() throws {
        guard let path = pathForTestResource("test-rgba.png") else {
            XCTFail("Test resource test-rgba.png not found")
            return
        }
        let image = try VIPSImage(contentsOfFile: path)
        XCTAssertTrue(image.hasAlpha)
        XCTAssertEqual(image.bands, 4)
    }

    func testPremultiplyRealImage() throws {
        guard let path = pathForTestResource("test-rgba.png") else {
            XCTFail("Test resource test-rgba.png not found")
            return
        }
        let image = try VIPSImage(contentsOfFile: path)
        let premultiplied = try image.premultiplied()
        XCTAssertEqual(premultiplied.bands, 4)
        XCTAssertTrue(premultiplied.hasAlpha)
    }

    func testAddAlphaToRealImage() throws {
        guard let path = pathForTestResource("test-rgb.png") else {
            XCTFail("Test resource test-rgb.png not found")
            return
        }
        let image = try VIPSImage(contentsOfFile: path)
        XCTAssertFalse(image.hasAlpha)
        XCTAssertEqual(image.bands, 3)

        let withAlpha = try image.addingAlpha()
        XCTAssertTrue(withAlpha.hasAlpha)
        XCTAssertEqual(withAlpha.bands, 4)
    }

    func testGrayscaleImageBands() throws {
        guard let path = pathForTestResource("grayscale.jpg") else {
            XCTFail("Test resource grayscale.jpg not found")
            return
        }
        let image = try VIPSImage(contentsOfFile: path)
        XCTAssertEqual(image.bands, 1)
        XCTAssertFalse(image.hasAlpha)
    }

    func testAddAlphaToGrayscale() throws {
        guard let path = pathForTestResource("grayscale.jpg") else {
            XCTFail("Test resource grayscale.jpg not found")
            return
        }
        let image = try VIPSImage(contentsOfFile: path)
        XCTAssertEqual(image.bands, 1)

        let withAlpha = try image.addingAlpha()
        XCTAssertTrue(withAlpha.hasAlpha)
        XCTAssertEqual(withAlpha.bands, 2)
    }
}
