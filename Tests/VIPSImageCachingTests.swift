import XCTest
@testable import VIPSKit

final class VIPSImageCachingTests: VIPSImageTestCase {

    func testCacheDataDefault() throws {
        let image = createTestImage(width: 100, height: 100)
        let data = try image.cacheData()
        XCTAssertGreaterThan(data.count, 0)
        // Check WebP magic: RIFF
        XCTAssertEqual(data[0], 0x52) // 'R'
        XCTAssertEqual(data[1], 0x49) // 'I'
    }

    func testCacheDataWebPLossy() throws {
        let image = createTestImage(width: 100, height: 100)
        let data = try image.cacheData(format: .webP, quality: 80, lossless: false)
        XCTAssertGreaterThan(data.count, 0)
    }

    func testCacheDataPNG() throws {
        let image = createTestImage(width: 100, height: 100)
        let data = try image.cacheData(format: .png, quality: 0, lossless: true)
        XCTAssertGreaterThan(data.count, 0)
        XCTAssertEqual(data[0], 0x89)
        XCTAssertEqual(data[1], 0x50) // 'P'
    }

    func testCacheDataJPEG() throws {
        let image = createTestImage(width: 100, height: 100)
        let data = try image.cacheData(format: .jpeg, quality: 85, lossless: false)
        XCTAssertGreaterThan(data.count, 0)
        XCTAssertEqual(data[0], 0xFF)
        XCTAssertEqual(data[1], 0xD8)
    }

    func testWriteToCacheFileDefault() throws {
        let image = createTestImage(width: 100, height: 100)
        let path = NSTemporaryDirectory() + "test_cache"
        try image.writeToCache(file: path)

        let expectedPath = path + ".webp"
        XCTAssertTrue(FileManager.default.fileExists(atPath: expectedPath))
        try? FileManager.default.removeItem(atPath: expectedPath)
    }

    func testWriteToCacheFileWithFormat() throws {
        let image = createTestImage(width: 100, height: 100)
        let path = NSTemporaryDirectory() + "test_cache_png"
        try image.writeToCache(file: path, format: .png, quality: 0, lossless: true)

        let expectedPath = path + ".png"
        XCTAssertTrue(FileManager.default.fileExists(atPath: expectedPath))
        try? FileManager.default.removeItem(atPath: expectedPath)
    }

    func testCacheRoundtrip() throws {
        let original = createTestImage(width: 100, height: 100)
        let data = try original.cacheData()
        let restored = try VIPSImage(data: data)
        XCTAssertEqual(restored.width, original.width)
        XCTAssertEqual(restored.height, original.height)
    }

    func testCacheRoundtripWithAlpha() throws {
        let original = createTestImage(width: 100, height: 100, bands: 4)
        let data = try original.cacheData(format: .png, quality: 0, lossless: true)
        let restored = try VIPSImage(data: data)
        XCTAssertTrue(restored.hasAlpha)
    }
}
