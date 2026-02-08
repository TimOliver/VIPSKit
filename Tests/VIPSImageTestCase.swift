import XCTest
@testable import VIPSKit

class VIPSImageTestCase: XCTestCase {

    private static var initialized = false

    override func setUp() {
        super.setUp()
        if !Self.initialized {
            XCTAssertNoThrow(try VIPSImage.initialize())
            Self.initialized = true
        }
    }

    // MARK: - Helpers

    func pathForTestResource(_ filename: String) -> String? {
        let bundle = Bundle(for: type(of: self))
        let name = (filename as NSString).deletingPathExtension
        let ext = (filename as NSString).pathExtension
        if let path = bundle.path(forResource: name, ofType: ext) {
            return path
        }
        let fallback = "/Users/TiM/Developer/VIPSKit/Tests/TestResources/\(filename)"
        if FileManager.default.fileExists(atPath: fallback) {
            return fallback
        }
        return nil
    }

    func createTestImage(width: Int, height: Int, bands: Int = 3) -> VIPSImage {
        var buffer = [UInt8](repeating: 0, count: width * height * bands)
        for y in 0..<height {
            for x in 0..<width {
                let idx = (y * width + x) * bands
                buffer[idx] = UInt8(x * 255 / max(width - 1, 1))
                if bands >= 2 { buffer[idx + 1] = UInt8(y * 255 / max(height - 1, 1)) }
                if bands >= 3 { buffer[idx + 2] = 128 }
                if bands >= 4 { buffer[idx + 3] = 200 }
            }
        }
        return try! VIPSImage(buffer: &buffer, width: width, height: height, bands: bands)
    }

    func createSolidColorImage(width: Int, height: Int, r: UInt8, g: UInt8, b: UInt8) -> VIPSImage {
        var buffer = [UInt8](repeating: 0, count: width * height * 3)
        for i in 0..<(width * height) {
            buffer[i * 3] = r; buffer[i * 3 + 1] = g; buffer[i * 3 + 2] = b
        }
        return try! VIPSImage(buffer: &buffer, width: width, height: height, bands: 3)
    }

    func createSolidColorImage(width: Int, height: Int, r: UInt8, g: UInt8, b: UInt8, a: UInt8) -> VIPSImage {
        var buffer = [UInt8](repeating: 0, count: width * height * 4)
        for i in 0..<(width * height) {
            buffer[i * 4] = r; buffer[i * 4 + 1] = g; buffer[i * 4 + 2] = b; buffer[i * 4 + 3] = a
        }
        return try! VIPSImage(buffer: &buffer, width: width, height: height, bands: 4)
    }

    func createImageWithMargins(width: Int, height: Int, margin: Int,
                                contentR: UInt8, contentG: UInt8, contentB: UInt8,
                                bgR: UInt8, bgG: UInt8, bgB: UInt8) -> VIPSImage {
        var buffer = [UInt8](repeating: 0, count: width * height * 3)
        for y in 0..<height {
            for x in 0..<width {
                let idx = (y * width + x) * 3
                let inMargin = x < margin || x >= width - margin || y < margin || y >= height - margin
                if inMargin {
                    buffer[idx] = bgR; buffer[idx + 1] = bgG; buffer[idx + 2] = bgB
                } else {
                    buffer[idx] = contentR; buffer[idx + 1] = contentG; buffer[idx + 2] = contentB
                }
            }
        }
        return try! VIPSImage(buffer: &buffer, width: width, height: height, bands: 3)
    }

    func createHorizontalGradient(width: Int, height: Int,
                                  startR: UInt8, startG: UInt8, startB: UInt8,
                                  endR: UInt8, endG: UInt8, endB: UInt8) -> VIPSImage {
        var buffer = [UInt8](repeating: 0, count: width * height * 3)
        for y in 0..<height {
            for x in 0..<width {
                let idx = (y * width + x) * 3
                let t = Double(x) / Double(max(width - 1, 1))
                buffer[idx] = UInt8(Double(startR) + t * Double(Int(endR) - Int(startR)))
                buffer[idx + 1] = UInt8(Double(startG) + t * Double(Int(endG) - Int(startG)))
                buffer[idx + 2] = UInt8(Double(startB) + t * Double(Int(endB) - Int(startB)))
            }
        }
        return try! VIPSImage(buffer: &buffer, width: width, height: height, bands: 3)
    }
}
