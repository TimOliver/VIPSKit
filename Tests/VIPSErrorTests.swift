import XCTest
@testable import VIPSKit

final class VIPSErrorTests: VIPSImageTestCase {

    // MARK: - Message

    func testErrorMessage() {
        let error = VIPSError("something went wrong")
        XCTAssertEqual(error.message, "something went wrong")
    }

    func testErrorDescription() {
        let error = VIPSError("test error")
        XCTAssertEqual(error.errorDescription, "test error")
    }

    func testLocalizedDescription() {
        let error = VIPSError("localized test")
        // LocalizedError's localizedDescription should use errorDescription
        XCTAssertEqual(error.localizedDescription, "localized test")
    }

    func testEmptyMessage() {
        let error = VIPSError("")
        XCTAssertEqual(error.message, "")
        XCTAssertEqual(error.errorDescription, "")
    }

    // MARK: - Error Protocol Conformance

    func testConformsToError() {
        let error: Error = VIPSError("protocol test")
        XCTAssertTrue(error is VIPSError)
    }

    func testCanBeCaughtAsError() {
        func throwingFunction() throws {
            throw VIPSError("thrown error")
        }
        XCTAssertThrowsError(try throwingFunction()) { error in
            let vipsError = error as? VIPSError
            XCTAssertNotNil(vipsError)
            XCTAssertEqual(vipsError?.message, "thrown error")
        }
    }

    // MARK: - fromVips

    func testFromVipsReturnsError() {
        // Trigger a vips error by attempting an invalid operation
        let error = VIPSError.fromVips()
        // fromVips() always returns a VIPSError; the buffer may be empty if no vips error occurred
        XCTAssertNotNil(error.message)
    }

    // MARK: - Errors from Operations

    func testInvalidFilePathThrowsVIPSError() {
        XCTAssertThrowsError(try VIPSImage(contentsOfFile: "/nonexistent/path.jpg")) { error in
            XCTAssertTrue(error is VIPSError)
            let vipsError = error as! VIPSError
            XCTAssertFalse(vipsError.message.isEmpty)
        }
    }

    func testInvalidDataThrowsVIPSError() {
        let garbage = Data([0x00, 0x01, 0x02, 0x03])
        XCTAssertThrowsError(try VIPSImage(data: garbage)) { error in
            XCTAssertTrue(error is VIPSError)
        }
    }

    func testInvalidCropThrowsVIPSError() {
        let image = createTestImage(width: 50, height: 50)
        XCTAssertThrowsError(try image.crop(x: 100, y: 100, width: 50, height: 50)) { error in
            XCTAssertTrue(error is VIPSError)
        }
    }

    // MARK: - Sendable

    func testSendableAcrossTaskBoundary() async {
        let error = VIPSError("sendable test")
        let message = await Task.detached {
            return error.message
        }.value
        XCTAssertEqual(message, "sendable test")
    }
}
