import Foundation
@_implementationOnly import vips
@_implementationOnly import CVIPS

extension VIPSImage {

    /// Export as lossless WebP for disk caching (~30% smaller than PNG).
    public func cacheData() throws -> Data {
        return try cacheData(format: .webP, quality: 0, lossless: true)
    }

    /// Export for caching with explicit format control.
    public func cacheData(format: ImageFormat, quality: Int = 0, lossless: Bool = true) throws -> Data {
        var buffer: UnsafeMutableRawPointer?
        var length: Int = 0
        let result: Int32

        switch format {
        case .jpeg:
            result = cvips_jpegsave_buffer(pointer, &buffer, &length, Int32(quality))
        case .png:
            result = cvips_pngsave_buffer(pointer, &buffer, &length)
        case .webP:
            if lossless {
                result = cvips_webpsave_buffer_lossless(pointer, &buffer, &length)
            } else {
                result = cvips_webpsave_buffer(pointer, &buffer, &length, Int32(quality))
            }
        case .heif:
            result = cvips_heifsave_buffer(pointer, &buffer, &length, Int32(quality))
        case .avif:
            result = cvips_avifsave_buffer(pointer, &buffer, &length, Int32(quality))
        case .jxl:
            if lossless {
                result = cvips_jxlsave_buffer_lossless(pointer, &buffer, &length)
            } else {
                result = cvips_jxlsave_buffer(pointer, &buffer, &length, Int32(quality))
            }
        case .gif:
            result = cvips_gifsave_buffer(pointer, &buffer, &length)
        case .unknown:
            throw VIPSError("Unknown format for cache export")
        }

        guard result == 0, let buffer else { throw VIPSError.fromVips() }
        defer { g_free(buffer) }
        return Data(bytes: buffer, count: length)
    }

    /// Write as lossless WebP cache file (auto-appends .webp extension).
    public func writeToCache(file path: String) throws {
        try writeToCache(file: path, format: .webP, quality: 0, lossless: true)
    }

    /// Write cache file with explicit format control.
    public func writeToCache(file path: String, format: ImageFormat, quality: Int = 0, lossless: Bool = true) throws {
        var finalPath = path
        if let ext = format.fileExtension,
           (path as NSString).pathExtension.lowercased() != ext {
            finalPath = (path as NSString).appendingPathExtension(ext) ?? path
        }

        let result: Int32
        switch format {
        case .jpeg:    result = cvips_jpegsave(pointer, finalPath, Int32(quality))
        case .png:     result = cvips_pngsave(pointer, finalPath)
        case .webP:
            if lossless {
                result = cvips_webpsave_lossless(pointer, finalPath)
            } else {
                result = cvips_webpsave(pointer, finalPath, Int32(quality))
            }
        case .heif:    result = cvips_heifsave(pointer, finalPath, Int32(quality))
        case .avif:    result = cvips_avifsave(pointer, finalPath, Int32(quality))
        case .jxl:
            if lossless {
                result = cvips_jxlsave_lossless(pointer, finalPath)
            } else {
                result = cvips_jxlsave(pointer, finalPath, Int32(quality))
            }
        case .gif:     result = cvips_gifsave(pointer, finalPath)
        case .unknown: throw VIPSError("Unknown format for cache export")
        }

        guard result == 0 else { throw VIPSError.fromVips() }
    }
}
