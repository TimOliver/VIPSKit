import XCTest
import CoreGraphics
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

    func testBlankImageCGSize() throws {
        let blank = try VIPSImage.blank(size: CGSize(width: 80, height: 60))
        XCTAssertEqual(blank.width, 80)
        XCTAssertEqual(blank.height, 60)
        XCTAssertEqual(blank.bands, 3)
    }

    func testBlankImageCGSizeCustomBands() throws {
        let blank = try VIPSImage.blank(size: CGSize(width: 40, height: 40), bands: 4)
        XCTAssertEqual(blank.bands, 4)
    }

    func testBlankImageIsBlack() throws {
        let blank = try VIPSImage.blank(width: 10, height: 10)
        let pixel = try blank.pixelValues(atX: 5, y: 5)
        XCTAssertEqual(pixel.red, 0.0, accuracy: 1.0)
        XCTAssertEqual(pixel.green, 0.0, accuracy: 1.0)
        XCTAssertEqual(pixel.blue, 0.0, accuracy: 1.0)
    }

    func testBlankImageAllPixelsBlack() throws {
        let blank = try VIPSImage.blank(width: 10, height: 10)
        for x in 0..<10 {
            for y in 0..<10 {
                let pixel = try blank.pixelValues(atX: x, y: y)
                XCTAssertEqual(pixel.red, 0.0, accuracy: 1.0)
                XCTAssertEqual(pixel.green, 0.0, accuracy: 1.0)
                XCTAssertEqual(pixel.blue, 0.0, accuracy: 1.0)
            }
        }
    }

    // MARK: - Draw Rect

    func testDrawRectOutline() throws {
        let image = createTestImage(width: 100, height: 100)
        let result = try image.drawRect(x: 10, y: 10, width: 30, height: 30,
                                        color: VIPSColor(red: 255, green: 0, blue: 0))
        XCTAssertEqual(result.width, 100)
        XCTAssertEqual(result.height, 100)
    }

    func testDrawRectFilled() throws {
        let image = createTestImage(width: 100, height: 100)
        let result = try image.drawRect(x: 10, y: 10, width: 30, height: 30,
                                        color: VIPSColor(red: 0, green: 255, blue: 0), fill: true)
        XCTAssertEqual(result.width, 100)
        XCTAssertEqual(result.height, 100)
    }

    func testDrawRectFilledPixelValues() throws {
        let canvas = try VIPSImage.blank(width: 50, height: 50)
        let red = VIPSColor(red: 255, green: 0, blue: 0)
        let result = try canvas.drawRect(x: 10, y: 10, width: 20, height: 20, color: red, fill: true)
        // Inside the filled rect
        let inside = try result.pixelValues(atX: 20, y: 20)
        XCTAssertEqual(inside.red, 255.0, accuracy: 1.0)
        XCTAssertEqual(inside.green, 0.0, accuracy: 1.0)
        XCTAssertEqual(inside.blue, 0.0, accuracy: 1.0)
        // Outside should still be black
        let outside = try result.pixelValues(atX: 0, y: 0)
        XCTAssertEqual(outside.red, 0.0, accuracy: 1.0)
        XCTAssertEqual(outside.green, 0.0, accuracy: 1.0)
        XCTAssertEqual(outside.blue, 0.0, accuracy: 1.0)
    }

    func testDrawRectOutlinePixelValues() throws {
        let canvas = try VIPSImage.blank(width: 50, height: 50)
        let blue = VIPSColor(red: 0, green: 0, blue: 255)
        let result = try canvas.drawRect(x: 10, y: 10, width: 20, height: 20, color: blue, fill: false)
        // On the border (top edge)
        let border = try result.pixelValues(atX: 15, y: 10)
        XCTAssertEqual(border.blue, 255.0, accuracy: 1.0)
        // Interior should remain black (not filled)
        let interior = try result.pixelValues(atX: 20, y: 20)
        XCTAssertEqual(interior.red, 0.0, accuracy: 1.0)
        XCTAssertEqual(interior.green, 0.0, accuracy: 1.0)
        XCTAssertEqual(interior.blue, 0.0, accuracy: 1.0)
    }

    func testDrawRectFillDefaultIsFalse() throws {
        let canvas = try VIPSImage.blank(width: 50, height: 50)
        let result = try canvas.drawRect(x: 10, y: 10, width: 20, height: 20,
                                         color: VIPSColor(red: 255, green: 0, blue: 0))
        // Interior should be black (outline only)
        let interior = try result.pixelValues(atX: 20, y: 20)
        XCTAssertEqual(interior.red, 0.0, accuracy: 1.0)
    }

    func testDrawRectOnRGBAImage() throws {
        let canvas = try VIPSImage.blank(width: 50, height: 50, bands: 4)
        let color = VIPSColor(values: [255.0, 128.0, 64.0, 200.0])
        let result = try canvas.drawRect(x: 5, y: 5, width: 10, height: 10, color: color, fill: true)
        XCTAssertEqual(result.bands, 4)
        let pixel = try result.pixelValues(atX: 10, y: 10)
        XCTAssertEqual(pixel.count, 4)
        XCTAssertEqual(pixel.red, 255.0, accuracy: 1.0)
        XCTAssertEqual(pixel.alpha!, 255.0, accuracy: 1.0) // ink(forBands: 4) forces alpha to 255
    }

    // MARK: - Draw Line

    func testDrawLine() throws {
        let image = createTestImage(width: 100, height: 100)
        let result = try image.drawLine(from: CGPoint(x: 0, y: 0), to: CGPoint(x: 99, y: 99),
                                        color: VIPSColor(red: 255, green: 255, blue: 0))
        XCTAssertEqual(result.width, 100)
        XCTAssertEqual(result.height, 100)
    }

    func testDrawLinePixelValues() throws {
        let canvas = try VIPSImage.blank(width: 50, height: 50)
        let green = VIPSColor(red: 0, green: 255, blue: 0)
        // Draw a horizontal line at y=25 from x=0 to x=49
        let result = try canvas.drawLine(from: CGPoint(x: 0, y: 25), to: CGPoint(x: 49, y: 25), color: green)
        // Pixel on the line
        let onLine = try result.pixelValues(atX: 25, y: 25)
        XCTAssertEqual(onLine.green, 255.0, accuracy: 1.0)
        // Pixel off the line
        let offLine = try result.pixelValues(atX: 25, y: 0)
        XCTAssertEqual(offLine.green, 0.0, accuracy: 1.0)
    }

    func testDrawVerticalLine() throws {
        let canvas = try VIPSImage.blank(width: 50, height: 50)
        let white = VIPSColor.white
        let result = try canvas.drawLine(from: CGPoint(x: 10, y: 0), to: CGPoint(x: 10, y: 49), color: white)
        // Pixel on the vertical line
        let onLine = try result.pixelValues(atX: 10, y: 25)
        XCTAssertEqual(onLine.red, 255.0, accuracy: 1.0)
        // Pixel off the line
        let offLine = try result.pixelValues(atX: 11, y: 25)
        XCTAssertEqual(offLine.red, 0.0, accuracy: 1.0)
    }

    func testDrawDiagonalLine() throws {
        let canvas = try VIPSImage.blank(width: 100, height: 100)
        let result = try canvas.drawLine(from: CGPoint(x: 0, y: 0), to: CGPoint(x: 99, y: 99),
                                         color: VIPSColor(red: 255, green: 255, blue: 255))
        // The diagonal should touch (50, 50)
        let midPixel = try result.pixelValues(atX: 50, y: 50)
        XCTAssertEqual(midPixel.red, 255.0, accuracy: 1.0)
    }

    // MARK: - Draw Circle

    func testDrawCircleOutline() throws {
        let image = createTestImage(width: 100, height: 100)
        let result = try image.drawCircle(cx: 50, cy: 50, radius: 30,
                                          color: VIPSColor(red: 0, green: 0, blue: 255))
        XCTAssertEqual(result.width, 100)
        XCTAssertEqual(result.height, 100)
    }

    func testDrawCircleFilled() throws {
        let image = createTestImage(width: 100, height: 100)
        let result = try image.drawCircle(cx: 50, cy: 50, radius: 30,
                                          color: VIPSColor(red: 255, green: 0, blue: 255), fill: true)
        XCTAssertEqual(result.width, 100)
        XCTAssertEqual(result.height, 100)
    }

    func testDrawCircleFilledPixelValues() throws {
        let canvas = try VIPSImage.blank(width: 100, height: 100)
        let red = VIPSColor(red: 255, green: 0, blue: 0)
        let result = try canvas.drawCircle(cx: 50, cy: 50, radius: 20, color: red, fill: true)
        // Center of circle
        let center = try result.pixelValues(atX: 50, y: 50)
        XCTAssertEqual(center.red, 255.0, accuracy: 1.0)
        XCTAssertEqual(center.green, 0.0, accuracy: 1.0)
        // Well outside the circle
        let outside = try result.pixelValues(atX: 0, y: 0)
        XCTAssertEqual(outside.red, 0.0, accuracy: 1.0)
    }

    func testDrawCircleOutlineInteriorUnchanged() throws {
        let canvas = try VIPSImage.blank(width: 100, height: 100)
        let result = try canvas.drawCircle(cx: 50, cy: 50, radius: 30,
                                           color: VIPSColor.white, fill: false)
        // Center should remain black for outline-only
        let center = try result.pixelValues(atX: 50, y: 50)
        XCTAssertEqual(center.red, 0.0, accuracy: 1.0)
        // Point on the circle edge (top: cx, cy - radius)
        let edge = try result.pixelValues(atX: 50, y: 20)
        XCTAssertEqual(edge.red, 255.0, accuracy: 1.0)
    }

    func testDrawCircleCGPointOverload() throws {
        let canvas = try VIPSImage.blank(width: 100, height: 100)
        let result = try canvas.drawCircle(center: CGPoint(x: 50, y: 50), radius: 10,
                                           color: VIPSColor.white, fill: true)
        let center = try result.pixelValues(atX: 50, y: 50)
        XCTAssertEqual(center.red, 255.0, accuracy: 1.0)
    }

    func testDrawCircleFillDefaultIsFalse() throws {
        let canvas = try VIPSImage.blank(width: 100, height: 100)
        let result = try canvas.drawCircle(cx: 50, cy: 50, radius: 20, color: VIPSColor.white)
        // Center should remain black
        let center = try result.pixelValues(atX: 50, y: 50)
        XCTAssertEqual(center.red, 0.0, accuracy: 1.0)
    }

    // MARK: - Flood Fill

    func testFloodFill() throws {
        let image = createSolidColorImage(width: 50, height: 50, r: 100, g: 100, b: 100)
        let result = try image.floodFill(x: 25, y: 25,
                                         color: VIPSColor(red: 255, green: 0, blue: 0))
        XCTAssertEqual(result.width, 50)
        XCTAssertEqual(result.height, 50)
    }

    func testFloodFillEntireImage() throws {
        let image = createSolidColorImage(width: 20, height: 20, r: 100, g: 100, b: 100)
        let green = VIPSColor(red: 0, green: 255, blue: 0)
        let filled = try image.floodFill(x: 0, y: 0, color: green)
        // Every pixel should now be green
        for x in stride(from: 0, to: 20, by: 5) {
            for y in stride(from: 0, to: 20, by: 5) {
                let pixel = try filled.pixelValues(atX: x, y: y)
                XCTAssertEqual(pixel.red, 0.0, accuracy: 1.0)
                XCTAssertEqual(pixel.green, 255.0, accuracy: 1.0)
                XCTAssertEqual(pixel.blue, 0.0, accuracy: 1.0)
            }
        }
    }

    func testFloodFillStoppedByBorder() throws {
        // Create a black canvas, draw a white filled rect, then flood-fill inside
        let canvas = try VIPSImage.blank(width: 50, height: 50)
        let withRect = try canvas.drawRect(x: 10, y: 10, width: 20, height: 20,
                                           color: VIPSColor.white, fill: true)
        // Flood fill the black region at (0,0) with red
        let filled = try withRect.floodFill(x: 0, y: 0, color: VIPSColor(red: 255, green: 0, blue: 0))
        // Outside the rect should be red
        let outside = try filled.pixelValues(atX: 0, y: 0)
        XCTAssertEqual(outside.red, 255.0, accuracy: 1.0)
        XCTAssertEqual(outside.green, 0.0, accuracy: 1.0)
        // Inside the white rect should remain white
        let inside = try filled.pixelValues(atX: 20, y: 20)
        XCTAssertEqual(inside.red, 255.0, accuracy: 1.0)
        XCTAssertEqual(inside.green, 255.0, accuracy: 1.0)
        XCTAssertEqual(inside.blue, 255.0, accuracy: 1.0)
    }

    func testFloodFillCGPointOverload() throws {
        let image = createSolidColorImage(width: 20, height: 20, r: 50, g: 50, b: 50)
        let result = try image.floodFill(at: CGPoint(x: 10, y: 10),
                                         color: VIPSColor(red: 200, green: 100, blue: 50))
        let pixel = try result.pixelValues(atX: 0, y: 0)
        XCTAssertEqual(pixel.red, 200.0, accuracy: 1.0)
        XCTAssertEqual(pixel.green, 100.0, accuracy: 1.0)
        XCTAssertEqual(pixel.blue, 50.0, accuracy: 1.0)
    }

    // MARK: - Immutability

    func testDrawDoesNotMutateOriginal() throws {
        let original = createSolidColorImage(width: 30, height: 30, r: 100, g: 100, b: 100)
        _ = try original.drawRect(x: 5, y: 5, width: 10, height: 10,
                                  color: VIPSColor(red: 255, green: 0, blue: 0), fill: true)
        // Original pixel should be unchanged
        let pixel = try original.pixelValues(atX: 10, y: 10)
        XCTAssertEqual(pixel.red, 100.0, accuracy: 1.0)
        XCTAssertEqual(pixel.green, 100.0, accuracy: 1.0)
        XCTAssertEqual(pixel.blue, 100.0, accuracy: 1.0)
    }

    func testLineDoesNotMutateOriginal() throws {
        let original = createSolidColorImage(width: 30, height: 30, r: 50, g: 50, b: 50)
        _ = try original.drawLine(from: CGPoint(x: 0, y: 15), to: CGPoint(x: 29, y: 15),
                                  color: VIPSColor.white)
        let pixel = try original.pixelValues(atX: 15, y: 15)
        XCTAssertEqual(pixel.red, 50.0, accuracy: 1.0)
    }

    func testCircleDoesNotMutateOriginal() throws {
        let original = createSolidColorImage(width: 50, height: 50, r: 80, g: 80, b: 80)
        _ = try original.drawCircle(cx: 25, cy: 25, radius: 10, color: VIPSColor.white, fill: true)
        let pixel = try original.pixelValues(atX: 25, y: 25)
        XCTAssertEqual(pixel.red, 80.0, accuracy: 1.0)
    }

    func testFloodFillDoesNotMutateOriginal() throws {
        let original = createSolidColorImage(width: 20, height: 20, r: 60, g: 60, b: 60)
        _ = try original.floodFill(x: 10, y: 10, color: VIPSColor.white)
        let pixel = try original.pixelValues(atX: 10, y: 10)
        XCTAssertEqual(pixel.red, 60.0, accuracy: 1.0)
    }

    // MARK: - Chaining

    func testDrawMultipleShapes() throws {
        let image = createTestImage(width: 100, height: 100)
        let withRect = try image.drawRect(x: 10, y: 10, width: 20, height: 20,
                                          color: VIPSColor(red: 255, green: 0, blue: 0), fill: true)
        let withCircle = try withRect.drawCircle(cx: 70, cy: 70, radius: 15,
                                                 color: VIPSColor(red: 0, green: 255, blue: 0), fill: true)
        let withLine = try withCircle.drawLine(from: CGPoint(x: 0, y: 0), to: CGPoint(x: 99, y: 99),
                                               color: VIPSColor(red: 0, green: 0, blue: 255))
        XCTAssertEqual(withLine.width, 100)
        XCTAssertEqual(withLine.height, 100)
    }

    func testDrawMultipleShapesPixelValues() throws {
        let canvas = try VIPSImage.blank(width: 100, height: 100)
        // Draw a filled red rect
        let withRect = try canvas.drawRect(x: 0, y: 0, width: 50, height: 50,
                                           color: VIPSColor(red: 255, green: 0, blue: 0), fill: true)
        // Draw a filled green rect in the other corner
        let withBoth = try withRect.drawRect(x: 50, y: 50, width: 50, height: 50,
                                             color: VIPSColor(red: 0, green: 255, blue: 0), fill: true)
        // Verify top-left quadrant is red
        let topLeft = try withBoth.pixelValues(atX: 25, y: 25)
        XCTAssertEqual(topLeft.red, 255.0, accuracy: 1.0)
        XCTAssertEqual(topLeft.green, 0.0, accuracy: 1.0)
        // Verify bottom-right quadrant is green
        let bottomRight = try withBoth.pixelValues(atX: 75, y: 75)
        XCTAssertEqual(bottomRight.red, 0.0, accuracy: 1.0)
        XCTAssertEqual(bottomRight.green, 255.0, accuracy: 1.0)
        // Verify top-right quadrant is still black
        let topRight = try withBoth.pixelValues(atX: 75, y: 25)
        XCTAssertEqual(topRight.red, 0.0, accuracy: 1.0)
        XCTAssertEqual(topRight.green, 0.0, accuracy: 1.0)
        XCTAssertEqual(topRight.blue, 0.0, accuracy: 1.0)
    }

    // MARK: - Single-Band Drawing

    func testDrawRectOnSingleBandImage() throws {
        let canvas = try VIPSImage.blank(width: 50, height: 50, bands: 1)
        let result = try canvas.drawRect(x: 10, y: 10, width: 20, height: 20,
                                         color: VIPSColor.white, fill: true)
        XCTAssertEqual(result.bands, 1)
        let inside = try result.pixelValues(atX: 20, y: 20)
        XCTAssertEqual(inside.count, 1)
        // ink(forBands: 1) produces luminance = 0.2126*255 + 0.7152*255 + 0.0722*255 ≈ 255
        XCTAssertEqual(inside[0], 255.0, accuracy: 1.0)
    }

    func testDrawCircleOnSingleBandImage() throws {
        let canvas = try VIPSImage.blank(width: 50, height: 50, bands: 1)
        let result = try canvas.drawCircle(cx: 25, cy: 25, radius: 10, color: VIPSColor.white, fill: true)
        XCTAssertEqual(result.bands, 1)
        let center = try result.pixelValues(atX: 25, y: 25)
        XCTAssertGreaterThan(center[0], 200.0)
    }

    // MARK: - Export After Drawing

    func testDrawAndExportPNG() throws {
        let canvas = try VIPSImage.blank(width: 50, height: 50)
        let drawn = try canvas.drawRect(x: 5, y: 5, width: 40, height: 40,
                                        color: VIPSColor(red: 128, green: 64, blue: 32), fill: true)
        let data = try drawn.data(format: .png)
        XCTAssertGreaterThan(data.count, 0)
        // Re-load and verify
        let reloaded = try VIPSImage(data: data)
        XCTAssertEqual(reloaded.width, 50)
        XCTAssertEqual(reloaded.height, 50)
        let pixel = try reloaded.pixelValues(atX: 25, y: 25)
        XCTAssertEqual(pixel.red, 128.0, accuracy: 1.0)
        XCTAssertEqual(pixel.green, 64.0, accuracy: 1.0)
        XCTAssertEqual(pixel.blue, 32.0, accuracy: 1.0)
    }
}
