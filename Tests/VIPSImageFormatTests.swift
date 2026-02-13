import XCTest
@testable import VIPSKit

final class VIPSImageFormatTests: VIPSImageTestCase {

    // MARK: - Raw Values

    func testRawValues() {
        XCTAssertEqual(VIPSImageFormat.unknown.rawValue, -1)
        XCTAssertEqual(VIPSImageFormat.jpeg.rawValue, 0)
        XCTAssertEqual(VIPSImageFormat.png.rawValue, 1)
        XCTAssertEqual(VIPSImageFormat.webP.rawValue, 2)
        XCTAssertEqual(VIPSImageFormat.heif.rawValue, 3)
        XCTAssertEqual(VIPSImageFormat.avif.rawValue, 4)
        XCTAssertEqual(VIPSImageFormat.jxl.rawValue, 5)
        XCTAssertEqual(VIPSImageFormat.gif.rawValue, 6)
        XCTAssertEqual(VIPSImageFormat.tiff.rawValue, 7)
    }

    func testInitFromRawValue() {
        XCTAssertEqual(VIPSImageFormat(rawValue: -1), .unknown)
        XCTAssertEqual(VIPSImageFormat(rawValue: 0), .jpeg)
        XCTAssertEqual(VIPSImageFormat(rawValue: 7), .tiff)
        XCTAssertNil(VIPSImageFormat(rawValue: 99))
    }

    // MARK: - File Extensions

    func testFileExtensions() {
        XCTAssertNil(VIPSImageFormat.unknown.fileExtension)
        XCTAssertEqual(VIPSImageFormat.jpeg.fileExtension, "jpg")
        XCTAssertEqual(VIPSImageFormat.png.fileExtension, "png")
        XCTAssertEqual(VIPSImageFormat.webP.fileExtension, "webp")
        XCTAssertEqual(VIPSImageFormat.heif.fileExtension, "heic")
        XCTAssertEqual(VIPSImageFormat.avif.fileExtension, "avif")
        XCTAssertEqual(VIPSImageFormat.jxl.fileExtension, "jxl")
        XCTAssertEqual(VIPSImageFormat.gif.fileExtension, "gif")
        XCTAssertEqual(VIPSImageFormat.tiff.fileExtension, "tif")
    }

    // MARK: - Source Format Detection

    func testSourceFormatJPEG() throws {
        guard let path = pathForTestResource("superman.jpg") else {
            XCTFail("Test resource not found")
            return
        }
        let image = try VIPSImage(contentsOfFile: path)
        XCTAssertEqual(image.sourceFormat, .jpeg)
    }

    func testSourceFormatPNG() throws {
        guard let path = pathForTestResource("test-rgb.png") else {
            XCTFail("Test resource not found")
            return
        }
        let image = try VIPSImage(contentsOfFile: path)
        XCTAssertEqual(image.sourceFormat, .png)
    }

    func testSourceFormatUnknownForBuffer() {
        // Images created from raw buffers have no loader, so sourceFormat is unknown
        let image = createTestImage(width: 10, height: 10)
        XCTAssertEqual(image.sourceFormat, .unknown)
    }

    func testLoaderNameJPEG() throws {
        guard let path = pathForTestResource("superman.jpg") else {
            XCTFail("Test resource not found")
            return
        }
        let image = try VIPSImage(contentsOfFile: path)
        XCTAssertNotNil(image.loaderName)
        XCTAssertTrue(image.loaderName!.hasPrefix("jpeg"))
    }

    func testLoaderNameNilForBuffer() {
        let image = createTestImage(width: 10, height: 10)
        XCTAssertNil(image.loaderName)
    }

    // MARK: - Format Encoding Round-Trip

    func testJPEGRoundTrip() throws {
        let image = createTestImage(width: 50, height: 50)
        let data = try image.data(format: .jpeg, quality: 90)
        let reloaded = try VIPSImage(data: data)
        XCTAssertEqual(reloaded.sourceFormat, .jpeg)
        XCTAssertEqual(reloaded.width, 50)
        XCTAssertEqual(reloaded.height, 50)
    }

    func testPNGRoundTrip() throws {
        let image = createTestImage(width: 50, height: 50)
        let data = try image.data(format: .png)
        let reloaded = try VIPSImage(data: data)
        XCTAssertEqual(reloaded.sourceFormat, .png)
        XCTAssertEqual(reloaded.width, 50)
        XCTAssertEqual(reloaded.height, 50)
    }

    func testWebPRoundTrip() throws {
        let image = createTestImage(width: 50, height: 50)
        let data = try image.data(format: .webP, quality: 80)
        let reloaded = try VIPSImage(data: data)
        XCTAssertEqual(reloaded.sourceFormat, .webP)
    }

    // MARK: - Sendable

    func testSendable() async {
        let format = VIPSImageFormat.jpeg
        let result = await Task.detached {
            return format.fileExtension
        }.value
        XCTAssertEqual(result, "jpg")
    }

    // MARK: - All Cases Exhaustive

    func testAllFormatsHaveFileExtensionOrNil() {
        let allFormats: [VIPSImageFormat] = [
            .unknown, .jpeg, .png, .webP, .heif, .avif, .jxl, .gif, .tiff
        ]
        for format in allFormats {
            if format == .unknown {
                XCTAssertNil(format.fileExtension)
            } else {
                XCTAssertNotNil(format.fileExtension)
                XCTAssertFalse(format.fileExtension!.isEmpty)
            }
        }
    }

    // MARK: - Debug Labels

    func testDebugLabels() {
        XCTAssertEqual(VIPSImageFormat.unknown.debugLabel, "Unknown")
        XCTAssertEqual(VIPSImageFormat.jpeg.debugLabel, "JPEG")
        XCTAssertEqual(VIPSImageFormat.png.debugLabel, "PNG")
        XCTAssertEqual(VIPSImageFormat.webP.debugLabel, "WebP")
        XCTAssertEqual(VIPSImageFormat.heif.debugLabel, "HEIF")
        XCTAssertEqual(VIPSImageFormat.avif.debugLabel, "AVIF")
        XCTAssertEqual(VIPSImageFormat.jxl.debugLabel, "JPEG XL")
        XCTAssertEqual(VIPSImageFormat.gif.debugLabel, "GIF")
        XCTAssertEqual(VIPSImageFormat.tiff.debugLabel, "TIFF")
    }

    func testDebugLabelsNonEmpty() {
        let allFormats: [VIPSImageFormat] = [
            .unknown, .jpeg, .png, .webP, .heif, .avif, .jxl, .gif, .tiff
        ]
        for format in allFormats {
            XCTAssertFalse(format.debugLabel.isEmpty)
        }
    }

    // MARK: - Source Format Detection (Additional Formats)

    func testSourceFormatWebP() throws {
        guard let path = pathForTestResource("test.webp") else {
            XCTFail("Test resource not found")
            return
        }
        let image = try VIPSImage(contentsOfFile: path)
        XCTAssertEqual(image.sourceFormat, .webP)
    }

    func testSourceFormatGIF() throws {
        guard let path = pathForTestResource("test.gif") else {
            XCTFail("Test resource not found")
            return
        }
        let image = try VIPSImage(contentsOfFile: path)
        XCTAssertEqual(image.sourceFormat, .gif)
    }

    func testSourceFormatFromEncodedData() throws {
        let image = createTestImage(width: 50, height: 50)
        let webpData = try image.data(format: .webP, quality: 80)
        let loaded = try VIPSImage(data: webpData)
        XCTAssertEqual(loaded.sourceFormat, .webP)
    }

    func testSourceFormatTIFF() throws {
        let image = createTestImage(width: 50, height: 50)
        let tiffData = try image.data(format: .tiff)
        let loaded = try VIPSImage(data: tiffData)
        XCTAssertEqual(loaded.sourceFormat, .tiff)
    }

    func testSourceFormatJXL() throws {
        let image = createTestImage(width: 50, height: 50)
        let jxlData = try image.data(format: .jxl, quality: 80)
        let loaded = try VIPSImage(data: jxlData)
        XCTAssertEqual(loaded.sourceFormat, .jxl)
    }

    // MARK: - Equatable

    func testFormatEquality() {
        XCTAssertEqual(VIPSImageFormat.jpeg, VIPSImageFormat.jpeg)
        XCTAssertNotEqual(VIPSImageFormat.jpeg, VIPSImageFormat.png)
    }

    // MARK: - Loader Name

    func testLoaderNamePNG() throws {
        guard let path = pathForTestResource("test-rgb.png") else {
            XCTFail("Test resource not found")
            return
        }
        let image = try VIPSImage(contentsOfFile: path)
        XCTAssertNotNil(image.loaderName)
        XCTAssertTrue(image.loaderName!.hasPrefix("png"))
    }

    func testLoaderNameWebP() throws {
        guard let path = pathForTestResource("test.webp") else {
            XCTFail("Test resource not found")
            return
        }
        let image = try VIPSImage(contentsOfFile: path)
        XCTAssertNotNil(image.loaderName)
        XCTAssertTrue(image.loaderName!.hasPrefix("webp"))
    }
}
