import XCTest
@testable import VIPSKit

final class VIPSImageResizeTests: VIPSImageTestCase {

    func testResizeToFit() throws {
        let image = createTestImage(width: 200, height: 100)
        let resized = try image.resizeToFit(width: 100, height: 100)
        XCTAssertLessThanOrEqual(resized.width, 100)
        XCTAssertLessThanOrEqual(resized.height, 100)
    }

    func testResizeToFitMaintainsAspect() throws {
        let image = createTestImage(width: 200, height: 100)
        let resized = try image.resizeToFit(width: 50, height: 50)
        XCTAssertEqual(resized.width, 50)
        XCTAssertEqual(resized.height, 25)
    }

    func testResizeByScale() throws {
        let image = createTestImage(width: 100, height: 100)
        let resized = try image.resize(scale: 0.5)
        XCTAssertEqual(resized.width, 50)
        XCTAssertEqual(resized.height, 50)
    }

    func testResizeByScaleUp() throws {
        let image = createTestImage(width: 50, height: 50)
        let resized = try image.resize(scale: 2.0)
        XCTAssertEqual(resized.width, 100)
        XCTAssertEqual(resized.height, 100)
    }

    func testResizeToExact() throws {
        let image = createTestImage(width: 100, height: 100)
        let resized = try image.resize(toWidth: 200, height: 50)
        XCTAssertEqual(resized.width, 200)
        XCTAssertEqual(resized.height, 50)
    }

    func testResizeKernelNearest() throws {
        let image = createTestImage(width: 100, height: 100)
        let resized = try image.resize(scale: 0.5, kernel: .nearest)
        XCTAssertEqual(resized.width, 50)
    }

    func testResizeKernelLinear() throws {
        let image = createTestImage(width: 100, height: 100)
        let resized = try image.resize(scale: 0.5, kernel: .linear)
        XCTAssertEqual(resized.width, 50)
    }

    func testResizeKernelCubic() throws {
        let image = createTestImage(width: 100, height: 100)
        let resized = try image.resize(scale: 0.5, kernel: .cubic)
        XCTAssertEqual(resized.width, 50)
    }

    func testResizeKernelLanczos2() throws {
        let image = createTestImage(width: 100, height: 100)
        let resized = try image.resize(scale: 0.5, kernel: .lanczos2)
        XCTAssertEqual(resized.width, 50)
    }

    func testResizeChain() throws {
        let image = createTestImage(width: 200, height: 200)
        let step1 = try image.resize(scale: 0.5)
        let step2 = try step1.resize(scale: 0.5)
        XCTAssertEqual(step2.width, 50)
        XCTAssertEqual(step2.height, 50)
    }

    // MARK: - Async

    func testAsyncResizedToFit() async throws {
        let image = createTestImage(width: 200, height: 100)
        let resized = try await image.resizedToFit(width: 50, height: 50)
        XCTAssertEqual(resized.width, 50)
        XCTAssertEqual(resized.height, 25)
    }

    func testAsyncResizedToFitCGSize() async throws {
        let image = createTestImage(width: 200, height: 100)
        let resized = try await image.resizedToFit(size: CGSize(width: 50, height: 50))
        XCTAssertEqual(resized.width, 50)
        XCTAssertEqual(resized.height, 25)
    }

    func testAsyncResizedByScale() async throws {
        let image = createTestImage(width: 100, height: 100)
        let resized = try await image.resized(scale: 0.5)
        XCTAssertEqual(resized.width, 50)
        XCTAssertEqual(resized.height, 50)
    }

    func testAsyncResizedToExact() async throws {
        let image = createTestImage(width: 100, height: 100)
        let resized = try await image.resized(toWidth: 200, height: 50)
        XCTAssertEqual(resized.width, 200)
        XCTAssertEqual(resized.height, 50)
    }

    func testAsyncResizedToCGSize() async throws {
        let image = createTestImage(width: 100, height: 100)
        let resized = try await image.resized(to: CGSize(width: 200, height: 50))
        XCTAssertEqual(resized.width, 200)
        XCTAssertEqual(resized.height, 50)
    }
}
