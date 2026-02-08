import Foundation
internal import vips
internal import CVIPS

/// Error type for VIPSKit operations.
public struct VIPSError: Error, LocalizedError, @unchecked Sendable {
    public let message: String

    public var errorDescription: String? { message }

    internal init(_ message: String) {
        self.message = message
    }

    /// Create a VIPSError from the current vips error buffer, then clear it.
    internal static func fromVips() -> VIPSError {
        let msg = String(cString: vips_error_buffer())
        vips_error_clear()
        return VIPSError(msg)
    }
}
