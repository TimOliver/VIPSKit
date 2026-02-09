import XCTest
@testable import VIPSKit

final class VIPSImageDrawTests: VIPSImageTestCase {

    // MARK: - Canvas Creation

    func testBlankImage() throws {
        let blank = try VIPSImage.blank(width: 200, height: 100)
        XCTAssertEqual(blank.width, 200)
        XCTAssertEqual(blank.height, 100)
        XCTAssertEqual(blank.bands, 3)
    }

    func testBlankImageCustomBands() throws {
        let blank = try VIPSImage.blank(width: 100, height: 100, bands: 4)
        XCTAssertEqual(blank.width, 100)
        XCTAssertEqual(blank.height, 100)
        XCTAssertEqual(blank.bands, 4)
    }

    func testBlankImageSingleBand() throws {
        let blank = try VIPSImage.blank(width: 50, height: 50, bands: 1)
        XCTAssertEqual(blank.bands, 1)
    }

    // MARK: - Drawing Primitives

    func testDrawRectOutline() throws {
        let image = createTestImage(width: 100, height: 100)
        let result = try image.drawRect(x: 10, y: 10, width: 30, height: 30, color: [255, 0, 0])
        XCTAssertEqual(result.width, 100)
        XCTAssertEqual(result.height, 100)
    }

    func testDrawRectFilled() throws {
        let image = createTestImage(width: 100, height: 100)
        let result = try image.drawRect(x: 10, y: 10, width: 30, height: 30,
                                        color: [0, 255, 0], fill: true)
        XCTAssertEqual(result.width, 100)
        XCTAssertEqual(result.height, 100)
    }

    func testDrawLine() throws {
        let image = createTestImage(width: 100, height: 100)
        let result = try image.drawLine(from: (x: 0, y: 0), to: (x: 99, y: 99),
                                        color: [255, 255, 0])
        XCTAssertEqual(result.width, 100)
        XCTAssertEqual(result.height, 100)
    }

    func testDrawCircleOutline() throws {
        let image = createTestImage(width: 100, height: 100)
        let result = try image.drawCircle(cx: 50, cy: 50, radius: 30, color: [0, 0, 255])
        XCTAssertEqual(result.width, 100)
        XCTAssertEqual(result.height, 100)
    }

    func testDrawCircleFilled() throws {
        let image = createTestImage(width: 100, height: 100)
        let result = try image.drawCircle(cx: 50, cy: 50, radius: 30,
                                          color: [255, 0, 255], fill: true)
        XCTAssertEqual(result.width, 100)
        XCTAssertEqual(result.height, 100)
    }

    func testFloodFill() throws {
        let image = createSolidColorImage(width: 50, height: 50, r: 100, g: 100, b: 100)
        let result = try image.floodFill(x: 25, y: 25, color: [255, 0, 0])
        XCTAssertEqual(result.width, 50)
        XCTAssertEqual(result.height, 50)
    }

    func testDrawDoesNotMutateOriginal() throws {
        let original = createTestImage(width: 100, height: 100)
        let originalCopy = try original.copyToMemory()
        _ = try original.drawRect(x: 10, y: 10, width: 30, height: 30,
                                  color: [255, 0, 0], fill: true)
        // Original should be unchanged
        XCTAssertEqual(original.width, originalCopy.width)
        XCTAssertEqual(original.height, originalCopy.height)
    }

    func testDrawMultipleShapes() throws {
        let image = createTestImage(width: 100, height: 100)
        let withRect = try image.drawRect(x: 10, y: 10, width: 20, height: 20,
                                          color: [255, 0, 0], fill: true)
        let withCircle = try withRect.drawCircle(cx: 70, cy: 70, radius: 15,
                                                 color: [0, 255, 0], fill: true)
        let withLine = try withCircle.drawLine(from: (x: 0, y: 0), to: (x: 99, y: 99),
                                               color: [0, 0, 255])
        XCTAssertEqual(withLine.width, 100)
        XCTAssertEqual(withLine.height, 100)
    }
}
