import Foundation
internal import vips
internal import CVIPS

/// An error thrown by VIPSKit operations, containing a human-readable description
/// of what went wrong. Errors originating from libvips include the library's own
/// error message for debugging purposes.
public struct VIPSError: Error, LocalizedError, @unchecked Sendable {

    /// A human-readable description of the error
    public let message: String

    /// The localized description for this error, matching the ``message`` property.
    public var errorDescription: String? { message }

    /// Create a VIPSError with a custom message.
    /// - Parameter message: A description of what went wrong
    internal init(_ message: String) {
        self.message = message
    }

    /// Create a VIPSError from the current libvips error buffer, then clear it.
    /// - Returns: A new error containing the libvips error message
    internal static func fromVips() -> VIPSError {
        let msg = String(cString: vips_error_buffer())
        vips_error_clear()
        return VIPSError(msg)
    }
}
