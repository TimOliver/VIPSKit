/// Blend modes for image compositing.
public enum VIPSBlendMode: Int, Sendable {
    case clear = 0
    case source
    case over
    case `in`
    case out
    case atop
    case dest
    case destOver
    case destIn
    case destOut
    case destAtop
    case xor
    case add
    case saturate
    case multiply
    case screen
    case overlay
    case darken
    case lighten
    case colourDodge
    case colourBurn
    case hardLight
    case softLight
    case difference
    case exclusion
}
