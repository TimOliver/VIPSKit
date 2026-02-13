import XCTest
@testable import VIPSKit

final class VIPSImageCoreTests: VIPSImageTestCase {

    // MARK: - Properties

    func testImageProperties() {
        let image = createTestImage(width: 200, height: 100)
        XCTAssertEqual(image.width, 200)
        XCTAssertEqual(image.height, 100)
        XCTAssertEqual(image.bands, 3)
        XCTAssertFalse(image.hasAlpha)
    }

    func testImagePropertiesWithAlpha() {
        let image = createTestImage(width: 50, height: 50, bands: 4)
        XCTAssertEqual(image.bands, 4)
        XCTAssertTrue(image.hasAlpha)
    }

    // MARK: - Memory Management

    func testCopiedToMemory() throws {
        let source = createTestImage(width: 100, height: 100)
        let copied = try source.copiedToMemory()
        XCTAssertEqual(copied.width, source.width)
        XCTAssertEqual(copied.height, source.height)
        XCTAssertEqual(copied.bands, source.bands)
    }

    func testClearCache() {
        VIPSImage.Cache.clear()
        // Should not crash
    }

    func testMemoryUsage() {
        let usage = VIPSImage.memoryUsage
        XCTAssertGreaterThanOrEqual(usage, 0)
    }

    func testMemoryHighWater() {
        let hw = VIPSImage.memoryHighWater
        XCTAssertGreaterThanOrEqual(hw, 0)
    }

    func testCacheSettings() {
        VIPSImage.Cache.maxOperations = 50
        VIPSImage.Cache.maxMemory = 25 * 1024 * 1024
        VIPSImage.Cache.maxFiles = 5
        // Restore defaults
        VIPSImage.Cache.maxOperations = 100
        VIPSImage.Cache.maxMemory = 50 * 1024 * 1024
        VIPSImage.Cache.maxFiles = 10
    }

    func testConcurrency() {
        let original = VIPSImage.concurrency
        VIPSImage.concurrency = 2
        XCTAssertEqual(VIPSImage.concurrency, 2)
        VIPSImage.concurrency = original
    }

    // MARK: - Pixel Access

    func testWithPixelData() throws {
        let image = createSolidColorImage(width: 10, height: 10, r: 128, g: 64, b: 32)
        try image.withPixelData { buffer in
            XCTAssertEqual(buffer.width, 10)
            XCTAssertEqual(buffer.height, 10)
            XCTAssertEqual(buffer.bands, 3)
            XCTAssertEqual(buffer.bytesPerRow, 30)
            // Check first pixel
            XCTAssertEqual(buffer.data[0], 128)
            XCTAssertEqual(buffer.data[1], 64)
            XCTAssertEqual(buffer.data[2], 32)
        }
    }

    // MARK: - Concurrent Processing

    func testConcurrentImageProcessing() throws {
        let images = (0..<4).map { _ in createTestImage(width: 100, height: 100) }

        let group = DispatchGroup()
        let queue = DispatchQueue(label: "test.concurrent", attributes: .concurrent)
        var results = [VIPSImage?](repeating: nil, count: 4)
        let lock = NSLock()

        for i in 0..<4 {
            group.enter()
            queue.async {
                let resized = try? images[i].resizeToFit(width: 50, height: 50)
                lock.lock()
                results[i] = resized
                lock.unlock()
                group.leave()
            }
        }

        group.wait()
        for r in results {
            XCTAssertNotNil(r)
        }
    }

    // MARK: - Async

    func testAsyncCopiedToMemory() async throws {
        let source = createTestImage(width: 100, height: 100)
        let copied = try await source.copiedToMemory()
        XCTAssertEqual(copied.width, source.width)
        XCTAssertEqual(copied.height, source.height)
        XCTAssertEqual(copied.bands, source.bands)
    }
}
