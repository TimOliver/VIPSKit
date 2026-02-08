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
}
