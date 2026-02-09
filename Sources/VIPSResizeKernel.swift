/// Interpolation kernels used when resizing images.
/// Higher quality kernels produce sharper results but are slower to compute.
public enum VIPSResizeKernel: Int, Sendable {
    /// Nearest-neighbor interpolation. Fastest, but produces blocky results. Best for pixel art.
    case nearest = 0
    /// Bilinear interpolation. Fast with acceptable quality.
    case linear
    /// Bicubic interpolation. Good balance of quality and speed.
    case cubic
    /// Lanczos interpolation with a=2. High quality.
    case lanczos2
    /// Lanczos interpolation with a=3. Best quality (default).
    case lanczos3
}
