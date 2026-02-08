import XCTest
@testable import VIPSKit

final class VIPSImageTilingTests: VIPSImageTestCase {

    func testTileRects() {
        let image = createTestImage(width: 100, height: 100)
        let rects = image.tileRects(tileWidth: 50, tileHeight: 50)
        XCTAssertEqual(rects.count, 4)
        for rect in rects {
            XCTAssertEqual(rect.width, 50)
            XCTAssertEqual(rect.height, 50)
        }
    }

    func testTileRectsUneven() {
        let image = createTestImage(width: 100, height: 75)
        let rects = image.tileRects(tileWidth: 60, tileHeight: 60)
        // 100/60 = 2 cols, 75/60 = 2 rows
        XCTAssertEqual(rects.count, 4)
        // Last column should be 40px wide, last row 15px tall
        XCTAssertEqual(rects.last!.width, 40)
        XCTAssertEqual(rects.last!.height, 15)
    }

    func testNumberOfStrips() {
        let image = createTestImage(width: 100, height: 250)
        XCTAssertEqual(image.numberOfStrips(withHeight: 100), 3)
        XCTAssertEqual(image.numberOfStrips(withHeight: 250), 1)
        XCTAssertEqual(image.numberOfStrips(withHeight: 0), 0)
    }

    func testStripExtraction() throws {
        let image = createTestImage(width: 100, height: 250)
        let strip0 = try image.strip(atIndex: 0, height: 100)
        XCTAssertEqual(strip0.width, 100)
        XCTAssertEqual(strip0.height, 100)

        let strip2 = try image.strip(atIndex: 2, height: 100)
        XCTAssertEqual(strip2.width, 100)
        XCTAssertEqual(strip2.height, 50) // Last strip is shorter
    }

    func testStripOutOfRange() {
        let image = createTestImage(width: 100, height: 100)
        XCTAssertThrowsError(try image.strip(atIndex: 5, height: 100))
    }

    func testExtractRegionFromFile() throws {
        guard let path = pathForTestResource("superman.jpg") else {
            XCTFail("Test resource not found")
            return
        }
        let info = try VIPSImage.getImageInfo(atPath: path)
        let regionW = min(100, info.width)
        let regionH = min(100, info.height)
        let region = try VIPSImage.extractRegion(fromFile: path, x: 0, y: 0,
                                                  width: regionW, height: regionH)
        XCTAssertEqual(region.width, regionW)
        XCTAssertEqual(region.height, regionH)
    }

    func testExtractRegionFromData() throws {
        let source = createTestImage(width: 200, height: 200)
        let data = try source.data(format: .png)
        let region = try VIPSImage.extractRegion(fromData: data, x: 50, y: 50,
                                                  width: 100, height: 100)
        XCTAssertEqual(region.width, 100)
        XCTAssertEqual(region.height, 100)
    }

    func testProcessStrips() throws {
        let image = createTestImage(width: 100, height: 200)
        let numStrips = image.numberOfStrips(withHeight: 100)
        for i in 0..<numStrips {
            let strip = try image.strip(atIndex: i, height: 100)
            XCTAssertEqual(strip.width, 100)
            XCTAssertGreaterThan(strip.height, 0)
        }
    }
}
