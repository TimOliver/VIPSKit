internal import vips

/// Blend modes for compositing one image over another.
/// These correspond to the Porter-Duff compositing operators
/// and common Photoshop-style blend modes supported by libvips.
public enum VIPSBlendMode: Int, Sendable {
    /// Clear both source and destination
    case clear = 0
    /// Display only the source image
    case source
    /// Standard alpha compositing (most common for overlays and watermarks)
    case over
    /// Show source only where destination is opaque
    case `in`
    /// Show source only where destination is transparent
    case out
    /// Show source over destination, using destination's alpha
    case atop
    /// Display only the destination image
    case dest
    /// Place destination over source
    case destOver
    /// Show destination only where source is opaque
    case destIn
    /// Show destination only where source is transparent
    case destOut
    /// Show destination over source, using source's alpha
    case destAtop
    /// Show pixels where only one of source or destination is opaque
    case xor
    /// Add source and destination colors together
    case add
    /// Show whichever of source or destination is more opaque
    case saturate
    /// Multiply source and destination colors (darkening effect)
    case multiply
    /// Inverse multiply (lightening effect)
    case screen
    /// Multiply or screen based on base color
    case overlay
    /// Keep the darker pixel from source and destination
    case darken
    /// Keep the lighter pixel from source and destination
    case lighten
    /// Brighten destination based on source (dodge effect)
    case colourDodge
    /// Darken destination based on source (burn effect)
    case colourBurn
    /// Strong contrast adjustment
    case hardLight
    /// Subtle contrast adjustment
    case softLight
    /// Absolute difference between source and destination
    case difference
    /// Similar to difference but with lower contrast
    case exclusion

    /// The corresponding libvips `VipsBlendMode` value.
    internal var vipsValue: VipsBlendMode {
        VipsBlendMode(rawValue: UInt32(rawValue))
    }
}
