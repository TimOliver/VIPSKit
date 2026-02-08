/// Image format for saving and detection.
public enum ImageFormat: Int, Sendable {
    case unknown = -1
    case jpeg = 0
    case png
    case webP
    case heif
    case avif
    case jxl
    case gif

    /// File extension for this format.
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
        }
    }
}
