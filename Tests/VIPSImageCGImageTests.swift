import XCTest
import CoreGraphics
@testable import VIPSKit

final class VIPSImageCGImageTests: VIPSImageTestCase {

    func testCreateCGImage() throws {
        let image = createTestImage(width: 100, height: 100)
        let cgImage = try image.cgImage
        XCTAssertEqual(cgImage.width, 100)
        XCTAssertEqual(cgImage.height, 100)
    }

    func testCreateCGImageWithAlpha() throws {
        let image = createTestImage(width: 100, height: 100, bands: 4)
        let cgImage = try image.cgImage
        XCTAssertEqual(cgImage.width, 100)
        XCTAssertEqual(cgImage.height, 100)
    }

    func testCreateCGImageGrayscale() throws {
        let image = createTestImage(width: 100, height: 100)
        let gray = try image.grayscaled()
        let cgImage = try gray.cgImage
        XCTAssertEqual(cgImage.width, 100)
        XCTAssertEqual(cgImage.height, 100)
    }

    func testCreateThumbnailCGImage() throws {
        guard let path = pathForTestResource("superman.jpg") else {
            XCTFail("Test resource not found")
            return
        }
        let cgImage = try VIPSImage.thumbnailCGImage(fromFile: path, width: 100, height: 100)
        XCTAssertLessThanOrEqual(cgImage.width, 100)
        XCTAssertLessThanOrEqual(cgImage.height, 100)
    }

    func testCreateCGImageFromProcessed() throws {
        let image = createTestImage(width: 200, height: 200)
        let resized = try image.resizeToFit(width: 50, height: 50)
        let cgImage = try resized.cgImage
        XCTAssertLessThanOrEqual(cgImage.width, 50)
        XCTAssertLessThanOrEqual(cgImage.height, 50)
    }

    func testCreateCGImageFromEdges() throws {
        let image = createTestImage(width: 100, height: 100)
        let edges = try image.sobel()
        let cgImage = try edges.cgImage
        XCTAssertEqual(cgImage.width, 100)
    }
}
