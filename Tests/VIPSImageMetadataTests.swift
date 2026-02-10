import XCTest
@testable import VIPSKit

final class VIPSImageMetadataTests: VIPSImageTestCase {

    // MARK: - Generic Metadata

    func testSetAndGetString() {
        let image = createTestImage(width: 100, height: 100)
        image.setString(named: "test-string", value: "hello world")
        XCTAssertEqual(image.getString(named: "test-string"), "hello world")
    }

    func testSetAndGetInt() {
        let image = createTestImage(width: 100, height: 100)
        image.setInt(named: "test-int", value: 42)
        XCTAssertEqual(image.getInt(named: "test-int"), 42)
    }

    func testSetAndGetDouble() {
        let image = createTestImage(width: 100, height: 100)
        image.setDouble(named: "test-double", value: 3.14)
        let value = image.getDouble(named: "test-double")
        XCTAssertNotNil(value)
        XCTAssertEqual(value!, 3.14, accuracy: 0.001)
    }

    func testGetNonExistentField() {
        let image = createTestImage(width: 100, height: 100)
        XCTAssertNil(image.getString(named: "does-not-exist"))
        XCTAssertNil(image.getInt(named: "does-not-exist"))
        XCTAssertNil(image.getDouble(named: "does-not-exist"))
        XCTAssertNil(image.getBlob(named: "does-not-exist"))
    }

    func testHasMetadata() {
        let image = createTestImage(width: 100, height: 100)
        image.setString(named: "test-exists", value: "yes")
        XCTAssertTrue(image.hasMetadata(named: "test-exists"))
        XCTAssertFalse(image.hasMetadata(named: "test-missing"))
    }

    func testRemoveMetadata() {
        let image = createTestImage(width: 100, height: 100)
        image.setString(named: "test-remove", value: "value")
        XCTAssertTrue(image.hasMetadata(named: "test-remove"))
        let removed = image.removeMetadata(named: "test-remove")
        XCTAssertTrue(removed)
        XCTAssertFalse(image.hasMetadata(named: "test-remove"))
    }

    func testRemoveNonExistentMetadata() {
        let image = createTestImage(width: 100, height: 100)
        let removed = image.removeMetadata(named: "never-existed")
        XCTAssertFalse(removed)
    }

    // MARK: - Fields Listing

    func testMetadataFields() {
        let image = createTestImage(width: 100, height: 100)
        let fields = image.metadataFields
        XCTAssertFalse(fields.isEmpty)
        // Synthetic images should have at least basic fields like "width", "coding", "format"
        XCTAssertTrue(fields.contains("width") || fields.contains("coding"))
    }

    func testMetadataFieldsIncludesCustom() {
        let image = createTestImage(width: 100, height: 100)
        image.setString(named: "custom-field", value: "custom-value")
        let fields = image.metadataFields
        XCTAssertTrue(fields.contains("custom-field"))
    }

    // MARK: - High-Level Properties (Synthetic Images)

    func testOrientationNilForSyntheticImage() {
        let image = createTestImage(width: 100, height: 100)
        // Synthetic images have no EXIF orientation
        XCTAssertNil(image.orientation)
    }

    func testResolution() {
        let image = createTestImage(width: 100, height: 100)
        // Resolution should be some non-negative value
        XCTAssertGreaterThanOrEqual(image.xResolution, 0)
        XCTAssertGreaterThanOrEqual(image.yResolution, 0)
    }

    func testPageCountDefaultsToOne() {
        let image = createTestImage(width: 100, height: 100)
        XCTAssertEqual(image.pageCount, 1)
    }

    func testPageHeightNilForSinglePage() {
        let image = createTestImage(width: 100, height: 100)
        XCTAssertNil(image.pageHeight)
    }

    func testExifDataNilForSyntheticImage() {
        let image = createTestImage(width: 100, height: 100)
        XCTAssertNil(image.exifData)
    }

    func testIccProfileNilForSyntheticImage() {
        let image = createTestImage(width: 100, height: 100)
        XCTAssertNil(image.iccProfile)
    }

    // MARK: - JPEG EXIF Metadata

    func testJPEGMetadataFields() throws {
        guard let path = pathForTestResource("superman.jpg") else {
            XCTFail("Test resource superman.jpg not found")
            return
        }
        let image = try VIPSImage(contentsOfFile: path)
        let fields = image.metadataFields
        XCTAssertFalse(fields.isEmpty)
        // JPEG images should have EXIF-related fields
        XCTAssertTrue(fields.count > 5, "JPEG should have many metadata fields, got \(fields.count)")
    }

    func testJPEGOrientation() throws {
        guard let path = pathForTestResource("superman.jpg") else {
            XCTFail("Test resource superman.jpg not found")
            return
        }
        let image = try VIPSImage(contentsOfFile: path)
        // Orientation may or may not be present depending on the JPEG
        if let orientation = image.orientation {
            XCTAssertTrue((1...8).contains(orientation), "Orientation should be 1-8, got \(orientation)")
        }
    }

    func testJPEGResolution() throws {
        guard let path = pathForTestResource("superman.jpg") else {
            XCTFail("Test resource superman.jpg not found")
            return
        }
        let image = try VIPSImage(contentsOfFile: path)
        // JPEG images typically have resolution metadata
        XCTAssertGreaterThan(image.xResolution, 0)
        XCTAssertGreaterThan(image.yResolution, 0)
    }

    func testJPEGIccProfile() throws {
        guard let path = pathForTestResource("superman.jpg") else {
            XCTFail("Test resource superman.jpg not found")
            return
        }
        let image = try VIPSImage(contentsOfFile: path)
        // ICC profile may or may not be present
        if let icc = image.iccProfile {
            XCTAssertGreaterThan(icc.count, 0)
        }
    }

    func testJPEGExifField() throws {
        guard let path = pathForTestResource("superman.jpg") else {
            XCTFail("Test resource superman.jpg not found")
            return
        }
        let image = try VIPSImage(contentsOfFile: path)
        // Try reading some common EXIF fields — they may or may not exist
        // depending on the test image, but the method should not crash
        _ = image.exifField("Make")
        _ = image.exifField("Model")
        _ = image.exifField("DateTime")
        _ = image.exifField("Software")
    }

    func testJPEGExifData() throws {
        guard let path = pathForTestResource("superman.jpg") else {
            XCTFail("Test resource superman.jpg not found")
            return
        }
        let image = try VIPSImage(contentsOfFile: path)
        // EXIF data may or may not be present depending on the JPEG
        if let exif = image.exifData {
            XCTAssertGreaterThan(exif.count, 0)
        }
    }

    // MARK: - Set Orientation

    func testSetAndGetOrientation() {
        let image = createTestImage(width: 100, height: 100)
        image.setInt(named: "orientation", value: 6)
        XCTAssertEqual(image.orientation, 6)
    }

    // MARK: - EXIF Orientation from Real Images

    func testOrientationFromRotated6Image() throws {
        guard let path = pathForTestResource("rotated-6.jpg") else {
            XCTFail("Test resource rotated-6.jpg not found")
            return
        }
        let image = try VIPSImage(contentsOfFile: path)
        XCTAssertEqual(image.orientation, 6)
    }

    func testOrientationFromRotated3Image() throws {
        guard let path = pathForTestResource("rotated-3.jpg") else {
            XCTFail("Test resource rotated-3.jpg not found")
            return
        }
        let image = try VIPSImage(contentsOfFile: path)
        XCTAssertEqual(image.orientation, 3)
    }

    func testOrientationNilForNonRotatedImage() throws {
        // PNG files typically don't have EXIF orientation
        guard let path = pathForTestResource("test-rgb.png") else {
            XCTFail("Test resource test-rgb.png not found")
            return
        }
        let image = try VIPSImage(contentsOfFile: path)
        // PNG should not have orientation metadata
        XCTAssertNil(image.orientation)
    }

    func testOrientationFromTestJPEG() throws {
        // test.jpg was created without explicit orientation, should be nil or 1
        guard let path = pathForTestResource("test.jpg") else {
            XCTFail("Test resource test.jpg not found")
            return
        }
        let image = try VIPSImage(contentsOfFile: path)
        // Either nil (not set) or 1 (normal) is acceptable
        if let orientation = image.orientation {
            XCTAssertEqual(orientation, 1)
        }
    }
}
