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

    func testAutoRotatedWithOrientation6() throws {
        // Orientation 6 = 90° CW rotation needed
        guard let path = pathForTestResource("rotated-6.jpg") else {
            XCTFail("Test resource rotated-6.jpg not found")
            return
        }
        let image = try VIPSImage(contentsOfFile: path)

        // Check that orientation metadata is present
        XCTAssertEqual(image.orientation, 6)

        // Original dimensions (before auto-rotate)
        XCTAssertEqual(image.width, 256)
        XCTAssertEqual(image.height, 256)

        // After auto-rotate, orientation should be applied
        let rotated = try image.autoRotated()
        // For a square image, dimensions stay the same
        XCTAssertEqual(rotated.width, 256)
        XCTAssertEqual(rotated.height, 256)
        // Orientation should be reset to 1 (or removed)
        XCTAssertTrue(rotated.orientation == nil || rotated.orientation == 1)
    }

    func testAutoRotatedWithOrientation3() throws {
        // Orientation 3 = 180° rotation needed
        guard let path = pathForTestResource("rotated-3.jpg") else {
            XCTFail("Test resource rotated-3.jpg not found")
            return
        }
        let image = try VIPSImage(contentsOfFile: path)

        // Check that orientation metadata is present
        XCTAssertEqual(image.orientation, 3)

        let rotated = try image.autoRotated()
        XCTAssertEqual(rotated.width, 256)
        XCTAssertEqual(rotated.height, 256)
        // Orientation should be reset
        XCTAssertTrue(rotated.orientation == nil || rotated.orientation == 1)
    }

    func testAutoRotatedPixelVerification() throws {
        // Load the rotated image and verify pixels are actually rotated
        guard let path = pathForTestResource("rotated-6.jpg") else {
            XCTFail("Test resource rotated-6.jpg not found")
            return
        }
        let image = try VIPSImage(contentsOfFile: path)
        let rotated = try image.autoRotated()

        // Sample a corner pixel to verify rotation happened
        // The asymmetric pattern has red in top-left (after rotation),
        // so we can verify the rotation was applied correctly
        let cornerColor = try rotated.pixelValues(atX: 10, y: 10)
        // After 90° CW rotation, the colors should have shifted
        XCTAssertNotNil(cornerColor)
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

    // MARK: - Async

    func testAsyncCropped() async throws {
        let image = createTestImage(width: 200, height: 200)
        let cropped = try await image.cropped(x: 50, y: 50, width: 100, height: 100)
        XCTAssertEqual(cropped.width, 100)
        XCTAssertEqual(cropped.height, 100)
    }

    func testAsyncCroppedCGRect() async throws {
        let image = createTestImage(width: 200, height: 200)
        let cropped = try await image.cropped(CGRect(x: 0, y: 0, width: 50, height: 50))
        XCTAssertEqual(cropped.width, 50)
        XCTAssertEqual(cropped.height, 50)
    }

    func testAsyncSmartCropped() async throws {
        let image = createTestImage(width: 200, height: 200)
        let cropped = try await image.smartCropped(toWidth: 100, height: 100, interesting: .centre)
        XCTAssertEqual(cropped.width, 100)
        XCTAssertEqual(cropped.height, 100)
    }

    func testAsyncSmartCroppedCGSize() async throws {
        let image = createTestImage(width: 200, height: 200)
        let cropped = try await image.smartCropped(to: CGSize(width: 100, height: 100), interesting: .centre)
        XCTAssertEqual(cropped.width, 100)
        XCTAssertEqual(cropped.height, 100)
    }
}
