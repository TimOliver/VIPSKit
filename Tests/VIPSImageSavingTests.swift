import XCTest
@testable import VIPSKit

final class VIPSImageSavingTests: VIPSImageTestCase {

    // MARK: - data(format:quality:) — Per-Format

    func testDataJPEG() throws {
        let image = createTestImage(width: 100, height: 100)
        let data = try image.data(format: .jpeg, quality: 85)
        XCTAssertGreaterThan(data.count, 0)
        // JPEG magic: FF D8
        XCTAssertEqual(data[0], 0xFF)
        XCTAssertEqual(data[1], 0xD8)
    }

    func testDataPNG() throws {
        let image = createTestImage(width: 100, height: 100)
        let data = try image.data(format: .png)
        XCTAssertGreaterThan(data.count, 0)
        // PNG magic: 89 50 4E 47 0D 0A 1A 0A
        XCTAssertEqual(data[0], 0x89)
        XCTAssertEqual(data[1], 0x50) // 'P'
        XCTAssertEqual(data[2], 0x4E) // 'N'
        XCTAssertEqual(data[3], 0x47) // 'G'
    }

    func testDataWebP() throws {
        let image = createTestImage(width: 100, height: 100)
        let data = try image.data(format: .webP, quality: 80)
        XCTAssertGreaterThan(data.count, 0)
        // WebP magic: RIFF....WEBP
        XCTAssertEqual(data[0], 0x52) // 'R'
        XCTAssertEqual(data[1], 0x49) // 'I'
        XCTAssertEqual(data[2], 0x46) // 'F'
        XCTAssertEqual(data[3], 0x46) // 'F'
        XCTAssertEqual(data[8], 0x57)  // 'W'
        XCTAssertEqual(data[9], 0x45)  // 'E'
        XCTAssertEqual(data[10], 0x42) // 'B'
        XCTAssertEqual(data[11], 0x50) // 'P'
    }

    func testDataHEIFThrowsUnsupported() {
        let image = createTestImage(width: 50, height: 50)
        XCTAssertThrowsError(try image.data(format: .heif)) { error in
            XCTAssertTrue(error is VIPSError)
            let vipsError = error as! VIPSError
            XCTAssertTrue(vipsError.message.contains("not supported"))
        }
    }

    func testDataAVIFThrowsUnsupported() {
        let image = createTestImage(width: 50, height: 50)
        XCTAssertThrowsError(try image.data(format: .avif)) { error in
            XCTAssertTrue(error is VIPSError)
            let vipsError = error as! VIPSError
            XCTAssertTrue(vipsError.message.contains("not supported"))
        }
    }

    func testDataJXL() throws {
        let image = createTestImage(width: 100, height: 100)
        let data = try image.data(format: .jxl, quality: 80)
        XCTAssertGreaterThan(data.count, 0)
        // JXL codestream starts with FF 0A, or ISOBMFF container starts with 00 00 00 0C 4A 58 4C 20
        let isCodestream = data[0] == 0xFF && data[1] == 0x0A
        let isContainer = data.count >= 12
            && data[0] == 0x00 && data[1] == 0x00 && data[2] == 0x00 && data[3] == 0x0C
            && data[4] == 0x4A && data[5] == 0x58 && data[6] == 0x4C && data[7] == 0x20
        XCTAssertTrue(isCodestream || isContainer, "Data should be JXL codestream or container")
    }

    func testDataGIF() throws {
        let image = createTestImage(width: 100, height: 100)
        let data = try image.data(format: .gif)
        XCTAssertGreaterThan(data.count, 0)
        // GIF magic: "GIF8"
        XCTAssertEqual(data[0], 0x47) // 'G'
        XCTAssertEqual(data[1], 0x49) // 'I'
        XCTAssertEqual(data[2], 0x46) // 'F'
        XCTAssertEqual(data[3], 0x38) // '8'
    }

    func testDataTIFF() throws {
        let image = createTestImage(width: 100, height: 100)
        let data = try image.data(format: .tiff)
        XCTAssertGreaterThan(data.count, 0)
        // TIFF magic: "II" (little-endian) or "MM" (big-endian)
        let isLE = data[0] == 0x49 && data[1] == 0x49 // 'II'
        let isBE = data[0] == 0x4D && data[1] == 0x4D // 'MM'
        XCTAssertTrue(isLE || isBE, "Data should have TIFF byte-order marker")
    }

    func testDataUnknownFormatThrows() {
        let image = createTestImage(width: 50, height: 50)
        XCTAssertThrowsError(try image.data(format: .unknown)) { error in
            XCTAssertTrue(error is VIPSError)
            let vipsError = error as! VIPSError
            XCTAssertTrue(vipsError.message.contains("Unknown"))
        }
    }

    // MARK: - data(format:quality:) — Quality Parameter

    func testDataJPEGQualityAffectsSize() throws {
        let image = createTestImage(width: 100, height: 100)
        let lowQ = try image.data(format: .jpeg, quality: 10)
        let highQ = try image.data(format: .jpeg, quality: 95)
        XCTAssertLessThan(lowQ.count, highQ.count)
    }

    func testDataWebPQualityAffectsSize() throws {
        let image = createTestImage(width: 100, height: 100)
        let lowQ = try image.data(format: .webP, quality: 10)
        let highQ = try image.data(format: .webP, quality: 95)
        XCTAssertLessThan(lowQ.count, highQ.count)
    }

    func testDataJXLQualityAffectsSize() throws {
        let image = createTestImage(width: 100, height: 100)
        let lowQ = try image.data(format: .jxl, quality: 10)
        let highQ = try image.data(format: .jxl, quality: 95)
        XCTAssertLessThan(lowQ.count, highQ.count)
    }

    func testDataDefaultQualityIs85() throws {
        let image = createTestImage(width: 100, height: 100)
        let defaultQ = try image.data(format: .jpeg)
        let explicit85 = try image.data(format: .jpeg, quality: 85)
        // Same quality should produce identical output
        XCTAssertEqual(defaultQ.count, explicit85.count)
    }

    // MARK: - data(format:quality:) — Round-Trip Per Format

    func testRoundtripJPEG() throws {
        let source = createTestImage(width: 100, height: 100)
        let data = try source.data(format: .jpeg, quality: 100)
        let loaded = try VIPSImage(data: data)
        XCTAssertEqual(loaded.width, 100)
        XCTAssertEqual(loaded.height, 100)
        XCTAssertEqual(loaded.sourceFormat, .jpeg)
    }

    func testRoundtripPNG() throws {
        let source = createTestImage(width: 100, height: 100)
        let data = try source.data(format: .png)
        let loaded = try VIPSImage(data: data)
        XCTAssertEqual(loaded.width, 100)
        XCTAssertEqual(loaded.height, 100)
        XCTAssertEqual(loaded.sourceFormat, .png)
    }

    func testRoundtripWebP() throws {
        let source = createTestImage(width: 100, height: 100)
        let data = try source.data(format: .webP, quality: 90)
        let loaded = try VIPSImage(data: data)
        XCTAssertEqual(loaded.width, 100)
        XCTAssertEqual(loaded.height, 100)
        XCTAssertEqual(loaded.sourceFormat, .webP)
    }

    func testRoundtripJXL() throws {
        let source = createTestImage(width: 100, height: 100)
        let data = try source.data(format: .jxl, quality: 90)
        let loaded = try VIPSImage(data: data)
        XCTAssertEqual(loaded.width, 100)
        XCTAssertEqual(loaded.height, 100)
        XCTAssertEqual(loaded.sourceFormat, .jxl)
    }

    func testRoundtripGIF() throws {
        let source = createTestImage(width: 100, height: 100)
        let data = try source.data(format: .gif)
        let loaded = try VIPSImage(data: data)
        XCTAssertEqual(loaded.width, 100)
        XCTAssertEqual(loaded.height, 100)
        XCTAssertEqual(loaded.sourceFormat, .gif)
    }

    func testRoundtripTIFF() throws {
        let source = createTestImage(width: 100, height: 100)
        let data = try source.data(format: .tiff)
        let loaded = try VIPSImage(data: data)
        XCTAssertEqual(loaded.width, 100)
        XCTAssertEqual(loaded.height, 100)
        XCTAssertEqual(loaded.sourceFormat, .tiff)
    }

    // MARK: - data(format:quality:) — Pixel Fidelity (Lossless Formats)

    func testPNGLosslessPixelFidelity() throws {
        let source = createSolidColorImage(width: 10, height: 10, r: 42, g: 128, b: 200)
        let data = try source.data(format: .png)
        let loaded = try VIPSImage(data: data)
        let pixel = try loaded.pixelValues(atX: 5, y: 5)
        XCTAssertEqual(pixel.red, 42.0, accuracy: 0.0)
        XCTAssertEqual(pixel.green, 128.0, accuracy: 0.0)
        XCTAssertEqual(pixel.blue, 200.0, accuracy: 0.0)
    }

    func testTIFFLosslessPixelFidelity() throws {
        let source = createSolidColorImage(width: 10, height: 10, r: 17, g: 99, b: 250)
        let data = try source.data(format: .tiff)
        let loaded = try VIPSImage(data: data)
        let pixel = try loaded.pixelValues(atX: 5, y: 5)
        XCTAssertEqual(pixel.red, 17.0, accuracy: 0.0)
        XCTAssertEqual(pixel.green, 99.0, accuracy: 0.0)
        XCTAssertEqual(pixel.blue, 250.0, accuracy: 0.0)
    }

    // MARK: - write(toFile:) — Inferred Format Per Extension

    func testWriteToFileJPEG() throws {
        let image = createTestImage(width: 50, height: 50)
        let path = NSTemporaryDirectory() + "vipskit_test_write.jpg"
        defer { try? FileManager.default.removeItem(atPath: path) }
        try image.write(toFile: path)
        XCTAssertTrue(FileManager.default.fileExists(atPath: path))
        let loaded = try VIPSImage(contentsOfFile: path)
        XCTAssertEqual(loaded.width, 50)
        XCTAssertEqual(loaded.height, 50)
        XCTAssertEqual(loaded.sourceFormat, .jpeg)
    }

    func testWriteToFilePNG() throws {
        let image = createTestImage(width: 50, height: 50)
        let path = NSTemporaryDirectory() + "vipskit_test_write.png"
        defer { try? FileManager.default.removeItem(atPath: path) }
        try image.write(toFile: path)
        XCTAssertTrue(FileManager.default.fileExists(atPath: path))
        let loaded = try VIPSImage(contentsOfFile: path)
        XCTAssertEqual(loaded.sourceFormat, .png)
    }

    func testWriteToFileWebP() throws {
        let image = createTestImage(width: 50, height: 50)
        let path = NSTemporaryDirectory() + "vipskit_test_write.webp"
        defer { try? FileManager.default.removeItem(atPath: path) }
        try image.write(toFile: path)
        XCTAssertTrue(FileManager.default.fileExists(atPath: path))
        let loaded = try VIPSImage(contentsOfFile: path)
        XCTAssertEqual(loaded.sourceFormat, .webP)
    }

    func testWriteToFileTIFF() throws {
        let image = createTestImage(width: 50, height: 50)
        let path = NSTemporaryDirectory() + "vipskit_test_write.tif"
        defer { try? FileManager.default.removeItem(atPath: path) }
        try image.write(toFile: path)
        XCTAssertTrue(FileManager.default.fileExists(atPath: path))
        let loaded = try VIPSImage(contentsOfFile: path)
        XCTAssertEqual(loaded.sourceFormat, .tiff)
    }

    func testWriteToFileGIF() throws {
        let image = createTestImage(width: 50, height: 50)
        let path = NSTemporaryDirectory() + "vipskit_test_write.gif"
        defer { try? FileManager.default.removeItem(atPath: path) }
        try image.write(toFile: path)
        XCTAssertTrue(FileManager.default.fileExists(atPath: path))
        let loaded = try VIPSImage(contentsOfFile: path)
        XCTAssertEqual(loaded.sourceFormat, .gif)
    }

    // MARK: - write(toFile:format:quality:) — Explicit Format Per Format

    func testWriteToFileFormatJPEG() throws {
        let image = createTestImage(width: 50, height: 50)
        let path = NSTemporaryDirectory() + "vipskit_test_fmt.jpeg"
        defer { try? FileManager.default.removeItem(atPath: path) }
        try image.write(toFile: path, format: .jpeg, quality: 90)
        let loaded = try VIPSImage(contentsOfFile: path)
        XCTAssertEqual(loaded.width, 50)
        XCTAssertEqual(loaded.sourceFormat, .jpeg)
    }

    func testWriteToFileFormatPNG() throws {
        let image = createTestImage(width: 50, height: 50)
        let path = NSTemporaryDirectory() + "vipskit_test_fmt.png"
        defer { try? FileManager.default.removeItem(atPath: path) }
        try image.write(toFile: path, format: .png)
        let loaded = try VIPSImage(contentsOfFile: path)
        XCTAssertEqual(loaded.sourceFormat, .png)
    }

    func testWriteToFileFormatWebP() throws {
        let image = createTestImage(width: 50, height: 50)
        let path = NSTemporaryDirectory() + "vipskit_test_fmt.webp"
        defer { try? FileManager.default.removeItem(atPath: path) }
        try image.write(toFile: path, format: .webP, quality: 80)
        let loaded = try VIPSImage(contentsOfFile: path)
        XCTAssertEqual(loaded.sourceFormat, .webP)
    }

    func testWriteToFileFormatHEIFThrowsUnsupported() {
        let image = createTestImage(width: 50, height: 50)
        let path = NSTemporaryDirectory() + "vipskit_test_fmt.heic"
        XCTAssertThrowsError(try image.write(toFile: path, format: .heif))
    }

    func testWriteToFileFormatAVIFThrowsUnsupported() {
        let image = createTestImage(width: 50, height: 50)
        let path = NSTemporaryDirectory() + "vipskit_test_fmt.avif"
        XCTAssertThrowsError(try image.write(toFile: path, format: .avif))
    }

    func testWriteToFileFormatJXL() throws {
        let image = createTestImage(width: 50, height: 50)
        let path = NSTemporaryDirectory() + "vipskit_test_fmt.jxl"
        defer { try? FileManager.default.removeItem(atPath: path) }
        try image.write(toFile: path, format: .jxl, quality: 80)
        let loaded = try VIPSImage(contentsOfFile: path)
        XCTAssertEqual(loaded.sourceFormat, .jxl)
    }

    func testWriteToFileFormatGIF() throws {
        let image = createTestImage(width: 50, height: 50)
        let path = NSTemporaryDirectory() + "vipskit_test_fmt.gif"
        defer { try? FileManager.default.removeItem(atPath: path) }
        try image.write(toFile: path, format: .gif)
        let loaded = try VIPSImage(contentsOfFile: path)
        XCTAssertEqual(loaded.sourceFormat, .gif)
    }

    func testWriteToFileFormatTIFF() throws {
        let image = createTestImage(width: 50, height: 50)
        let path = NSTemporaryDirectory() + "vipskit_test_fmt.tif"
        defer { try? FileManager.default.removeItem(atPath: path) }
        try image.write(toFile: path, format: .tiff)
        let loaded = try VIPSImage(contentsOfFile: path)
        XCTAssertEqual(loaded.sourceFormat, .tiff)
    }

    func testWriteToFileFormatUnknownThrows() {
        let image = createTestImage(width: 50, height: 50)
        let path = NSTemporaryDirectory() + "vipskit_test_fmt.bin"
        XCTAssertThrowsError(try image.write(toFile: path, format: .unknown)) { error in
            XCTAssertTrue(error is VIPSError)
        }
    }

    // MARK: - write(toFile:format:quality:) — Quality Parameter

    func testWriteToFileJPEGQualityAffectsSize() throws {
        let image = createTestImage(width: 100, height: 100)
        let lowPath = NSTemporaryDirectory() + "vipskit_test_lowq.jpeg"
        let highPath = NSTemporaryDirectory() + "vipskit_test_highq.jpeg"
        defer {
            try? FileManager.default.removeItem(atPath: lowPath)
            try? FileManager.default.removeItem(atPath: highPath)
        }
        try image.write(toFile: lowPath, format: .jpeg, quality: 10)
        try image.write(toFile: highPath, format: .jpeg, quality: 95)
        let lowSize = try FileManager.default.attributesOfItem(atPath: lowPath)[.size] as! Int
        let highSize = try FileManager.default.attributesOfItem(atPath: highPath)[.size] as! Int
        XCTAssertLessThan(lowSize, highSize)
    }

    // MARK: - Round-Trip from Real Images

    func testRoundtripRealPNGToJPEG() throws {
        guard let path = pathForTestResource("test-rgb.png") else {
            XCTFail("Test resource not found")
            return
        }
        let source = try VIPSImage(contentsOfFile: path)
        let jpegData = try source.data(format: .jpeg, quality: 90)
        let loaded = try VIPSImage(data: jpegData)
        XCTAssertEqual(loaded.width, source.width)
        XCTAssertEqual(loaded.height, source.height)
        XCTAssertEqual(loaded.sourceFormat, .jpeg)
    }

    func testRoundtripRealPNGToWebP() throws {
        guard let path = pathForTestResource("test-rgb.png") else {
            XCTFail("Test resource not found")
            return
        }
        let source = try VIPSImage(contentsOfFile: path)
        let webpData = try source.data(format: .webP, quality: 85)
        let loaded = try VIPSImage(data: webpData)
        XCTAssertEqual(loaded.width, source.width)
        XCTAssertEqual(loaded.height, source.height)
        XCTAssertEqual(loaded.sourceFormat, .webP)
    }

    func testRoundtripWebPToJPEG() throws {
        guard let path = pathForTestResource("test.webp") else {
            XCTFail("Test resource not found")
            return
        }
        let source = try VIPSImage(contentsOfFile: path)
        let jpegData = try source.data(format: .jpeg, quality: 90)
        let loaded = try VIPSImage(data: jpegData)
        XCTAssertEqual(loaded.width, source.width)
        XCTAssertEqual(loaded.height, source.height)
        XCTAssertEqual(loaded.sourceFormat, .jpeg)
    }

    func testRoundtripGIFToPNG() throws {
        guard let path = pathForTestResource("test.gif") else {
            XCTFail("Test resource not found")
            return
        }
        let source = try VIPSImage(contentsOfFile: path)
        let pngData = try source.data(format: .png)
        let loaded = try VIPSImage(data: pngData)
        XCTAssertEqual(loaded.width, source.width)
        XCTAssertEqual(loaded.height, source.height)
        XCTAssertEqual(loaded.sourceFormat, .png)
    }

    // MARK: - Alpha Preservation

    func testDataPNGPreservesAlpha() throws {
        guard let path = pathForTestResource("test-rgba.png") else {
            XCTFail("Test resource not found")
            return
        }
        let source = try VIPSImage(contentsOfFile: path)
        XCTAssertTrue(source.hasAlpha)

        let data = try source.data(format: .png)
        let loaded = try VIPSImage(data: data)
        XCTAssertTrue(loaded.hasAlpha)
        XCTAssertEqual(loaded.bands, 4)
    }

    func testDataWebPPreservesAlpha() throws {
        guard let path = pathForTestResource("test-rgba.png") else {
            XCTFail("Test resource not found")
            return
        }
        let source = try VIPSImage(contentsOfFile: path)
        XCTAssertTrue(source.hasAlpha)

        let data = try source.data(format: .webP, quality: 90)
        let loaded = try VIPSImage(data: data)
        XCTAssertTrue(loaded.hasAlpha)
        XCTAssertEqual(loaded.bands, 4)
    }

    func testDataJXLPreservesAlpha() throws {
        let source = createTestImage(width: 50, height: 50, bands: 4)
        XCTAssertTrue(source.hasAlpha)
        let data = try source.data(format: .jxl, quality: 90)
        let loaded = try VIPSImage(data: data)
        XCTAssertTrue(loaded.hasAlpha)
    }

    func testDataTIFFPreservesAlpha() throws {
        let source = createTestImage(width: 50, height: 50, bands: 4)
        XCTAssertTrue(source.hasAlpha)
        let data = try source.data(format: .tiff)
        let loaded = try VIPSImage(data: data)
        XCTAssertTrue(loaded.hasAlpha)
    }

    // MARK: - Grayscale Handling

    func testSaveGrayscaleToJPEG() throws {
        guard let path = pathForTestResource("grayscale.jpg") else {
            XCTFail("Test resource not found")
            return
        }
        let source = try VIPSImage(contentsOfFile: path)
        XCTAssertEqual(source.bands, 1)

        let data = try source.data(format: .jpeg, quality: 85)
        let loaded = try VIPSImage(data: data)
        XCTAssertEqual(loaded.width, source.width)
        XCTAssertEqual(loaded.height, source.height)
    }

    func testSaveGrayscaleToPNG() throws {
        guard let path = pathForTestResource("grayscale.jpg") else {
            XCTFail("Test resource not found")
            return
        }
        let source = try VIPSImage(contentsOfFile: path)
        XCTAssertEqual(source.bands, 1)

        let data = try source.data(format: .png)
        let loaded = try VIPSImage(data: data)
        XCTAssertEqual(loaded.width, source.width)
        XCTAssertEqual(loaded.height, source.height)
    }

    // MARK: - Tiny Image Handling

    func testSaveTinyImage() throws {
        guard let path = pathForTestResource("tiny.png") else {
            XCTFail("Test resource not found")
            return
        }
        let source = try VIPSImage(contentsOfFile: path)
        XCTAssertEqual(source.width, 8)
        XCTAssertEqual(source.height, 8)

        let jpegData = try source.data(format: .jpeg, quality: 100)
        let pngData = try source.data(format: .png)
        let webpData = try source.data(format: .webP, quality: 100)

        XCTAssertGreaterThan(jpegData.count, 0)
        XCTAssertGreaterThan(pngData.count, 0)
        XCTAssertGreaterThan(webpData.count, 0)
    }

    // MARK: - Async

    func testAsyncWriteToFile() async throws {
        let image = createTestImage(width: 100, height: 100)
        let path = NSTemporaryDirectory() + "test_async_save.jpg"
        defer { try? FileManager.default.removeItem(atPath: path) }
        try await image.write(toFile: path)
        XCTAssertTrue(FileManager.default.fileExists(atPath: path))
    }

    func testAsyncWriteToFileWithFormat() async throws {
        let image = createTestImage(width: 100, height: 100)
        let path = NSTemporaryDirectory() + "test_async_save_explicit.png"
        defer { try? FileManager.default.removeItem(atPath: path) }
        try await image.write(toFile: path, format: .png)
        XCTAssertTrue(FileManager.default.fileExists(atPath: path))
    }

    func testAsyncEncoded() async throws {
        let image = createTestImage(width: 100, height: 100)
        let data = try await image.encoded(format: .jpeg, quality: 85)
        XCTAssertGreaterThan(data.count, 0)
        // Check JPEG magic bytes
        XCTAssertEqual(data[0], 0xFF)
        XCTAssertEqual(data[1], 0xD8)
    }
}
