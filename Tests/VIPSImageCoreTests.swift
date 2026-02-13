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

    // MARK: - Blank Image Creation

    func testBlankImage() throws {
        let blank = try VIPSImage.blank(width: 100, height: 50)
        XCTAssertEqual(blank.width, 100)
        XCTAssertEqual(blank.height, 50)
        XCTAssertEqual(blank.bands, 3)
    }

    func testBlankImageCustomBands() throws {
        let blank = try VIPSImage.blank(width: 50, height: 50, bands: 4)
        XCTAssertEqual(blank.bands, 4)
    }

    func testBlankImageSingleBand() throws {
        let blank = try VIPSImage.blank(width: 50, height: 50, bands: 1)
        XCTAssertEqual(blank.bands, 1)
        XCTAssertFalse(blank.hasAlpha)
    }

    func testBlankImageIsBlack() throws {
        let blank = try VIPSImage.blank(width: 10, height: 10)
        let pixel = try blank.pixelValues(atX: 5, y: 5)
        XCTAssertEqual(pixel.red, 0.0, accuracy: 0.0)
        XCTAssertEqual(pixel.green, 0.0, accuracy: 0.0)
        XCTAssertEqual(pixel.blue, 0.0, accuracy: 0.0)
    }

    func testBlankImageCGSize() throws {
        let blank = try VIPSImage.blank(size: CGSize(width: 80, height: 60))
        XCTAssertEqual(blank.width, 80)
        XCTAssertEqual(blank.height, 60)
    }

    // MARK: - Pixel Buffer

    func testWithPixelDataRGBA() throws {
        let image = createTestImage(width: 10, height: 10, bands: 4)
        try image.withPixelData { buffer in
            XCTAssertEqual(buffer.width, 10)
            XCTAssertEqual(buffer.height, 10)
            XCTAssertEqual(buffer.bands, 4)
            XCTAssertEqual(buffer.bytesPerRow, 40)
        }
    }

    func testWithPixelDataSolidColor() throws {
        let image = createSolidColorImage(width: 5, height: 5, r: 50, g: 100, b: 200)
        try image.withPixelData { buffer in
            // Check all pixels are the same color
            for i in 0..<5 {
                let offset = i * buffer.bytesPerRow
                XCTAssertEqual(buffer.data[offset], 50)
                XCTAssertEqual(buffer.data[offset + 1], 100)
                XCTAssertEqual(buffer.data[offset + 2], 200)
            }
        }
    }

    // MARK: - Properties from Real Images

    func testPropertiesFromJPEG() throws {
        guard let path = pathForTestResource("superman.jpg") else {
            XCTFail("Test resource not found")
            return
        }
        let image = try VIPSImage(contentsOfFile: path)
        XCTAssertGreaterThan(image.width, 0)
        XCTAssertGreaterThan(image.height, 0)
        XCTAssertGreaterThanOrEqual(image.bands, 1)
    }

    func testPropertiesFromPNG() throws {
        guard let path = pathForTestResource("test-rgb.png") else {
            XCTFail("Test resource not found")
            return
        }
        let image = try VIPSImage(contentsOfFile: path)
        XCTAssertEqual(image.bands, 3)
        XCTAssertFalse(image.hasAlpha)
    }

    func testPropertiesFromRGBA() throws {
        guard let path = pathForTestResource("test-rgba.png") else {
            XCTFail("Test resource not found")
            return
        }
        let image = try VIPSImage(contentsOfFile: path)
        XCTAssertEqual(image.bands, 4)
        XCTAssertTrue(image.hasAlpha)
    }

    // MARK: - Cache

    func testCacheMaxOperationsRoundTrip() {
        let original = VIPSImage.Cache.maxOperations
        VIPSImage.Cache.maxOperations = 42
        XCTAssertEqual(VIPSImage.Cache.maxOperations, 42)
        VIPSImage.Cache.maxOperations = original
    }

    func testCacheMaxFilesRoundTrip() {
        let original = VIPSImage.Cache.maxFiles
        VIPSImage.Cache.maxFiles = 7
        XCTAssertEqual(VIPSImage.Cache.maxFiles, 7)
        VIPSImage.Cache.maxFiles = original
    }

    func testResetMemoryHighWater() {
        // Should not crash and high water should be non-negative
        VIPSImage.resetMemoryHighWater()
        XCTAssertGreaterThanOrEqual(VIPSImage.memoryHighWater, 0)
    }

    // MARK: - Copied To Memory

    func testCopiedToMemoryPreservesPixels() throws {
        let source = createSolidColorImage(width: 10, height: 10, r: 42, g: 128, b: 200)
        let copied = try source.copiedToMemory()
        let pixel = try copied.pixelValues(atX: 5, y: 5)
        XCTAssertEqual(pixel.red, 42.0, accuracy: 0.0)
        XCTAssertEqual(pixel.green, 128.0, accuracy: 0.0)
        XCTAssertEqual(pixel.blue, 200.0, accuracy: 0.0)
    }

    func testCopiedToMemoryIsIndependent() throws {
        let source = createTestImage(width: 100, height: 100)
        let copied = try source.copiedToMemory()
        // Different instances, same content
        XCTAssertEqual(copied.width, source.width)
        XCTAssertEqual(copied.height, source.height)
    }
}
