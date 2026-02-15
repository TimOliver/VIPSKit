import XCTest
import CoreGraphics
import vips
import CVIPS
@testable import VIPSKit

final class VIPSImageCGImageTests: VIPSImageTestCase {

    // MARK: - Basic CGImage Creation

    func testCreateCGImage() throws {
        let image = createTestImage(width: 100, height: 100)
        let cgImage = try image.cgImage
        XCTAssertEqual(cgImage.width, 100)
        XCTAssertEqual(cgImage.height, 100)
    }

    func testCreateCGImageWithAlpha() throws {
        let image = createTestImage(width: 100, height: 100, bands: 4)
        let cgImage = try image.cgImage
        XCTAssertEqual(cgImage.width, 100)
        XCTAssertEqual(cgImage.height, 100)
    }

    func testCreateCGImageGrayscale() throws {
        let image = createTestImage(width: 100, height: 100)
        let gray = try image.grayscaled()
        let cgImage = try gray.cgImage
        XCTAssertEqual(cgImage.width, 100)
        XCTAssertEqual(cgImage.height, 100)
    }

    // MARK: - CGImage Property Verification

    func testCGImagePropertiesRGB() throws {
        let image = createTestImage(width: 50, height: 50)
        let cgImage = try image.cgImage
        XCTAssertEqual(cgImage.bitsPerComponent, 8)
        XCTAssertEqual(cgImage.bitsPerPixel, 24)
        XCTAssertEqual(cgImage.alphaInfo, .none)
        XCTAssertEqual(cgImage.colorSpace?.model, .rgb)
    }

    func testCGImagePropertiesRGBA() throws {
        let image = createTestImage(width: 50, height: 50, bands: 4)
        let cgImage = try image.cgImage
        XCTAssertEqual(cgImage.bitsPerComponent, 8)
        XCTAssertEqual(cgImage.bitsPerPixel, 32)
        XCTAssertEqual(cgImage.alphaInfo, .last)
        XCTAssertEqual(cgImage.colorSpace?.model, .rgb)
    }

    func testCGImagePropertiesGrayscale() throws {
        let image = createTestImage(width: 50, height: 50)
        let gray = try image.grayscaled()
        let cgImage = try gray.cgImage
        XCTAssertEqual(cgImage.bitsPerComponent, 8)
        XCTAssertEqual(cgImage.bitsPerPixel, 8)
        XCTAssertEqual(cgImage.alphaInfo, .none)
        XCTAssertEqual(cgImage.colorSpace?.model, .monochrome)
    }

    // MARK: - Band Count Edge Cases

    func testCGImageTwoBand() throws {
        // 2-band (grayscale + alpha) with B_W interpretation triggers the
        // bands == 2 conversion path in cgImage
        let gray = try createTestImage(width: 50, height: 50).grayscaled()
        let grayAlpha = try gray.addingAlpha()
        XCTAssertEqual(grayAlpha.bands, 2)
        let cgImage = try grayAlpha.cgImage
        XCTAssertEqual(cgImage.width, 50)
        XCTAssertEqual(cgImage.height, 50)
        XCTAssertEqual(cgImage.colorSpace?.model, .rgb)
    }

    func testCGImageFiveBand() throws {
        // >4 bands triggers the extract-first-4-bands path
        let rgba = createTestImage(width: 50, height: 50, bands: 4)
        let fiveBand = try rgba.appendBand(constant: 128.0)
        XCTAssertEqual(fiveBand.bands, 5)
        let cgImage = try fiveBand.cgImage
        XCTAssertEqual(cgImage.width, 50)
        XCTAssertEqual(cgImage.height, 50)
        XCTAssertEqual(cgImage.bitsPerPixel, 32)
        XCTAssertEqual(cgImage.alphaInfo, .last)
    }

    // MARK: - Colorspace Conversion

    func testCGImageFromLabColorspace() throws {
        // Convert sRGB → Lab, then verify cgImage converts back to sRGB
        let rgb = createTestImage(width: 50, height: 50)
        var labPtr: UnsafeMutablePointer<VipsImage>?
        guard cvips_colourspace(rgb.pointer, &labPtr, VIPS_INTERPRETATION_LAB) == 0,
              let labPtr else {
            XCTFail("Failed to convert to Lab colorspace")
            return
        }
        let labImage = VIPSImage(pointer: labPtr)
        XCTAssertEqual(vips_image_get_interpretation(labImage.pointer), VIPS_INTERPRETATION_LAB)

        let cgImage = try labImage.cgImage
        XCTAssertEqual(cgImage.width, 50)
        XCTAssertEqual(cgImage.height, 50)
        XCTAssertEqual(cgImage.colorSpace?.model, .rgb)
    }

    // MARK: - Format Casting

    func testCGImageFromFloatFormat() throws {
        // adjustBrightness produces FLOAT format, testing the cast-to-UCHAR path
        let image = createTestImage(width: 50, height: 50)
        let bright = try image.adjustBrightness(0.1)
        let cgImage = try bright.cgImage
        XCTAssertEqual(cgImage.width, 50)
        XCTAssertEqual(cgImage.height, 50)
        XCTAssertEqual(cgImage.bitsPerComponent, 8)
    }

    // MARK: - Thumbnail CGImage (Sync)

    func testThumbnailCGImage() throws {
        guard let path = pathForTestResource("superman.jpg") else {
            XCTFail("Test resource not found")
            return
        }
        let cgImage = try VIPSImage.thumbnailCGImage(fromFile: path, width: 100, height: 100)
        XCTAssertLessThanOrEqual(cgImage.width, 100)
        XCTAssertLessThanOrEqual(cgImage.height, 100)
    }

    func testThumbnailCGImageCGSize() throws {
        guard let path = pathForTestResource("superman.jpg") else {
            XCTFail("Test resource not found")
            return
        }
        let cgImage = try VIPSImage.thumbnailCGImage(fromFile: path, size: CGSize(width: 80, height: 80))
        XCTAssertLessThanOrEqual(cgImage.width, 80)
        XCTAssertLessThanOrEqual(cgImage.height, 80)
    }

    func testThumbnailCGImageInvalidPath() throws {
        XCTAssertThrowsError(
            try VIPSImage.thumbnailCGImage(fromFile: "/nonexistent/path.jpg", width: 100, height: 100)
        )
    }

    func testThumbnailPreservesAspectRatio() throws {
        guard let path = pathForTestResource("superman.jpg") else {
            XCTFail("Test resource not found")
            return
        }
        let original = try VIPSImage(contentsOfFile: path)
        let aspectRatio = Double(original.width) / Double(original.height)
        let cgImage = try VIPSImage.thumbnailCGImage(fromFile: path, width: 200, height: 100)
        let thumbAspect = Double(cgImage.width) / Double(cgImage.height)
        XCTAssertEqual(thumbAspect, aspectRatio, accuracy: 0.1)
    }

    func testThumbnailCGImageFromPNG() throws {
        guard let path = pathForTestResource("test-rgb.png") else {
            XCTFail("Test resource not found")
            return
        }
        let cgImage = try VIPSImage.thumbnailCGImage(fromFile: path, width: 50, height: 50)
        XCTAssertLessThanOrEqual(cgImage.width, 50)
        XCTAssertLessThanOrEqual(cgImage.height, 50)
        XCTAssertGreaterThan(cgImage.width, 0)
        XCTAssertGreaterThan(cgImage.height, 0)
    }

    func testThumbnailCGImageFromGrayscaleJPEG() throws {
        guard let path = pathForTestResource("grayscale.jpg") else {
            XCTFail("Test resource not found")
            return
        }
        let cgImage = try VIPSImage.thumbnailCGImage(fromFile: path, width: 50, height: 50)
        XCTAssertLessThanOrEqual(cgImage.width, 50)
        XCTAssertLessThanOrEqual(cgImage.height, 50)
    }

    // MARK: - CGImage from Real Files

    func testCGImageFromRGBAPNG() throws {
        guard let path = pathForTestResource("test-rgba.png") else {
            XCTFail("Test resource not found")
            return
        }
        let image = try VIPSImage(contentsOfFile: path)
        XCTAssertTrue(image.hasAlpha)
        let cgImage = try image.cgImage
        XCTAssertEqual(cgImage.width, image.width)
        XCTAssertEqual(cgImage.height, image.height)
        XCTAssertEqual(cgImage.alphaInfo, .last)
    }

    func testCGImageFromGrayscaleJPEG() throws {
        guard let path = pathForTestResource("grayscale.jpg") else {
            XCTFail("Test resource not found")
            return
        }
        let image = try VIPSImage(contentsOfFile: path)
        let cgImage = try image.cgImage
        XCTAssertEqual(cgImage.width, image.width)
        XCTAssertEqual(cgImage.height, image.height)
        XCTAssertEqual(cgImage.colorSpace?.model, .monochrome)
    }

    // MARK: - Pipeline Tests

    func testCreateCGImageFromProcessed() throws {
        let image = createTestImage(width: 200, height: 200)
        let resized = try image.resizeToFit(width: 50, height: 50)
        let cgImage = try resized.cgImage
        XCTAssertLessThanOrEqual(cgImage.width, 50)
        XCTAssertLessThanOrEqual(cgImage.height, 50)
    }

    func testCreateCGImageFromEdges() throws {
        let image = createTestImage(width: 100, height: 100)
        let edges = try image.sobel()
        let cgImage = try edges.cgImage
        XCTAssertEqual(cgImage.width, 100)
        XCTAssertEqual(cgImage.bitsPerComponent, 8)
    }

    // MARK: - Async

    func testAsyncMakeCGImage() async throws {
        let image = createTestImage(width: 100, height: 100)
        let cgImage = try await image.makeCGImage()
        XCTAssertEqual(cgImage.width, 100)
        XCTAssertEqual(cgImage.height, 100)
    }

    func testAsyncThumbnailCGImage() async throws {
        guard let path = pathForTestResource("superman.jpg") else {
            XCTFail("Test resource not found")
            return
        }
        let cgImage = try await VIPSImage.thumbnailCGImage(fromFile: path, width: 100, height: 100)
        XCTAssertLessThanOrEqual(cgImage.width, 100)
        XCTAssertLessThanOrEqual(cgImage.height, 100)
    }

    func testAsyncThumbnailCGImageCGSize() async throws {
        guard let path = pathForTestResource("superman.jpg") else {
            XCTFail("Test resource not found")
            return
        }
        let cgImage = try await VIPSImage.thumbnailCGImage(fromFile: path, size: CGSize(width: 80, height: 80))
        XCTAssertLessThanOrEqual(cgImage.width, 80)
        XCTAssertLessThanOrEqual(cgImage.height, 80)
    }
}
