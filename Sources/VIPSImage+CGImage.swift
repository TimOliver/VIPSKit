import Foundation
import CoreGraphics
internal import vips
internal import CVIPS

extension VIPSImage {

    // MARK: - Class Methods

    /// Decode an image file directly to a thumbnail-sized `CGImage` in one step.
    /// This is the most memory-efficient path for generating display-ready thumbnails,
    /// as the source image is decoded at a reduced resolution and the decode buffers
    /// are released immediately after the `CGImage` is created.
    /// - Parameters:
    ///   - path: The file path of the source image
    ///   - width: The maximum width of the thumbnail
    ///   - height: The maximum height of the thumbnail
    /// - Returns: A `CGImage` thumbnail that fits within the specified dimensions
    public static func thumbnailCGImage(fromFile path: String, width: Int, height: Int) throws -> CGImage {
        var thumb: UnsafeMutablePointer<VipsImage>?
        guard cvips_thumbnail(path, &thumb, Int32(width), Int32(height)) == 0, let thumb else {
            throw VIPSError.fromVips()
        }

        var prepared = thumb

        if vips_image_get_interpretation(prepared) != VIPS_INTERPRETATION_sRGB {
            var srgb: UnsafeMutablePointer<VipsImage>?
            guard cvips_colourspace(prepared, &srgb, VIPS_INTERPRETATION_sRGB) == 0, let srgb else {
                g_object_unref(gpointer(prepared))
                throw VIPSError.fromVips()
            }
            g_object_unref(gpointer(prepared))
            prepared = srgb
        }

        if vips_image_get_format(prepared) != VIPS_FORMAT_UCHAR {
            var cast: UnsafeMutablePointer<VipsImage>?
            guard cvips_cast_uchar(prepared, &cast) == 0, let cast else {
                g_object_unref(gpointer(prepared))
                throw VIPSError.fromVips()
            }
            g_object_unref(gpointer(prepared))
            prepared = cast
        }

        let finalWidth = Int(vips_image_get_width(prepared))
        let finalHeight = Int(vips_image_get_height(prepared))
        let bands = Int(vips_image_get_bands(prepared))

        var dataSize: Int = 0
        guard let data = vips_image_write_to_memory(prepared, &dataSize) else {
            g_object_unref(gpointer(prepared))
            throw VIPSError.fromVips()
        }
        g_object_unref(gpointer(prepared))

        return try createCGImageFromPixels(data: data, dataSize: dataSize,
                                           width: finalWidth, height: finalHeight, bands: bands)
    }

    /// Decode an image file directly to a thumbnail-sized `CGImage` in one step.
    /// - Parameters:
    ///   - path: The file path of the source image
    ///   - size: The maximum size of the thumbnail
    /// - Returns: A `CGImage` thumbnail that fits within the specified size
    public static func thumbnailCGImage(fromFile path: String, size: CGSize) throws -> CGImage {
        try thumbnailCGImage(fromFile: path, width: Int(size.width), height: Int(size.height))
    }

    // MARK: - Instance Methods

    /// A `CGImage` created from this image by transferring pixel data directly
    /// to CoreGraphics. This avoids the encode/decode cycle of converting
    /// through an intermediate format like JPEG or PNG.
    public var cgImage: CGImage {
        get throws {
            var prepared = pointer
            let interpretation = vips_image_get_interpretation(pointer)
            var bands = Int(vips_image_get_bands(pointer))

            // Handle color space conversion
            var srgbImage: UnsafeMutablePointer<VipsImage>
            if bands == 1 {
                g_object_ref(gpointer(pointer))
                srgbImage = pointer
            } else if interpretation != VIPS_INTERPRETATION_sRGB &&
                      interpretation != VIPS_INTERPRETATION_RGB &&
                      interpretation != VIPS_INTERPRETATION_B_W {
                var srgb: UnsafeMutablePointer<VipsImage>?
                guard cvips_colourspace(pointer, &srgb, VIPS_INTERPRETATION_sRGB) == 0, let srgb else {
                    throw VIPSError.fromVips()
                }
                srgbImage = srgb
            } else {
                g_object_ref(gpointer(pointer))
                srgbImage = pointer
            }

            bands = Int(vips_image_get_bands(srgbImage))

            // CoreGraphics needs 1, 3, or 4 bands
            if bands == 2 {
                // Grayscale with alpha -> RGBA
                var rgba: UnsafeMutablePointer<VipsImage>?
                guard cvips_colourspace(srgbImage, &rgba, VIPS_INTERPRETATION_sRGB) == 0, let rgba else {
                    g_object_unref(gpointer(srgbImage))
                    throw VIPSError.fromVips()
                }
                g_object_unref(gpointer(srgbImage))
                srgbImage = rgba
            } else if bands > 4 {
                // Extract first 4 bands
                var extracted: UnsafeMutablePointer<VipsImage>?
                guard cvips_extract_band(srgbImage, &extracted, 0, 4) == 0, let extracted else {
                    g_object_unref(gpointer(srgbImage))
                    throw VIPSError.fromVips()
                }
                g_object_unref(gpointer(srgbImage))
                srgbImage = extracted
            }

            prepared = srgbImage

            // Ensure 8-bit
            if vips_image_get_format(prepared) != VIPS_FORMAT_UCHAR {
                var cast: UnsafeMutablePointer<VipsImage>?
                guard cvips_cast_uchar(prepared, &cast) == 0, let cast else {
                    g_object_unref(gpointer(prepared))
                    throw VIPSError.fromVips()
                }
                g_object_unref(gpointer(prepared))
                prepared = cast
            }

            let w = Int(vips_image_get_width(prepared))
            let h = Int(vips_image_get_height(prepared))
            bands = Int(vips_image_get_bands(prepared))

            var dataSize: Int = 0
            guard let data = vips_image_write_to_memory(prepared, &dataSize) else {
                g_object_unref(gpointer(prepared))
                throw VIPSError.fromVips()
            }
            g_object_unref(gpointer(prepared))

            return try Self.createCGImageFromPixels(data: data, dataSize: dataSize,
                                                    width: w, height: h, bands: bands)
        }
    }

    // MARK: - Private

    /// Create a CGImage from raw pixel data. Takes ownership of `data` (freed via CGDataProvider callback).
    private static func createCGImageFromPixels(data: UnsafeMutableRawPointer, dataSize: Int,
                                                 width: Int, height: Int, bands: Int) throws -> CGImage {
        let provider = CGDataProvider(dataInfo: nil, data: data, size: dataSize) { _, data, _ in
            g_free(UnsafeMutableRawPointer(mutating: data))
        }
        guard let provider else {
            g_free(data)
            throw VIPSError("Failed to create CGDataProvider")
        }

        let colorSpace: CGColorSpace
        let bitmapInfo: CGBitmapInfo
        let bitsPerPixel: Int

        if bands == 1 {
            colorSpace = CGColorSpaceCreateDeviceGray()
            bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
            bitsPerPixel = 8
        } else if bands == 3 {
            colorSpace = CGColorSpaceCreateDeviceRGB()
            bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
            bitsPerPixel = 24
        } else {
            colorSpace = CGColorSpaceCreateDeviceRGB()
            bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue)
            bitsPerPixel = 32
        }

        guard let cgImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: bitsPerPixel,
            bytesPerRow: width * (bitsPerPixel / 8),
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        ) else {
            throw VIPSError("Failed to create CGImage")
        }

        return cgImage
    }
}
