import Foundation
@_implementationOnly import vips
@_implementationOnly import CVIPS

extension VIPSImage {

    // MARK: - File Saving

    /// Save to file (format inferred from extension).
    public func write(toFile path: String) throws {
        guard cvips_write_to_file(pointer, path) == 0 else {
            throw VIPSError.fromVips()
        }
    }

    /// Save to file with explicit format and quality.
    public func write(toFile path: String, format: ImageFormat, quality: Int = 85) throws {
        let result: Int32
        switch format {
        case .jpeg:    result = cvips_jpegsave(pointer, path, Int32(quality))
        case .png:     result = cvips_pngsave(pointer, path)
        case .webP:    result = cvips_webpsave(pointer, path, Int32(quality))
        case .heif:    result = cvips_heifsave(pointer, path, Int32(quality))
        case .avif:    result = cvips_avifsave(pointer, path, Int32(quality))
        case .jxl:     result = cvips_jxlsave(pointer, path, Int32(quality))
        case .gif:     result = cvips_gifsave(pointer, path)
        case .unknown: throw VIPSError("Unknown format for saving")
        }
        guard result == 0 else { throw VIPSError.fromVips() }
    }

    // MARK: - Data Export

    /// Export to Data in the specified format.
    public func data(format: ImageFormat, quality: Int = 85) throws -> Data {
        var buffer: UnsafeMutableRawPointer?
        var length: Int = 0
        let result: Int32

        switch format {
        case .jpeg:    result = cvips_jpegsave_buffer(pointer, &buffer, &length, Int32(quality))
        case .png:     result = cvips_pngsave_buffer(pointer, &buffer, &length)
        case .webP:    result = cvips_webpsave_buffer(pointer, &buffer, &length, Int32(quality))
        case .heif:    result = cvips_heifsave_buffer(pointer, &buffer, &length, Int32(quality))
        case .avif:    result = cvips_avifsave_buffer(pointer, &buffer, &length, Int32(quality))
        case .jxl:     result = cvips_jxlsave_buffer(pointer, &buffer, &length, Int32(quality))
        case .gif:     result = cvips_gifsave_buffer(pointer, &buffer, &length)
        case .unknown: throw VIPSError("Unknown format for export")
        }

        guard result == 0, let buffer else { throw VIPSError.fromVips() }
        defer { g_free(buffer) }
        return Data(bytes: buffer, count: length)
    }
}
