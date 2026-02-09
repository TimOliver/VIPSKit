import XCTest
@testable import VIPSKit

final class VIPSImageTransformTests: VIPSImageTestCase {

    // MARK: - Crop

    func testCrop() throws {
        let image = createTestImage(width: 200, height: 200)
        let cropped = try image.crop(x: 50, y: 50, width: 100, height: 100)
        XCTAssertEqual(cropped.width, 100)
        XCTAssertEqual(cropped.height, 100)
    }

    func testCropCorner() throws {
        let image = createTestImage(width: 100, height: 100)
        let cropped = try image.crop(x: 0, y: 0, width: 50, height: 50)
        XCTAssertEqual(cropped.width, 50)
        XCTAssertEqual(cropped.height, 50)
    }

    func testCropFullWidth() throws {
        let image = createTestImage(width: 100, height: 200)
        let cropped = try image.crop(x: 0, y: 50, width: 100, height: 100)
        XCTAssertEqual(cropped.width, 100)
        XCTAssertEqual(cropped.height, 100)
    }

    // MARK: - Rotation

    func testRotate90() throws {
        let image = createTestImage(width: 200, height: 100)
        let rotated = try image.rotate(degrees: 90)
        XCTAssertEqual(rotated.width, 100)
        XCTAssertEqual(rotated.height, 200)
    }

    func testRotate180() throws {
        let image = createTestImage(width: 200, height: 100)
        let rotated = try image.rotate(degrees: 180)
        XCTAssertEqual(rotated.width, 200)
        XCTAssertEqual(rotated.height, 100)
    }

    func testRotate270() throws {
        let image = createTestImage(width: 200, height: 100)
        let rotated = try image.rotate(degrees: 270)
        XCTAssertEqual(rotated.width, 100)
        XCTAssertEqual(rotated.height, 200)
    }

    func testRotateNegative90() throws {
        let image = createTestImage(width: 200, height: 100)
        let rotated = try image.rotate(degrees: -90)
        XCTAssertEqual(rotated.width, 100)
        XCTAssertEqual(rotated.height, 200)
    }

    func testRotate0() throws {
        let image = createTestImage(width: 200, height: 100)
        let rotated = try image.rotate(degrees: 0)
        XCTAssertEqual(rotated.width, 200)
        XCTAssertEqual(rotated.height, 100)
    }

    // MARK: - Flip

    func testFlippedHorizontally() throws {
        let image = createTestImage(width: 100, height: 100)
        let flipped = try image.flippedHorizontally()
        XCTAssertEqual(flipped.width, 100)
        XCTAssertEqual(flipped.height, 100)
    }

    func testFlippedVertically() throws {
        let image = createTestImage(width: 100, height: 100)
        let flipped = try image.flippedVertically()
        XCTAssertEqual(flipped.width, 100)
        XCTAssertEqual(flipped.height, 100)
    }

    // MARK: - Auto Rotate

    func testAutoRotated() throws {
        let image = createTestImage(width: 100, height: 100)
        let rotated = try image.autoRotated()
        XCTAssertEqual(rotated.width, 100)
        XCTAssertEqual(rotated.height, 100)
    }

    // MARK: - Smart Crop

    func testSmartCropCentre() throws {
        let image = createTestImage(width: 200, height: 200)
        let cropped = try image.smartCrop(toWidth: 100, height: 100, interesting: .centre)
        XCTAssertEqual(cropped.width, 100)
        XCTAssertEqual(cropped.height, 100)
    }

    func testSmartCropEntropy() throws {
        let image = createTestImage(width: 200, height: 200)
        let cropped = try image.smartCrop(toWidth: 100, height: 100, interesting: .entropy)
        XCTAssertEqual(cropped.width, 100)
        XCTAssertEqual(cropped.height, 100)
    }

    func testSmartCropAttention() throws {
        let image = createTestImage(width: 200, height: 200)
        let cropped = try image.smartCrop(toWidth: 100, height: 100, interesting: .attention)
        XCTAssertEqual(cropped.width, 100)
        XCTAssertEqual(cropped.height, 100)
    }
}
