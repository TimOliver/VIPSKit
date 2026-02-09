import XCTest
@testable import VIPSKit

final class VIPSImageRotateTests: VIPSImageTestCase {

    func testRotate45Degrees() throws {
        let image = createTestImage(width: 100, height: 100)
        let rotated = try image.rotate(byAngle: 45.0)
        // Rotated image should be larger to contain the full rotated content
        XCTAssertGreaterThan(rotated.width, 100)
        XCTAssertGreaterThan(rotated.height, 100)
    }

    func testRotate90Degrees() throws {
        let image = createTestImage(width: 100, height: 50)
        let rotated = try image.rotate(byAngle: 90.0)
        // 90-degree rotation should swap dimensions (approximately)
        XCTAssertGreaterThanOrEqual(rotated.width, 49)
        XCTAssertGreaterThanOrEqual(rotated.height, 99)
    }

    func testRotate0Degrees() throws {
        let image = createTestImage(width: 100, height: 100)
        let rotated = try image.rotate(byAngle: 0.0)
        XCTAssertEqual(rotated.width, 100)
        XCTAssertEqual(rotated.height, 100)
    }

    func testRotateNegativeAngle() throws {
        let image = createTestImage(width: 80, height: 80)
        let rotated = try image.rotate(byAngle: -30.0)
        XCTAssertGreaterThan(rotated.width, 80)
        XCTAssertGreaterThan(rotated.height, 80)
    }

    func testRotate180Degrees() throws {
        let image = createTestImage(width: 60, height: 40)
        let rotated = try image.rotate(byAngle: 180.0)
        // 180-degree rotation should preserve dimensions (approximately)
        XCTAssertGreaterThanOrEqual(rotated.width, 59)
        XCTAssertGreaterThanOrEqual(rotated.height, 39)
    }
}
