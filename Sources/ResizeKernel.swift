/// Resize kernel/interpolation method.
public enum ResizeKernel: Int, Sendable {
    case nearest = 0
    case linear
    case cubic
    case lanczos2
    case lanczos3
}
