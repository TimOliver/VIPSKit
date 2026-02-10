import XCTest
@testable import VIPSKit

final class VIPSImageFilterTests: VIPSImageTestCase {

    func testBlur() throws {
        let image = createTestImage(width: 100, height: 100)
        let blurred = try image.blurred(sigma: 2.0)
        XCTAssertEqual(blurred.width, 100)
        XCTAssertEqual(blurred.height, 100)
    }

    func testBlurHighSigma() throws {
        let image = createTestImage(width: 100, height: 100)
        let blurred = try image.blurred(sigma: 10.0)
        XCTAssertEqual(blurred.width, 100)
    }

    func testSharpen() throws {
        let image = createTestImage(width: 100, height: 100)
        let sharpened = try image.sharpened(sigma: 1.0)
        XCTAssertEqual(sharpened.width, 100)
    }

    func testSharpenHighSigma() throws {
        let image = createTestImage(width: 100, height: 100)
        let sharpened = try image.sharpened(sigma: 3.0)
        XCTAssertEqual(sharpened.width, 100)
    }

    func testSobel() throws {
        let image = createTestImage(width: 100, height: 100)
        let edges = try image.sobel()
        XCTAssertEqual(edges.width, 100)
        XCTAssertEqual(edges.height, 100)
    }

    func testCanny() throws {
        let image = createTestImage(width: 100, height: 100)
        let edges = try image.canny(sigma: 1.4)
        XCTAssertEqual(edges.width, 100)
        XCTAssertEqual(edges.height, 100)
    }

    func testCannyLowSigma() throws {
        let image = createTestImage(width: 100, height: 100)
        let edges = try image.canny(sigma: 0.5)
        XCTAssertEqual(edges.width, 100)
    }

    func testCannyHighSigma() throws {
        let image = createTestImage(width: 100, height: 100)
        let edges = try image.canny(sigma: 3.0)
        XCTAssertEqual(edges.width, 100)
    }

    func testFilterChain() throws {
        let image = createTestImage(width: 100, height: 100)
        let blurred = try image.blurred(sigma: 2.0)
        let sharpened = try blurred.sharpened(sigma: 1.0)
        XCTAssertEqual(sharpened.width, 100)
    }
}
