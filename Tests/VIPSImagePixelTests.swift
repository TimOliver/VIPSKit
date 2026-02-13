import XCTest
import CoreGraphics
@testable import VIPSKit

final class VIPSImagePixelTests: VIPSImageTestCase {

    // MARK: - Basic Pixel Access

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

    func testPixelValuesSingleBand() throws {
        let image = createTestImage(width: 10, height: 10, bands: 1)
        let values = try image.pixelValues(atX: 5, y: 5)
        XCTAssertEqual(values.count, 1)
    }

    // MARK: - VIPSColor Accessors

    func testPixelValuesRedAccessor() throws {
        let image = createSolidColorImage(width: 10, height: 10, r: 200, g: 100, b: 50)
        let color = try image.pixelValues(atX: 0, y: 0)
        XCTAssertEqual(color.red, 200.0, accuracy: 1.0)
        XCTAssertEqual(color.green, 100.0, accuracy: 1.0)
        XCTAssertEqual(color.blue, 50.0, accuracy: 1.0)
        XCTAssertNil(color.alpha)
    }

    func testPixelValuesAlphaAccessor() throws {
        let image = createSolidColorImage(width: 10, height: 10, r: 128, g: 64, b: 32, a: 200)
        let color = try image.pixelValues(atX: 0, y: 0)
        XCTAssertNotNil(color.alpha)
        XCTAssertEqual(color.alpha!, 200.0, accuracy: 1.0)
    }

    // MARK: - Corners and Edges

    func testPixelValuesCorners() throws {
        let image = createTestImage(width: 10, height: 10)
        // Top-left corner
        let topLeft = try image.pixelValues(atX: 0, y: 0)
        XCTAssertEqual(topLeft.count, 3)
        // Top-right
        let topRight = try image.pixelValues(atX: 9, y: 0)
        XCTAssertEqual(topRight.count, 3)
        // Bottom-left
        let bottomLeft = try image.pixelValues(atX: 0, y: 9)
        XCTAssertEqual(bottomLeft.count, 3)
        // Bottom-right corner
        let bottomRight = try image.pixelValues(atX: 9, y: 9)
        XCTAssertEqual(bottomRight.count, 3)
    }

    func testPixelValuesAtOrigin() throws {
        // createTestImage: R = x*255/(w-1), G = y*255/(h-1), B = 128
        let image = createTestImage(width: 100, height: 100)
        let origin = try image.pixelValues(atX: 0, y: 0)
        XCTAssertEqual(origin.red, 0.0, accuracy: 1.0)
        XCTAssertEqual(origin.green, 0.0, accuracy: 1.0)
        XCTAssertEqual(origin.blue, 128.0, accuracy: 1.0)
    }

    func testPixelValuesAtBottomRight() throws {
        let image = createTestImage(width: 100, height: 100)
        let br = try image.pixelValues(atX: 99, y: 99)
        XCTAssertEqual(br.red, 255.0, accuracy: 1.0)
        XCTAssertEqual(br.green, 255.0, accuracy: 1.0)
        XCTAssertEqual(br.blue, 128.0, accuracy: 1.0)
    }

    // MARK: - Gradient Verification

    func testPixelValuesMatchExpectedGradient() throws {
        // createTestImage generates a gradient where R = x*255/(width-1)
        let image = createTestImage(width: 10, height: 10)
        let midValues = try image.pixelValues(atX: 9, y: 0)
        // At x=9 in a 10-wide image: R = 9*255/9 = 255
        XCTAssertEqual(midValues[0], 255.0, accuracy: 1.0)
    }

    func testPixelValuesHorizontalGradient() throws {
        let image = createHorizontalGradient(width: 256, height: 1,
                                             startR: 0, startG: 0, startB: 0,
                                             endR: 255, endG: 255, endB: 255)
        let left = try image.pixelValues(atX: 0, y: 0)
        let mid = try image.pixelValues(atX: 128, y: 0)
        let right = try image.pixelValues(atX: 255, y: 0)
        XCTAssertEqual(left.red, 0.0, accuracy: 1.0)
        XCTAssertEqual(mid.red, 128.0, accuracy: 1.0)
        XCTAssertEqual(right.red, 255.0, accuracy: 1.0)
    }

    func testPixelValuesSolidColorConsistency() throws {
        let image = createSolidColorImage(width: 20, height: 20, r: 42, g: 99, b: 171)
        // Sample several pixels — all should be identical
        for x in stride(from: 0, to: 20, by: 5) {
            for y in stride(from: 0, to: 20, by: 5) {
                let c = try image.pixelValues(atX: x, y: y)
                XCTAssertEqual(c.red, 42.0, accuracy: 1.0)
                XCTAssertEqual(c.green, 99.0, accuracy: 1.0)
                XCTAssertEqual(c.blue, 171.0, accuracy: 1.0)
            }
        }
    }

    // MARK: - CGPoint Overload

    func testPixelValuesAtCGPoint() throws {
        let image = createSolidColorImage(width: 10, height: 10, r: 50, g: 100, b: 150)
        let color = try image.pixelValues(at: CGPoint(x: 3, y: 7))
        XCTAssertEqual(color.red, 50.0, accuracy: 1.0)
        XCTAssertEqual(color.green, 100.0, accuracy: 1.0)
        XCTAssertEqual(color.blue, 150.0, accuracy: 1.0)
    }

    func testPixelValuesCGPointMatchesIntOverload() throws {
        let image = createTestImage(width: 50, height: 50)
        let fromInts = try image.pixelValues(atX: 25, y: 30)
        let fromPoint = try image.pixelValues(at: CGPoint(x: 25, y: 30))
        XCTAssertEqual(fromInts.red, fromPoint.red)
        XCTAssertEqual(fromInts.green, fromPoint.green)
        XCTAssertEqual(fromInts.blue, fromPoint.blue)
    }

    // MARK: - Out of Bounds

    func testPixelValuesOutOfBoundsThrows() {
        let image = createTestImage(width: 10, height: 10)
        XCTAssertThrowsError(try image.pixelValues(atX: 10, y: 0))
        XCTAssertThrowsError(try image.pixelValues(atX: 0, y: 10))
        XCTAssertThrowsError(try image.pixelValues(atX: -1, y: 0))
        XCTAssertThrowsError(try image.pixelValues(atX: 0, y: -1))
    }

    // MARK: - After Drawing Operations

    func testPixelValuesAfterDrawFilledRect() throws {
        let canvas = try VIPSImage.blank(width: 50, height: 50)
        let drawn = try canvas.drawRect(x: 10, y: 10, width: 20, height: 20,
                                        color: VIPSColor(red: 255, green: 0, blue: 0), fill: true)
        // Inside the rect
        let inside = try drawn.pixelValues(atX: 20, y: 20)
        XCTAssertEqual(inside.red, 255.0, accuracy: 1.0)
        XCTAssertEqual(inside.green, 0.0, accuracy: 1.0)
        XCTAssertEqual(inside.blue, 0.0, accuracy: 1.0)
        // Outside the rect (blank = black)
        let outside = try drawn.pixelValues(atX: 0, y: 0)
        XCTAssertEqual(outside.red, 0.0, accuracy: 1.0)
        XCTAssertEqual(outside.green, 0.0, accuracy: 1.0)
        XCTAssertEqual(outside.blue, 0.0, accuracy: 1.0)
    }

    func testPixelValuesAfterFloodFill() throws {
        let image = createSolidColorImage(width: 20, height: 20, r: 100, g: 100, b: 100)
        let filled = try image.floodFill(x: 10, y: 10, color: VIPSColor(red: 0, green: 255, blue: 0))
        let pixel = try filled.pixelValues(atX: 5, y: 5)
        XCTAssertEqual(pixel.red, 0.0, accuracy: 1.0)
        XCTAssertEqual(pixel.green, 255.0, accuracy: 1.0)
        XCTAssertEqual(pixel.blue, 0.0, accuracy: 1.0)
    }
}
