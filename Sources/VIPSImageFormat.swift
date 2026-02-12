/// Supported image formats for loading, saving, and format detection.
public enum VIPSImageFormat: Int, Sendable {
    /// Format could not be detected or is not supported
    case unknown = -1
    /// JPEG format (lossy compression, quality 1-100)
    case jpeg = 0
    /// PNG format (lossless compression, quality parameter ignored)
    case png
    /// WebP format (lossy or lossless, quality 1-100)
    case webP
    /// HEIF format (lossy compression, quality 1-100)
    case heif
    /// AVIF format (AV1-based, lossy compression, quality 1-100)
    case avif
    /// JPEG XL format (lossy or lossless, quality 1-100)
    case jxl
    /// GIF format (palette-based, quality parameter ignored)
    case gif
    /// TIFF format (lossless, quality parameter ignored)
    case tiff

    /// A human-readable label for this format, suitable for debug output.
    internal var debugLabel: String {
        switch self {
        case .unknown: return "Unknown"
        case .jpeg:    return "JPEG"
        case .png:     return "PNG"
        case .webP:    return "WebP"
        case .heif:    return "HEIF"
        case .avif:    return "AVIF"
        case .jxl:     return "JPEG XL"
        case .gif:     return "GIF"
        case .tiff:    return "TIFF"
        }
    }

    /// The standard file extension associated with this format, or `nil` for unknown formats.
    public var fileExtension: String? {
        switch self {
        case .unknown: return nil
        case .jpeg:    return "jpg"
        case .png:     return "png"
        case .webP:    return "webp"
        case .heif:    return "heic"
        case .avif:    return "avif"
        case .jxl:     return "jxl"
        case .gif:     return "gif"
        case .tiff:    return "tif"
        }
    }
}
