import XCTest
@testable import VIPSKit

final class VIPSImagePixelTests: VIPSImageTestCase {

    func testPixelValuesRGB() throws {
        let image = createSolidColorImage(width: 10, height: 10, r: 128, g: 64, b: 32)
        let values = try image.pixelValues(atX: 5, y: 5)
        XCTAssertEqual(values.count, 3)
        XCTAssertEqual(values[0], 128.0, accuracy: 1.0)
        XCTAssertEqual(values[1], 64.0, accuracy: 1.0)
        XCTAssertEqual(values[2], 32.0, accuracy: 1.0)
    }

    func testPixelValuesRGBA() throws {
        let image = createSolidColorImage(width: 10, height: 10, r: 200, g: 100, b: 50, a: 128)
        let values = try image.pixelValues(atX: 0, y: 0)
        XCTAssertEqual(values.count, 4)
        XCTAssertEqual(values[0], 200.0, accuracy: 1.0)
        XCTAssertEqual(values[1], 100.0, accuracy: 1.0)
        XCTAssertEqual(values[2], 50.0, accuracy: 1.0)
        XCTAssertEqual(values[3], 128.0, accuracy: 1.0)
    }

    func testPixelValuesCorners() throws {
        let image = createTestImage(width: 10, height: 10)
        // Top-left corner
        let topLeft = try image.pixelValues(atX: 0, y: 0)
        XCTAssertEqual(topLeft.count, 3)
        // Bottom-right corner
        let bottomRight = try image.pixelValues(atX: 9, y: 9)
        XCTAssertEqual(bottomRight.count, 3)
    }

    func testPixelValuesSingleBand() throws {
        let image = createTestImage(width: 10, height: 10, bands: 1)
        let values = try image.pixelValues(atX: 5, y: 5)
        XCTAssertEqual(values.count, 1)
    }

    func testPixelValuesMatchExpectedGradient() throws {
        // createTestImage generates a gradient where R = x*255/(width-1)
        let image = createTestImage(width: 10, height: 10)
        let midValues = try image.pixelValues(atX: 9, y: 0)
        // At x=9 in a 10-wide image: R = 9*255/9 = 255
        XCTAssertEqual(midValues[0], 255.0, accuracy: 1.0)
    }
}
