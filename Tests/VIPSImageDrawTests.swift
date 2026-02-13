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
        let canvas = try VIPSImage.blank(width: 100, height: 100)
        try canvas.drawRect(x: 10, y: 10, width: 30, height: 30,
                            color: VIPSColor(red: 255, green: 0, blue: 0))
        XCTAssertEqual(canvas.width, 100)
        XCTAssertEqual(canvas.height, 100)
    }

    func testDrawRectFilled() throws {
        let canvas = try VIPSImage.blank(width: 100, height: 100)
        try canvas.drawRect(x: 10, y: 10, width: 30, height: 30,
                            color: VIPSColor(red: 0, green: 255, blue: 0), fill: true)
        XCTAssertEqual(canvas.width, 100)
        XCTAssertEqual(canvas.height, 100)
    }

    func testDrawRectFilledPixelValues() throws {
        let canvas = try VIPSImage.blank(width: 50, height: 50)
        let red = VIPSColor(red: 255, green: 0, blue: 0)
        try canvas.drawRect(x: 10, y: 10, width: 20, height: 20, color: red, fill: true)
        // Inside the filled rect
        let inside = try canvas.pixelValues(atX: 20, y: 20)
        XCTAssertEqual(inside.red, 255.0, accuracy: 1.0)
        XCTAssertEqual(inside.green, 0.0, accuracy: 1.0)
        XCTAssertEqual(inside.blue, 0.0, accuracy: 1.0)
        // Outside should still be black
        let outside = try canvas.pixelValues(atX: 0, y: 0)
        XCTAssertEqual(outside.red, 0.0, accuracy: 1.0)
        XCTAssertEqual(outside.green, 0.0, accuracy: 1.0)
        XCTAssertEqual(outside.blue, 0.0, accuracy: 1.0)
    }

    func testDrawRectOutlinePixelValues() throws {
        let canvas = try VIPSImage.blank(width: 50, height: 50)
        let blue = VIPSColor(red: 0, green: 0, blue: 255)
        try canvas.drawRect(x: 10, y: 10, width: 20, height: 20, color: blue, fill: false)
        // On the border (top edge)
        let border = try canvas.pixelValues(atX: 15, y: 10)
        XCTAssertEqual(border.blue, 255.0, accuracy: 1.0)
        // Interior should remain black (not filled)
        let interior = try canvas.pixelValues(atX: 20, y: 20)
        XCTAssertEqual(interior.red, 0.0, accuracy: 1.0)
        XCTAssertEqual(interior.green, 0.0, accuracy: 1.0)
        XCTAssertEqual(interior.blue, 0.0, accuracy: 1.0)
    }

    func testDrawRectFillDefaultIsFalse() throws {
        let canvas = try VIPSImage.blank(width: 50, height: 50)
        try canvas.drawRect(x: 10, y: 10, width: 20, height: 20,
                            color: VIPSColor(red: 255, green: 0, blue: 0))
        // Interior should be black (outline only)
        let interior = try canvas.pixelValues(atX: 20, y: 20)
        XCTAssertEqual(interior.red, 0.0, accuracy: 1.0)
    }

    func testDrawRectOnRGBAImage() throws {
        let canvas = try VIPSImage.blank(width: 50, height: 50, bands: 4)
        let color = VIPSColor(values: [255.0, 128.0, 64.0, 200.0])
        try canvas.drawRect(x: 5, y: 5, width: 10, height: 10, color: color, fill: true)
        XCTAssertEqual(canvas.bands, 4)
        let pixel = try canvas.pixelValues(atX: 10, y: 10)
        XCTAssertEqual(pixel.count, 4)
        XCTAssertEqual(pixel.red, 255.0, accuracy: 1.0)
        XCTAssertEqual(pixel.alpha!, 255.0, accuracy: 1.0) // ink(forBands: 4) forces alpha to 255
    }

    // MARK: - Draw Line

    func testDrawLine() throws {
        let canvas = try VIPSImage.blank(width: 100, height: 100)
        try canvas.drawLine(from: CGPoint(x: 0, y: 0), to: CGPoint(x: 99, y: 99),
                            color: VIPSColor(red: 255, green: 255, blue: 0))
        XCTAssertEqual(canvas.width, 100)
        XCTAssertEqual(canvas.height, 100)
    }

    func testDrawLinePixelValues() throws {
        let canvas = try VIPSImage.blank(width: 50, height: 50)
        let green = VIPSColor(red: 0, green: 255, blue: 0)
        // Draw a horizontal line at y=25 from x=0 to x=49
        try canvas.drawLine(from: CGPoint(x: 0, y: 25), to: CGPoint(x: 49, y: 25), color: green)
        // Pixel on the line
        let onLine = try canvas.pixelValues(atX: 25, y: 25)
        XCTAssertEqual(onLine.green, 255.0, accuracy: 1.0)
        // Pixel off the line
        let offLine = try canvas.pixelValues(atX: 25, y: 0)
        XCTAssertEqual(offLine.green, 0.0, accuracy: 1.0)
    }

    func testDrawVerticalLine() throws {
        let canvas = try VIPSImage.blank(width: 50, height: 50)
        let white = VIPSColor.white
        try canvas.drawLine(from: CGPoint(x: 10, y: 0), to: CGPoint(x: 10, y: 49), color: white)
        // Pixel on the vertical line
        let onLine = try canvas.pixelValues(atX: 10, y: 25)
        XCTAssertEqual(onLine.red, 255.0, accuracy: 1.0)
        // Pixel off the line
        let offLine = try canvas.pixelValues(atX: 11, y: 25)
        XCTAssertEqual(offLine.red, 0.0, accuracy: 1.0)
    }

    func testDrawDiagonalLine() throws {
        let canvas = try VIPSImage.blank(width: 100, height: 100)
        try canvas.drawLine(from: CGPoint(x: 0, y: 0), to: CGPoint(x: 99, y: 99),
                            color: VIPSColor(red: 255, green: 255, blue: 255))
        // The diagonal should touch (50, 50)
        let midPixel = try canvas.pixelValues(atX: 50, y: 50)
        XCTAssertEqual(midPixel.red, 255.0, accuracy: 1.0)
    }

    // MARK: - Draw Circle

    func testDrawCircleOutline() throws {
        let canvas = try VIPSImage.blank(width: 100, height: 100)
        try canvas.drawCircle(cx: 50, cy: 50, radius: 30,
                              color: VIPSColor(red: 0, green: 0, blue: 255))
        XCTAssertEqual(canvas.width, 100)
        XCTAssertEqual(canvas.height, 100)
    }

    func testDrawCircleFilled() throws {
        let canvas = try VIPSImage.blank(width: 100, height: 100)
        try canvas.drawCircle(cx: 50, cy: 50, radius: 30,
                              color: VIPSColor(red: 255, green: 0, blue: 255), fill: true)
        XCTAssertEqual(canvas.width, 100)
        XCTAssertEqual(canvas.height, 100)
    }

    func testDrawCircleFilledPixelValues() throws {
        let canvas = try VIPSImage.blank(width: 100, height: 100)
        let red = VIPSColor(red: 255, green: 0, blue: 0)
        try canvas.drawCircle(cx: 50, cy: 50, radius: 20, color: red, fill: true)
        // Center of circle
        let center = try canvas.pixelValues(atX: 50, y: 50)
        XCTAssertEqual(center.red, 255.0, accuracy: 1.0)
        XCTAssertEqual(center.green, 0.0, accuracy: 1.0)
        // Well outside the circle
        let outside = try canvas.pixelValues(atX: 0, y: 0)
        XCTAssertEqual(outside.red, 0.0, accuracy: 1.0)
    }

    func testDrawCircleOutlineInteriorUnchanged() throws {
        let canvas = try VIPSImage.blank(width: 100, height: 100)
        try canvas.drawCircle(cx: 50, cy: 50, radius: 30,
                              color: VIPSColor.white, fill: false)
        // Center should remain black for outline-only
        let center = try canvas.pixelValues(atX: 50, y: 50)
        XCTAssertEqual(center.red, 0.0, accuracy: 1.0)
        // Point on the circle edge (top: cx, cy - radius)
        let edge = try canvas.pixelValues(atX: 50, y: 20)
        XCTAssertEqual(edge.red, 255.0, accuracy: 1.0)
    }

    func testDrawCircleCGPointOverload() throws {
        let canvas = try VIPSImage.blank(width: 100, height: 100)
        try canvas.drawCircle(center: CGPoint(x: 50, y: 50), radius: 10,
                              color: VIPSColor.white, fill: true)
        let center = try canvas.pixelValues(atX: 50, y: 50)
        XCTAssertEqual(center.red, 255.0, accuracy: 1.0)
    }

    func testDrawCircleFillDefaultIsFalse() throws {
        let canvas = try VIPSImage.blank(width: 100, height: 100)
        try canvas.drawCircle(cx: 50, cy: 50, radius: 20, color: VIPSColor.white)
        // Center should remain black
        let center = try canvas.pixelValues(atX: 50, y: 50)
        XCTAssertEqual(center.red, 0.0, accuracy: 1.0)
    }

    // MARK: - Flood Fill

    func testFloodFill() throws {
        let canvas = try VIPSImage.blank(width: 50, height: 50)
        try canvas.floodFill(x: 25, y: 25,
                             color: VIPSColor(red: 255, green: 0, blue: 0))
        XCTAssertEqual(canvas.width, 50)
        XCTAssertEqual(canvas.height, 50)
    }

    func testFloodFillEntireImage() throws {
        let canvas = try VIPSImage.blank(width: 20, height: 20)
        let green = VIPSColor(red: 0, green: 255, blue: 0)
        try canvas.floodFill(x: 0, y: 0, color: green)
        // Every pixel should now be green
        for x in stride(from: 0, to: 20, by: 5) {
            for y in stride(from: 0, to: 20, by: 5) {
                let pixel = try canvas.pixelValues(atX: x, y: y)
                XCTAssertEqual(pixel.red, 0.0, accuracy: 1.0)
                XCTAssertEqual(pixel.green, 255.0, accuracy: 1.0)
                XCTAssertEqual(pixel.blue, 0.0, accuracy: 1.0)
            }
        }
    }

    func testFloodFillStoppedByBorder() throws {
        // Draw a white filled rect on a black canvas, then flood fill the
        // black exterior with red. The fill should not cross into the white rect.
        let canvas = try VIPSImage.blank(width: 50, height: 50)
        try canvas.drawRect(x: 10, y: 10, width: 20, height: 20,
                            color: VIPSColor.white, fill: true)
        try canvas.floodFill(x: 0, y: 0, color: VIPSColor(red: 255, green: 0, blue: 0))
        // Outside the rect should be red
        let outside = try canvas.pixelValues(atX: 0, y: 0)
        XCTAssertEqual(outside.red, 255.0, accuracy: 1.0)
        XCTAssertEqual(outside.green, 0.0, accuracy: 1.0)
        // Inside the white rect should remain white
        let inside = try canvas.pixelValues(atX: 20, y: 20)
        XCTAssertEqual(inside.red, 255.0, accuracy: 1.0)
        XCTAssertEqual(inside.green, 255.0, accuracy: 1.0)
        XCTAssertEqual(inside.blue, 255.0, accuracy: 1.0)
    }

    func testFloodFillCGPointOverload() throws {
        let canvas = try VIPSImage.blank(width: 20, height: 20)
        try canvas.floodFill(at: CGPoint(x: 10, y: 10),
                             color: VIPSColor(red: 200, green: 100, blue: 50))
        let pixel = try canvas.pixelValues(atX: 0, y: 0)
        XCTAssertEqual(pixel.red, 200.0, accuracy: 1.0)
        XCTAssertEqual(pixel.green, 100.0, accuracy: 1.0)
        XCTAssertEqual(pixel.blue, 50.0, accuracy: 1.0)
    }

    // MARK: - In-Place Mutation

    func testDrawMutatesInPlace() throws {
        let canvas = try VIPSImage.blank(width: 30, height: 30)
        try canvas.drawRect(x: 5, y: 5, width: 10, height: 10,
                            color: VIPSColor(red: 255, green: 0, blue: 0), fill: true)
        // The canvas itself should have the drawn pixels
        let pixel = try canvas.pixelValues(atX: 10, y: 10)
        XCTAssertEqual(pixel.red, 255.0, accuracy: 1.0)
    }

    func testDrawLineReturnsSelf() throws {
        let canvas = try VIPSImage.blank(width: 30, height: 30)
        let returned = try canvas.drawLine(from: CGPoint(x: 0, y: 15),
                                           to: CGPoint(x: 29, y: 15),
                                           color: VIPSColor.white)
        XCTAssertTrue(canvas === returned)
    }

    func testDrawCircleReturnsSelf() throws {
        let canvas = try VIPSImage.blank(width: 50, height: 50)
        let returned = try canvas.drawCircle(cx: 25, cy: 25, radius: 10,
                                             color: VIPSColor.white, fill: true)
        XCTAssertTrue(canvas === returned)
    }

    func testFloodFillReturnsSelf() throws {
        let canvas = try VIPSImage.blank(width: 20, height: 20)
        let returned = try canvas.floodFill(x: 0, y: 0, color: VIPSColor.white)
        XCTAssertTrue(canvas === returned)
    }

    // MARK: - Chaining

    func testDrawChaining() throws {
        let canvas = try VIPSImage.blank(width: 100, height: 100)
        try canvas
            .drawRect(x: 0, y: 0, width: 50, height: 50,
                      color: VIPSColor(red: 255, green: 0, blue: 0), fill: true)
            .drawRect(x: 50, y: 50, width: 50, height: 50,
                      color: VIPSColor(red: 0, green: 255, blue: 0), fill: true)
        // Verify top-left quadrant is red
        let topLeft = try canvas.pixelValues(atX: 25, y: 25)
        XCTAssertEqual(topLeft.red, 255.0, accuracy: 1.0)
        XCTAssertEqual(topLeft.green, 0.0, accuracy: 1.0)
        // Verify bottom-right quadrant is green
        let bottomRight = try canvas.pixelValues(atX: 75, y: 75)
        XCTAssertEqual(bottomRight.red, 0.0, accuracy: 1.0)
        XCTAssertEqual(bottomRight.green, 255.0, accuracy: 1.0)
        // Verify top-right quadrant is still black
        let topRight = try canvas.pixelValues(atX: 75, y: 25)
        XCTAssertEqual(topRight.red, 0.0, accuracy: 1.0)
        XCTAssertEqual(topRight.green, 0.0, accuracy: 1.0)
        XCTAssertEqual(topRight.blue, 0.0, accuracy: 1.0)
    }

    func testDrawChainingMultipleShapeTypes() throws {
        let canvas = try VIPSImage.blank(width: 100, height: 100)
        try canvas
            .drawRect(x: 10, y: 10, width: 20, height: 20,
                      color: VIPSColor(red: 255, green: 0, blue: 0), fill: true)
            .drawCircle(cx: 70, cy: 70, radius: 15,
                        color: VIPSColor(red: 0, green: 255, blue: 0), fill: true)
            .drawLine(from: CGPoint(x: 0, y: 0), to: CGPoint(x: 99, y: 99),
                      color: VIPSColor(red: 0, green: 0, blue: 255))
        XCTAssertEqual(canvas.width, 100)
        XCTAssertEqual(canvas.height, 100)
    }

    // MARK: - Single-Band Drawing

    func testDrawRectOnSingleBandImage() throws {
        let canvas = try VIPSImage.blank(width: 50, height: 50, bands: 1)
        try canvas.drawRect(x: 10, y: 10, width: 20, height: 20,
                            color: VIPSColor.white, fill: true)
        XCTAssertEqual(canvas.bands, 1)
        let inside = try canvas.pixelValues(atX: 20, y: 20)
        XCTAssertEqual(inside.count, 1)
        // ink(forBands: 1) produces luminance = 0.2126*255 + 0.7152*255 + 0.0722*255 ≈ 255
        XCTAssertEqual(inside[0], 255.0, accuracy: 1.0)
    }

    func testDrawCircleOnSingleBandImage() throws {
        let canvas = try VIPSImage.blank(width: 50, height: 50, bands: 1)
        try canvas.drawCircle(cx: 25, cy: 25, radius: 10, color: VIPSColor.white, fill: true)
        XCTAssertEqual(canvas.bands, 1)
        let center = try canvas.pixelValues(atX: 25, y: 25)
        XCTAssertGreaterThan(center[0], 200.0)
    }

    // MARK: - Export After Drawing

    func testDrawAndExportPNG() throws {
        let canvas = try VIPSImage.blank(width: 50, height: 50)
        try canvas.drawRect(x: 5, y: 5, width: 40, height: 40,
                            color: VIPSColor(red: 128, green: 64, blue: 32), fill: true)
        let data = try canvas.data(format: .png)
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
