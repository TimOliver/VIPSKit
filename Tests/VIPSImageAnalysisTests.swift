import XCTest
@testable import VIPSKit

final class VIPSImageAnalysisTests: VIPSImageTestCase {

    // MARK: - Statistics

    func testStatisticsSolidColor() throws {
        let image = createSolidColorImage(width: 50, height: 50, r: 128, g: 128, b: 128)
        let stats = try image.statistics()
        XCTAssertEqual(stats.min, stats.max, accuracy: 1.0)
        XCTAssertEqual(stats.mean, stats.min, accuracy: 1.0)
        XCTAssertLessThan(stats.standardDeviation, 5.0)
    }

    func testStatisticsGradient() throws {
        let image = createHorizontalGradient(width: 256, height: 10,
                                             startR: 0, startG: 0, startB: 0,
                                             endR: 255, endG: 255, endB: 255)
        let stats = try image.statistics()
        XCTAssertLessThan(stats.min, 10.0)
        XCTAssertGreaterThan(stats.max, 245.0)
        XCTAssertGreaterThan(stats.standardDeviation, 50.0)
    }

    // MARK: - Average Color

    func testAverageColorBasic() throws {
        let image = createSolidColorImage(width: 50, height: 50, r: 128, g: 128, b: 128)
        let avg = try image.averageColor()
        XCTAssertEqual(avg.count, 3)
        for val in avg {
            XCTAssertGreaterThanOrEqual(val, 0.0)
            XCTAssertLessThanOrEqual(val, 255.0)
        }
    }

    func testAverageColorWithAlpha() throws {
        let image = createSolidColorImage(width: 50, height: 50, r: 200, g: 100, b: 50, a: 128)
        let avg = try image.averageColor()
        XCTAssertEqual(avg.count, 4)
    }

    func testAverageColorGradient() throws {
        let image = createHorizontalGradient(width: 100, height: 50,
                                             startR: 255, startG: 0, startB: 0,
                                             endR: 0, endG: 0, endB: 255)
        let avg = try image.averageColor()
        XCTAssertEqual(avg.count, 3)
    }

    // MARK: - Detect Background Color

    func testDetectBackgroundColorBasic() throws {
        let image = createImageWithMargins(width: 100, height: 100, margin: 20,
                                           contentR: 255, contentG: 0, contentB: 0,
                                           bgR: 255, bgG: 255, bgB: 255)
        let bg = try image.detectBackgroundColor()
        XCTAssertEqual(bg.count, 3)
    }

    func testDetectBackgroundColorBlack() throws {
        let image = createImageWithMargins(width: 100, height: 100, margin: 15,
                                           contentR: 0, contentG: 255, contentB: 0,
                                           bgR: 0, bgG: 0, bgB: 0)
        let bg = try image.detectBackgroundColor()
        XCTAssertEqual(bg.count, 3)
    }

    func testDetectBackgroundColorWithStripWidth() throws {
        let image = createImageWithMargins(width: 100, height: 100, margin: 25,
                                           contentR: 255, contentG: 0, contentB: 0,
                                           bgR: 128, bgG: 128, bgB: 128)
        let bg = try image.detectBackgroundColor(stripWidth: 20)
        XCTAssertEqual(bg.count, 3)
    }

    // MARK: - Find Trim

    func testFindTrimWhiteMargins() throws {
        let image = createImageWithMargins(width: 100, height: 100, margin: 20,
                                           contentR: 255, contentG: 0, contentB: 0,
                                           bgR: 255, bgG: 255, bgB: 255)
        let bounds = try image.findTrim()
        XCTAssertFalse(bounds.isEmpty)
        XCTAssertEqual(bounds.origin.x, 20, accuracy: 3)
        XCTAssertEqual(bounds.origin.y, 20, accuracy: 3)
        XCTAssertEqual(bounds.width, 60, accuracy: 3)
        XCTAssertEqual(bounds.height, 60, accuracy: 3)
    }

    func testFindTrimBlackMargins() throws {
        let image = createImageWithMargins(width: 150, height: 100, margin: 25,
                                           contentR: 0, contentG: 255, contentB: 0,
                                           bgR: 0, bgG: 0, bgB: 0)
        let bounds = try image.findTrim()
        XCTAssertFalse(bounds.isEmpty)
        XCTAssertGreaterThan(bounds.width, 0)
        XCTAssertGreaterThan(bounds.height, 0)
    }

    func testFindTrimWithThreshold() throws {
        let image = createImageWithMargins(width: 100, height: 100, margin: 15,
                                           contentR: 200, contentG: 50, contentB: 50,
                                           bgR: 255, bgG: 255, bgB: 255)
        let bounds = try image.findTrim(threshold: 10.0)
        XCTAssertFalse(bounds.isEmpty)
    }

    func testFindTrimWithExplicitBackground() throws {
        let image = createImageWithMargins(width: 100, height: 100, margin: 10,
                                           contentR: 100, contentG: 100, contentB: 100,
                                           bgR: 200, bgG: 200, bgB: 200)
        let bounds = try image.findTrim(threshold: 5.0, background: [200, 200, 200])
        XCTAssertFalse(bounds.isEmpty)
        XCTAssertEqual(bounds.origin.x, 10, accuracy: 3)
        XCTAssertEqual(bounds.origin.y, 10, accuracy: 3)
        XCTAssertEqual(bounds.width, 80, accuracy: 3)
        XCTAssertEqual(bounds.height, 80, accuracy: 3)
    }

    func testFindTrimNoMargins() throws {
        let image = createSolidColorImage(width: 50, height: 50, r: 128, g: 128, b: 128)
        let bounds = try image.findTrim()
        XCTAssertEqual(bounds.origin.x, 0, accuracy: 1)
        XCTAssertEqual(bounds.origin.y, 0, accuracy: 1)
        XCTAssertEqual(bounds.width, 50, accuracy: 1)
        XCTAssertEqual(bounds.height, 50, accuracy: 1)
    }

    // MARK: - Arithmetic

    func testSubtractIdenticalImages() throws {
        let image1 = createSolidColorImage(width: 50, height: 50, r: 100, g: 100, b: 100)
        let image2 = createSolidColorImage(width: 50, height: 50, r: 100, g: 100, b: 100)
        let diff = try image1.subtract(image2)
        let stats = try diff.statistics()
        XCTAssertEqual(stats.mean, 0, accuracy: 1.0)
    }

    func testSubtractDifferentImages() throws {
        let image1 = createSolidColorImage(width: 50, height: 50, r: 200, g: 200, b: 200)
        let image2 = createSolidColorImage(width: 50, height: 50, r: 100, g: 100, b: 100)
        let diff = try image1.subtract(image2)
        let stats = try diff.statistics()
        XCTAssertGreaterThan(abs(stats.mean), 50.0)
    }

    func testAbsolute() throws {
        let image1 = createSolidColorImage(width: 50, height: 50, r: 50, g: 50, b: 50)
        let image2 = createSolidColorImage(width: 50, height: 50, r: 100, g: 100, b: 100)
        let diff = try image1.subtract(image2)
        let absDiff = try diff.absolute()
        let stats = try absDiff.statistics()
        XCTAssertGreaterThan(stats.mean, 0.0)
    }

    func testSubtractAndAbsoluteForSimilarity() throws {
        let image1 = createHorizontalGradient(width: 100, height: 50,
                                              startR: 0, startG: 0, startB: 0,
                                              endR: 255, endG: 255, endB: 255)
        let image2 = createHorizontalGradient(width: 100, height: 50,
                                              startR: 10, startG: 10, startB: 10,
                                              endR: 245, endG: 245, endB: 245)
        let diff = try image1.subtract(image2)
        let absDiff = try diff.absolute()
        let stats = try absDiff.statistics()
        XCTAssertLessThan(stats.mean, 20.0)
    }
}
