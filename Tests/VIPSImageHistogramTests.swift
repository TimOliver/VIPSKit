import XCTest
@testable import VIPSKit

final class VIPSImageHistogramTests: VIPSImageTestCase {

    func testEqualizeHistogram() throws {
        let image = createTestImage(width: 100, height: 100)
        let equalized = try image.histogramEqualized()
        XCTAssertEqual(equalized.width, 100)
        XCTAssertEqual(equalized.height, 100)
        XCTAssertEqual(equalized.bands, image.bands)
    }

    func testEqualizeHistogramDarkImage() throws {
        // Create a dark image (all pixels near 0)
        let image = createSolidColorImage(width: 50, height: 50, r: 10, g: 10, b: 10)
        let equalized = try image.histogramEqualized()
        XCTAssertEqual(equalized.width, 50)
        XCTAssertEqual(equalized.height, 50)
    }

    func testEqualizeHistogramGrayscale() throws {
        let image = createTestImage(width: 80, height: 80)
        let gray = try image.grayscaled()
        let equalized = try gray.histogramEqualized()
        XCTAssertEqual(equalized.width, 80)
        XCTAssertEqual(equalized.height, 80)
    }

    // MARK: - Async

    func testAsyncHistogramEqualized() async throws {
        let image = createTestImage(width: 100, height: 100)
        let equalized = try await image.histogramEqualized()
        XCTAssertEqual(equalized.width, 100)
        XCTAssertEqual(equalized.height, 100)
        XCTAssertEqual(equalized.bands, image.bands)
    }
}
