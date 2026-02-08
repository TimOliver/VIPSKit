import XCTest
@testable import VIPSKit

final class VIPSImageExportTests: VIPSImageTestCase {

    func testExportDataDefault() throws {
        let image = createTestImage(width: 100, height: 100)
        let data = try image.exportData()
        XCTAssertGreaterThan(data.count, 0)
        // Check WebP magic: RIFF
        XCTAssertEqual(data[0], 0x52) // 'R'
        XCTAssertEqual(data[1], 0x49) // 'I'
    }

    func testExportDataWebPLossy() throws {
        let image = createTestImage(width: 100, height: 100)
        let data = try image.exportData(format: .webP, quality: 80, lossless: false)
        XCTAssertGreaterThan(data.count, 0)
    }

    func testExportDataPNG() throws {
        let image = createTestImage(width: 100, height: 100)
        let data = try image.exportData(format: .png, quality: 0, lossless: true)
        XCTAssertGreaterThan(data.count, 0)
        XCTAssertEqual(data[0], 0x89)
        XCTAssertEqual(data[1], 0x50) // 'P'
    }

    func testExportDataJPEG() throws {
        let image = createTestImage(width: 100, height: 100)
        let data = try image.exportData(format: .jpeg, quality: 85, lossless: false)
        XCTAssertGreaterThan(data.count, 0)
        XCTAssertEqual(data[0], 0xFF)
        XCTAssertEqual(data[1], 0xD8)
    }

    func testExportToFileDefault() throws {
        let image = createTestImage(width: 100, height: 100)
        let path = NSTemporaryDirectory() + "test_export"
        try image.export(toFile: path)

        let expectedPath = path + ".webp"
        XCTAssertTrue(FileManager.default.fileExists(atPath: expectedPath))
        try? FileManager.default.removeItem(atPath: expectedPath)
    }

    func testExportToFileWithFormat() throws {
        let image = createTestImage(width: 100, height: 100)
        let path = NSTemporaryDirectory() + "test_export_png"
        try image.export(toFile: path, format: .png, quality: 0, lossless: true)

        let expectedPath = path + ".png"
        XCTAssertTrue(FileManager.default.fileExists(atPath: expectedPath))
        try? FileManager.default.removeItem(atPath: expectedPath)
    }

    func testExportRoundtrip() throws {
        let original = createTestImage(width: 100, height: 100)
        let data = try original.exportData()
        let restored = try VIPSImage(data: data)
        XCTAssertEqual(restored.width, original.width)
        XCTAssertEqual(restored.height, original.height)
    }

    func testExportRoundtripWithAlpha() throws {
        let original = createTestImage(width: 100, height: 100, bands: 4)
        let data = try original.exportData(format: .png, quality: 0, lossless: true)
        let restored = try VIPSImage(data: data)
        XCTAssertTrue(restored.hasAlpha)
    }
}
