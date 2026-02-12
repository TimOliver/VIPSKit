import Foundation
internal import vips

// MARK: - Debug Description

extension VIPSImage: CustomDebugStringConvertible {

    public var debugDescription: String {
        var lines: [String] = []
        let address = Unmanaged.passUnretained(self).toOpaque()
        lines.append("<VIPSImage: \(address)> \(width)x\(height) pixels, \(bands) band\(bands == 1 ? "" : "s")\(hasAlpha ? " (with alpha)" : "")")

        // Source format and loader
        let format = sourceFormat
        if format != .unknown {
            lines.append("  Format: \(format.debugLabel)\(loaderName.map { " (loader: \($0))" } ?? "")")
        } else if let loader = loaderName {
            lines.append("  Loader: \(loader)")
        }

        // Pixel format and interpretation
        let interp = vips_image_get_interpretation(pointer)
        let bandFmt = vips_image_get_format(pointer)
        lines.append("  Interpretation: \(Self.interpretationLabel(interp))")
        lines.append("  Band format: \(Self.bandFormatLabel(bandFmt))")

        // Resolution (only if non-default)
        let xres = xResolution
        let yres = yResolution
        if xres > 0 || yres > 0 {
            let dpiX = xres * 25.4
            let dpiY = yres * 25.4
            if abs(dpiX - dpiY) < 0.01 {
                lines.append("  Resolution: \(String(format: "%.1f", dpiX)) DPI")
            } else {
                lines.append("  Resolution: \(String(format: "%.1f", dpiX)) x \(String(format: "%.1f", dpiY)) DPI")
            }
        }

        // Orientation
        if let orient = orientation, orient != 1 {
            lines.append("  Orientation: \(orient) (\(Self.orientationLabel(orient)))")
        }

        // Multi-page
        let pages = pageCount
        if pages > 1 {
            lines.append("  Pages: \(pages)\(pageHeight.map { ", page height: \($0)px" } ?? "")")
        }

        // Embedded data
        var embeds: [String] = []
        if exifData != nil { embeds.append("EXIF") }
        if xmpData != nil { embeds.append("XMP") }
        if iccProfile != nil { embeds.append("ICC") }
        if !embeds.isEmpty {
            lines.append("  Embedded data: \(embeds.joined(separator: ", "))")
        }

        // Memory
        let estimatedBytes = width * height * bands * Self.bytesPerBand(bandFmt)
        lines.append("  Estimated size: \(Self.formatBytes(estimatedBytes))")

        return lines.joined(separator: "\n")
    }

    // MARK: - Debug Label Helpers

    private static func interpretationLabel(_ interp: VipsInterpretation) -> String {
        switch interp {
        case VIPS_INTERPRETATION_sRGB:       return "sRGB"
        case VIPS_INTERPRETATION_RGB:        return "RGB (linear)"
        case VIPS_INTERPRETATION_RGB16:      return "RGB16"
        case VIPS_INTERPRETATION_B_W:        return "Grayscale"
        case VIPS_INTERPRETATION_GREY16:     return "Grayscale 16-bit"
        case VIPS_INTERPRETATION_CMYK:       return "CMYK"
        case VIPS_INTERPRETATION_LAB:        return "CIE Lab"
        case VIPS_INTERPRETATION_LABS:       return "CIE LabS"
        case VIPS_INTERPRETATION_LCH:        return "CIE LCh"
        case VIPS_INTERPRETATION_XYZ:        return "CIE XYZ"
        case VIPS_INTERPRETATION_scRGB:      return "scRGB (linear)"
        case VIPS_INTERPRETATION_HSV:        return "HSV"
        case VIPS_INTERPRETATION_MULTIBAND:  return "Multiband"
        case VIPS_INTERPRETATION_FOURIER:    return "Fourier"
        case VIPS_INTERPRETATION_MATRIX:     return "Matrix"
        default:                             return "Unknown (\(interp.rawValue))"
        }
    }

    private static func bandFormatLabel(_ fmt: VipsBandFormat) -> String {
        switch fmt {
        case VIPS_FORMAT_UCHAR:    return "8-bit unsigned"
        case VIPS_FORMAT_CHAR:     return "8-bit signed"
        case VIPS_FORMAT_USHORT:   return "16-bit unsigned"
        case VIPS_FORMAT_SHORT:    return "16-bit signed"
        case VIPS_FORMAT_UINT:     return "32-bit unsigned"
        case VIPS_FORMAT_INT:      return "32-bit signed"
        case VIPS_FORMAT_FLOAT:    return "32-bit float"
        case VIPS_FORMAT_DOUBLE:   return "64-bit float"
        case VIPS_FORMAT_COMPLEX:  return "64-bit complex"
        case VIPS_FORMAT_DPCOMPLEX: return "128-bit complex"
        default:                   return "Unknown (\(fmt.rawValue))"
        }
    }

    private static func orientationLabel(_ value: Int) -> String {
        switch value {
        case 1: return "normal"
        case 2: return "flipped horizontal"
        case 3: return "rotated 180°"
        case 4: return "flipped vertical"
        case 5: return "transposed"
        case 6: return "rotated 90° CW"
        case 7: return "transverse"
        case 8: return "rotated 270° CW"
        default: return "unknown"
        }
    }

    private static func bytesPerBand(_ fmt: VipsBandFormat) -> Int {
        switch fmt {
        case VIPS_FORMAT_UCHAR, VIPS_FORMAT_CHAR: return 1
        case VIPS_FORMAT_USHORT, VIPS_FORMAT_SHORT: return 2
        case VIPS_FORMAT_UINT, VIPS_FORMAT_INT, VIPS_FORMAT_FLOAT: return 4
        case VIPS_FORMAT_DOUBLE, VIPS_FORMAT_COMPLEX: return 8
        case VIPS_FORMAT_DPCOMPLEX: return 16
        default: return 1
        }
    }

    private static func formatBytes(_ bytes: Int) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        let kb = Double(bytes) / 1024
        if kb < 1024 { return String(format: "%.1f KB", kb) }
        let mb = kb / 1024
        if mb < 1024 { return String(format: "%.1f MB", mb) }
        let gb = mb / 1024
        return String(format: "%.2f GB", gb)
    }
}
