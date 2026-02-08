/// Resize kernel/interpolation method.
public enum VIPSResizeKernel: Int, Sendable {
    case nearest = 0
    case linear
    case cubic
    case lanczos2
    case lanczos3
}
