import XCTest
@testable import VIPSKit

final class VIPSImageSavingTests: VIPSImageTestCase {

    func testSaveJPEG() throws {
        let image = createTestImage(width: 100, height: 100)
        let data = try image.data(format: .jpeg, quality: 85)
        XCTAssertGreaterThan(data.count, 0)
        // Check JPEG magic bytes
        XCTAssertEqual(data[0], 0xFF)
        XCTAssertEqual(data[1], 0xD8)
    }

    func testSavePNG() throws {
        let image = createTestImage(width: 100, height: 100)
        let data = try image.data(format: .png)
        XCTAssertGreaterThan(data.count, 0)
        // Check PNG magic
        XCTAssertEqual(data[0], 0x89)
        XCTAssertEqual(data[1], 0x50) // 'P'
    }

    func testSaveWebP() throws {
        let image = createTestImage(width: 100, height: 100)
        let data = try image.data(format: .webP, quality: 80)
        XCTAssertGreaterThan(data.count, 0)
    }

    func testSaveJPEGQuality() throws {
        let image = createTestImage(width: 100, height: 100)
        let lowQ = try image.data(format: .jpeg, quality: 10)
        let highQ = try image.data(format: .jpeg, quality: 95)
        XCTAssertLessThan(lowQ.count, highQ.count)
    }

    func testWriteToFile() throws {
        let image = createTestImage(width: 100, height: 100)
        let path = NSTemporaryDirectory() + "test_save.jpg"
        try image.write(toFile: path)
        XCTAssertTrue(FileManager.default.fileExists(atPath: path))
        try? FileManager.default.removeItem(atPath: path)
    }

    func testWriteToFileWithFormat() throws {
        let image = createTestImage(width: 100, height: 100)
        let path = NSTemporaryDirectory() + "test_save_explicit.png"
        try image.write(toFile: path, format: .png)
        XCTAssertTrue(FileManager.default.fileExists(atPath: path))
        try? FileManager.default.removeItem(atPath: path)
    }

    func testRoundtripJPEG() throws {
        let source = createTestImage(width: 100, height: 100)
        let data = try source.data(format: .jpeg, quality: 100)
        let loaded = try VIPSImage(data: data)
        XCTAssertEqual(loaded.width, source.width)
        XCTAssertEqual(loaded.height, source.height)
    }

    func testRoundtripPNG() throws {
        let source = createTestImage(width: 100, height: 100)
        let data = try source.data(format: .png)
        let loaded = try VIPSImage(data: data)
        XCTAssertEqual(loaded.width, source.width)
        XCTAssertEqual(loaded.height, source.height)
    }

    func testRoundtripWebP() throws {
        let source = createTestImage(width: 100, height: 100)
        let data = try source.data(format: .webP, quality: 90)
        let loaded = try VIPSImage(data: data)
        XCTAssertEqual(loaded.width, source.width)
        XCTAssertEqual(loaded.height, source.height)
        XCTAssertEqual(loaded.sourceFormat, .webP)
    }

    // MARK: - Round-trip from Real Images

    func testRoundtripRealPNGToJPEG() throws {
        guard let path = pathForTestResource("test-rgb.png") else {
            XCTFail("Test resource not found")
            return
        }
        let source = try VIPSImage(contentsOfFile: path)
        let jpegData = try source.data(format: .jpeg, quality: 90)
        let loaded = try VIPSImage(data: jpegData)
        XCTAssertEqual(loaded.width, source.width)
        XCTAssertEqual(loaded.height, source.height)
        XCTAssertEqual(loaded.sourceFormat, .jpeg)
    }

    func testRoundtripRealPNGToWebP() throws {
        guard let path = pathForTestResource("test-rgb.png") else {
            XCTFail("Test resource not found")
            return
        }
        let source = try VIPSImage(contentsOfFile: path)
        let webpData = try source.data(format: .webP, quality: 85)
        let loaded = try VIPSImage(data: webpData)
        XCTAssertEqual(loaded.width, source.width)
        XCTAssertEqual(loaded.height, source.height)
        XCTAssertEqual(loaded.sourceFormat, .webP)
    }

    func testRoundtripWebPToJPEG() throws {
        guard let path = pathForTestResource("test.webp") else {
            XCTFail("Test resource not found")
            return
        }
        let source = try VIPSImage(contentsOfFile: path)
        let jpegData = try source.data(format: .jpeg, quality: 90)
        let loaded = try VIPSImage(data: jpegData)
        XCTAssertEqual(loaded.width, source.width)
        XCTAssertEqual(loaded.height, source.height)
        XCTAssertEqual(loaded.sourceFormat, .jpeg)
    }

    func testRoundtripGIFToPNG() throws {
        guard let path = pathForTestResource("test.gif") else {
            XCTFail("Test resource not found")
            return
        }
        let source = try VIPSImage(contentsOfFile: path)
        let pngData = try source.data(format: .png)
        let loaded = try VIPSImage(data: pngData)
        XCTAssertEqual(loaded.width, source.width)
        XCTAssertEqual(loaded.height, source.height)
        XCTAssertEqual(loaded.sourceFormat, .png)
    }

    // MARK: - Alpha Preservation

    func testSavePNGPreservesAlpha() throws {
        guard let path = pathForTestResource("test-rgba.png") else {
            XCTFail("Test resource not found")
            return
        }
        let source = try VIPSImage(contentsOfFile: path)
        XCTAssertTrue(source.hasAlpha)

        let data = try source.data(format: .png)
        let loaded = try VIPSImage(data: data)
        XCTAssertTrue(loaded.hasAlpha)
        XCTAssertEqual(loaded.bands, 4)
    }

    func testSaveWebPPreservesAlpha() throws {
        guard let path = pathForTestResource("test-rgba.png") else {
            XCTFail("Test resource not found")
            return
        }
        let source = try VIPSImage(contentsOfFile: path)
        XCTAssertTrue(source.hasAlpha)

        let data = try source.data(format: .webP, quality: 90)
        let loaded = try VIPSImage(data: data)
        XCTAssertTrue(loaded.hasAlpha)
        XCTAssertEqual(loaded.bands, 4)
    }

    // MARK: - Grayscale Handling

    func testSaveGrayscaleToJPEG() throws {
        guard let path = pathForTestResource("grayscale.jpg") else {
            XCTFail("Test resource not found")
            return
        }
        let source = try VIPSImage(contentsOfFile: path)
        XCTAssertEqual(source.bands, 1)

        let data = try source.data(format: .jpeg, quality: 85)
        let loaded = try VIPSImage(data: data)
        XCTAssertEqual(loaded.width, source.width)
        XCTAssertEqual(loaded.height, source.height)
    }

    func testSaveGrayscaleToPNG() throws {
        guard let path = pathForTestResource("grayscale.jpg") else {
            XCTFail("Test resource not found")
            return
        }
        let source = try VIPSImage(contentsOfFile: path)
        XCTAssertEqual(source.bands, 1)

        let data = try source.data(format: .png)
        let loaded = try VIPSImage(data: data)
        XCTAssertEqual(loaded.width, source.width)
        XCTAssertEqual(loaded.height, source.height)
    }

    // MARK: - Tiny Image Handling

    func testSaveTinyImage() throws {
        guard let path = pathForTestResource("tiny.png") else {
            XCTFail("Test resource not found")
            return
        }
        let source = try VIPSImage(contentsOfFile: path)
        XCTAssertEqual(source.width, 8)
        XCTAssertEqual(source.height, 8)

        // Test saving to various formats
        let jpegData = try source.data(format: .jpeg, quality: 100)
        let pngData = try source.data(format: .png)
        let webpData = try source.data(format: .webP, quality: 100)

        XCTAssertGreaterThan(jpegData.count, 0)
        XCTAssertGreaterThan(pngData.count, 0)
        XCTAssertGreaterThan(webpData.count, 0)
    }

    // MARK: - Async

    func testAsyncWriteToFile() async throws {
        let image = createTestImage(width: 100, height: 100)
        let path = NSTemporaryDirectory() + "test_async_save.jpg"
        try await image.write(toFile: path)
        XCTAssertTrue(FileManager.default.fileExists(atPath: path))
        try? FileManager.default.removeItem(atPath: path)
    }

    func testAsyncWriteToFileWithFormat() async throws {
        let image = createTestImage(width: 100, height: 100)
        let path = NSTemporaryDirectory() + "test_async_save_explicit.png"
        try await image.write(toFile: path, format: .png)
        XCTAssertTrue(FileManager.default.fileExists(atPath: path))
        try? FileManager.default.removeItem(atPath: path)
    }

    func testAsyncEncoded() async throws {
        let image = createTestImage(width: 100, height: 100)
        let data = try await image.encoded(format: .jpeg, quality: 85)
        XCTAssertGreaterThan(data.count, 0)
        // Check JPEG magic bytes
        XCTAssertEqual(data[0], 0xFF)
        XCTAssertEqual(data[1], 0xD8)
    }
}
