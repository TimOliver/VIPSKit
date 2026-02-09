import XCTest
@testable import VIPSKit

final class VIPSImageLoadingTests: VIPSImageTestCase {

    // MARK: - Buffer Loading

    func testLoadFromBuffer() throws {
        let image = createTestImage(width: 100, height: 100)
        XCTAssertEqual(image.width, 100)
        XCTAssertEqual(image.height, 100)
        XCTAssertEqual(image.bands, 3)
    }

    func testLoadFromBufferRGBA() throws {
        let image = createTestImage(width: 50, height: 50, bands: 4)
        XCTAssertEqual(image.bands, 4)
        XCTAssertTrue(image.hasAlpha)
    }

    func testLoadFromBufferGrayscale() throws {
        let image = createTestImage(width: 50, height: 50, bands: 1)
        XCTAssertEqual(image.bands, 1)
        XCTAssertFalse(image.hasAlpha)
    }

    // MARK: - File Loading

    func testLoadFromFile() throws {
        guard let path = pathForTestResource("superman.jpg") else {
            XCTFail("Test resource not found")
            return
        }
        let image = try VIPSImage(contentsOfFile: path)
        XCTAssertGreaterThan(image.width, 0)
        XCTAssertGreaterThan(image.height, 0)
    }

    func testLoadFromFileSequential() throws {
        guard let path = pathForTestResource("superman.jpg") else {
            XCTFail("Test resource not found")
            return
        }
        let image = try VIPSImage(contentsOfFileSequential: path)
        XCTAssertGreaterThan(image.width, 0)
    }

    // MARK: - Image Info

    func testGetImageInfo() throws {
        guard let path = pathForTestResource("superman.jpg") else {
            XCTFail("Test resource not found")
            return
        }
        let info = try VIPSImage.imageInfo(atPath: path)
        XCTAssertGreaterThan(info.width, 0)
        XCTAssertGreaterThan(info.height, 0)
        XCTAssertEqual(info.format, .jpeg)
    }

    // MARK: - Thumbnail

    func testThumbnailFromFile() throws {
        guard let path = pathForTestResource("superman.jpg") else {
            XCTFail("Test resource not found")
            return
        }
        let thumb = try VIPSImage.thumbnail(fromFile: path, width: 100, height: 100)
        XCTAssertLessThanOrEqual(thumb.width, 100)
        XCTAssertLessThanOrEqual(thumb.height, 100)
    }

    // MARK: - Data Loading

    func testLoadFromData() throws {
        let source = createTestImage(width: 100, height: 100)
        let jpegData = try source.data(format: .jpeg, quality: 85)
        let loaded = try VIPSImage(data: jpegData)
        XCTAssertGreaterThan(loaded.width, 0)
    }

    func testThumbnailFromData() throws {
        let source = createTestImage(width: 200, height: 200)
        let jpegData = try source.data(format: .jpeg, quality: 85)
        let thumb = try VIPSImage.thumbnail(fromData: jpegData, width: 50, height: 50)
        XCTAssertLessThanOrEqual(thumb.width, 50)
    }

    // MARK: - Source Format

    func testSourceFormatJPEG() throws {
        let source = createTestImage(width: 50, height: 50)
        let data = try source.data(format: .jpeg, quality: 85)
        let loaded = try VIPSImage(data: data)
        XCTAssertEqual(loaded.sourceFormat, .jpeg)
    }

    func testSourceFormatPNG() throws {
        let source = createTestImage(width: 50, height: 50)
        let data = try source.data(format: .png)
        let loaded = try VIPSImage(data: data)
        XCTAssertEqual(loaded.sourceFormat, .png)
    }

    func testSourceFormatWebP() throws {
        let source = createTestImage(width: 50, height: 50)
        let data = try source.data(format: .webP, quality: 85)
        let loaded = try VIPSImage(data: data)
        XCTAssertEqual(loaded.sourceFormat, .webP)
    }
}
