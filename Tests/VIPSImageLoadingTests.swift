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

    // MARK: - Load From File (Various Formats)

    func testLoadPNGFromFile() throws {
        guard let path = pathForTestResource("test-rgb.png") else {
            XCTFail("Test resource test-rgb.png not found")
            return
        }
        let image = try VIPSImage(contentsOfFile: path)
        XCTAssertEqual(image.width, 256)
        XCTAssertEqual(image.height, 256)
        XCTAssertEqual(image.sourceFormat, .png)
        XCTAssertFalse(image.hasAlpha)
    }

    func testLoadPNGWithAlphaFromFile() throws {
        guard let path = pathForTestResource("test-rgba.png") else {
            XCTFail("Test resource test-rgba.png not found")
            return
        }
        let image = try VIPSImage(contentsOfFile: path)
        XCTAssertEqual(image.width, 256)
        XCTAssertEqual(image.height, 256)
        XCTAssertEqual(image.sourceFormat, .png)
        XCTAssertTrue(image.hasAlpha)
        XCTAssertEqual(image.bands, 4)
    }

    func testLoadWebPFromFile() throws {
        guard let path = pathForTestResource("test.webp") else {
            XCTFail("Test resource test.webp not found")
            return
        }
        let image = try VIPSImage(contentsOfFile: path)
        XCTAssertEqual(image.width, 256)
        XCTAssertEqual(image.height, 256)
        XCTAssertEqual(image.sourceFormat, .webP)
    }

    func testLoadGIFFromFile() throws {
        guard let path = pathForTestResource("test.gif") else {
            XCTFail("Test resource test.gif not found")
            return
        }
        let image = try VIPSImage(contentsOfFile: path)
        XCTAssertEqual(image.width, 64)
        XCTAssertEqual(image.height, 64)
        XCTAssertEqual(image.sourceFormat, .gif)
    }

    func testLoadTIFFFromFile() throws {
        guard let path = pathForTestResource("test.tiff") else {
            XCTFail("Test resource test.tiff not found")
            return
        }
        let image = try VIPSImage(contentsOfFile: path)
        XCTAssertEqual(image.width, 256)
        XCTAssertEqual(image.height, 256)
        XCTAssertEqual(image.sourceFormat, .tiff)
    }

    func testLoadGrayscaleJPEGFromFile() throws {
        guard let path = pathForTestResource("grayscale.jpg") else {
            XCTFail("Test resource grayscale.jpg not found")
            return
        }
        let image = try VIPSImage(contentsOfFile: path)
        XCTAssertEqual(image.width, 256)
        XCTAssertEqual(image.height, 256)
        XCTAssertEqual(image.sourceFormat, .jpeg)
        XCTAssertEqual(image.bands, 1)
        XCTAssertFalse(image.hasAlpha)
    }

    func testLoadTinyImageFromFile() throws {
        guard let path = pathForTestResource("tiny.png") else {
            XCTFail("Test resource tiny.png not found")
            return
        }
        let image = try VIPSImage(contentsOfFile: path)
        XCTAssertEqual(image.width, 8)
        XCTAssertEqual(image.height, 8)
    }

    // MARK: - Image Info (Various Formats)

    func testImageInfoPNG() throws {
        guard let path = pathForTestResource("test-rgb.png") else {
            XCTFail("Test resource not found")
            return
        }
        let info = try VIPSImage.imageInfo(atPath: path)
        XCTAssertEqual(info.width, 256)
        XCTAssertEqual(info.height, 256)
        XCTAssertEqual(info.format, .png)
    }

    func testImageInfoWebP() throws {
        guard let path = pathForTestResource("test.webp") else {
            XCTFail("Test resource not found")
            return
        }
        let info = try VIPSImage.imageInfo(atPath: path)
        XCTAssertEqual(info.width, 256)
        XCTAssertEqual(info.height, 256)
        XCTAssertEqual(info.format, .webP)
    }

    func testImageInfoGIF() throws {
        guard let path = pathForTestResource("test.gif") else {
            XCTFail("Test resource not found")
            return
        }
        let info = try VIPSImage.imageInfo(atPath: path)
        XCTAssertEqual(info.width, 64)
        XCTAssertEqual(info.height, 64)
        XCTAssertEqual(info.format, .gif)
    }

    func testImageInfoTIFF() throws {
        guard let path = pathForTestResource("test.tiff") else {
            XCTFail("Test resource not found")
            return
        }
        let info = try VIPSImage.imageInfo(atPath: path)
        XCTAssertEqual(info.width, 256)
        XCTAssertEqual(info.height, 256)
        XCTAssertEqual(info.format, .tiff)
    }

    // MARK: - Thumbnail From Various Formats

    func testThumbnailFromPNG() throws {
        guard let path = pathForTestResource("test-rgb.png") else {
            XCTFail("Test resource not found")
            return
        }
        let thumb = try VIPSImage.thumbnail(fromFile: path, width: 64, height: 64)
        XCTAssertLessThanOrEqual(thumb.width, 64)
        XCTAssertLessThanOrEqual(thumb.height, 64)
    }

    func testThumbnailFromWebP() throws {
        guard let path = pathForTestResource("test.webp") else {
            XCTFail("Test resource not found")
            return
        }
        let thumb = try VIPSImage.thumbnail(fromFile: path, width: 64, height: 64)
        XCTAssertLessThanOrEqual(thumb.width, 64)
        XCTAssertLessThanOrEqual(thumb.height, 64)
    }

    func testThumbnailFromGIF() throws {
        guard let path = pathForTestResource("test.gif") else {
            XCTFail("Test resource not found")
            return
        }
        let thumb = try VIPSImage.thumbnail(fromFile: path, width: 32, height: 32)
        XCTAssertLessThanOrEqual(thumb.width, 32)
        XCTAssertLessThanOrEqual(thumb.height, 32)
    }

    func testThumbnailPreservesAlpha() throws {
        guard let path = pathForTestResource("test-rgba.png") else {
            XCTFail("Test resource not found")
            return
        }
        let thumb = try VIPSImage.thumbnail(fromFile: path, width: 64, height: 64)
        XCTAssertTrue(thumb.hasAlpha)
        XCTAssertEqual(thumb.bands, 4)
    }
}
