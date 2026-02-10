import Foundation
internal import vips
internal import CVIPS

extension VIPSImage {

    // MARK: - File Saving

    /// Save the image to a file, inferring the format from the file extension.
    /// Supported extensions include `.jpg`, `.png`, `.webp`, `.jxl`, `.gif`, and `.tif`.
    /// - Parameter path: The destination file path (the extension determines the format)
    public func write(toFile path: String) throws {
        guard cvips_write_to_file(pointer, path) == 0 else {
            throw VIPSError.fromVips()
        }
    }

    /// Save the image to a file with an explicit format and quality setting.
    /// HEIF and AVIF encoding are not supported (decode-only); attempting to save
    /// in those formats will throw an error.
    /// - Parameters:
    ///   - path: The destination file path
    ///   - format: The image format to encode as
    ///   - quality: The encoding quality (1-100). Ignored for PNG, GIF, and TIFF formats. (Default is 85)
    public func write(toFile path: String, format: VIPSImageFormat, quality: Int = 85) throws {
        let result: Int32
        switch format {
        case .jpeg:    result = cvips_jpegsave(pointer, path, Int32(quality))
        case .png:     result = cvips_pngsave(pointer, path)
        case .webP:    result = cvips_webpsave(pointer, path, Int32(quality))
        case .jxl:     result = cvips_jxlsave(pointer, path, Int32(quality))
        case .gif:     result = cvips_gifsave(pointer, path)
        case .tiff:    result = cvips_tiffsave(pointer, path)
        case .heif:    throw VIPSError("HEIF encoding is not supported (decode-only)")
        case .avif:    throw VIPSError("AVIF encoding is not supported (decode-only)")
        case .unknown: throw VIPSError("Unknown format for saving")
        }
        guard result == 0 else { throw VIPSError.fromVips() }
    }

    // MARK: - Data Export

    /// Export the image as encoded data in the specified format.
    /// HEIF and AVIF encoding are not supported (decode-only); attempting to export
    /// in those formats will throw an error.
    /// - Parameters:
    ///   - format: The image format to encode as
    ///   - quality: The encoding quality (1-100). Ignored for PNG, GIF, and TIFF formats. (Default is 85)
    /// - Returns: The encoded image data
    public func data(format: VIPSImageFormat, quality: Int = 85) throws -> Data {
        var buffer: UnsafeMutableRawPointer?
        var length: Int = 0
        let result: Int32

        switch format {
        case .jpeg:    result = cvips_jpegsave_buffer(pointer, &buffer, &length, Int32(quality))
        case .png:     result = cvips_pngsave_buffer(pointer, &buffer, &length)
        case .webP:    result = cvips_webpsave_buffer(pointer, &buffer, &length, Int32(quality))
        case .jxl:     result = cvips_jxlsave_buffer(pointer, &buffer, &length, Int32(quality))
        case .gif:     result = cvips_gifsave_buffer(pointer, &buffer, &length)
        case .tiff:    result = cvips_tiffsave_buffer(pointer, &buffer, &length)
        case .heif:    throw VIPSError("HEIF encoding is not supported (decode-only)")
        case .avif:    throw VIPSError("AVIF encoding is not supported (decode-only)")
        case .unknown: throw VIPSError("Unknown format for export")
        }

        guard result == 0, let buffer else { throw VIPSError.fromVips() }
        defer { g_free(buffer) }
        return Data(bytes: buffer, count: length)
    }

    // MARK: - Async

    /// Save the image to a file, inferring the format from the file extension.
    /// Supported extensions include `.jpg`, `.png`, `.webp`, `.jxl`, `.gif`, and `.tif`.
    /// The work is performed off the calling actor via `Task.detached`.
    /// - Parameter path: The destination file path (the extension determines the format)
    public func write(toFile path: String) async throws {
        try await Task.detached {
            try self.write(toFile: path)
        }.value
    }

    /// Save the image to a file with an explicit format and quality setting.
    /// The work is performed off the calling actor via `Task.detached`.
    /// - Parameters:
    ///   - path: The destination file path
    ///   - format: The image format to encode as
    ///   - quality: The encoding quality (1-100). Ignored for PNG and GIF formats. (Default is 85)
    public func write(toFile path: String, format: VIPSImageFormat, quality: Int = 85) async throws {
        try await Task.detached {
            try self.write(toFile: path, format: format, quality: quality)
        }.value
    }

    /// Export the image as encoded data in the specified format.
    /// The work is performed off the calling actor via `Task.detached`.
    /// - Parameters:
    ///   - format: The image format to encode as
    ///   - quality: The encoding quality (1-100). Ignored for PNG and GIF formats. (Default is 85)
    /// - Returns: The encoded image data
    public func encoded(format: VIPSImageFormat, quality: Int = 85) async throws -> Data {
        try await Task.detached {
            try self.data(format: format, quality: quality)
        }.value
    }
}
