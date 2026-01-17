//
//  VIPSImage+CGImage.m
//  VIPSKit
//
//  CoreGraphics integration methods
//

#import "VIPSImage+Private.h"

// Callback to free vips memory when CGDataProvider is released
static void VIPSDataProviderReleaseCallback(void *info, const void *data, size_t size) {
    g_free((void *)data);
}

@implementation VIPSImage (CGImage)

#pragma mark - Class Methods

+ (CGImageRef)createThumbnailFromFile:(NSString *)path
                                width:(NSInteger)width
                               height:(NSInteger)height
                                error:(NSError **)error {
    VipsImage *thumb = NULL;

    // Use vips_thumbnail which handles shrink-on-load where possible
    if (vips_thumbnail(path.UTF8String, &thumb, (int)width, "height", (int)height, NULL) != 0) {
        if (error) {
            *error = [self errorFromVips];
        }
        return NULL;
    }

    // Convert to 8-bit sRGB if needed
    VipsImage *prepared = NULL;
    if (vips_image_get_interpretation(thumb) != VIPS_INTERPRETATION_sRGB) {
        if (vips_colourspace(thumb, &prepared, VIPS_INTERPRETATION_sRGB, NULL) != 0) {
            g_object_unref(thumb);
            if (error) {
                *error = [self errorFromVips];
            }
            return NULL;
        }
        g_object_unref(thumb);
    } else {
        prepared = thumb;
    }

    // Cast to 8-bit if needed
    VipsImage *cast = NULL;
    if (vips_image_get_format(prepared) != VIPS_FORMAT_UCHAR) {
        if (vips_cast_uchar(prepared, &cast, NULL) != 0) {
            g_object_unref(prepared);
            if (error) {
                *error = [self errorFromVips];
            }
            return NULL;
        }
        g_object_unref(prepared);
        prepared = cast;
    }

    // Get final dimensions and bands
    int finalWidth = vips_image_get_width(prepared);
    int finalHeight = vips_image_get_height(prepared);
    int bands = vips_image_get_bands(prepared);

    // Write to memory (this forces evaluation and we get just the thumbnail pixels)
    size_t dataSize = 0;
    void *data = vips_image_write_to_memory(prepared, &dataSize);
    g_object_unref(prepared);  // Release vips image immediately

    if (!data) {
        if (error) {
            *error = [self errorFromVips];
        }
        return NULL;
    }

    // Create CGImage from the pixel data
    CGDataProviderRef provider = CGDataProviderCreateWithData(
        NULL, data, dataSize,
        (CGDataProviderReleaseDataCallback)g_free  // Free vips memory when CGImage is released
    );

    if (!provider) {
        g_free(data);
        if (error) {
            *error = [NSError errorWithDomain:VIPSErrorDomain
                                         code:-1
                                     userInfo:@{NSLocalizedDescriptionKey: @"Failed to create CGDataProvider"}];
        }
        return NULL;
    }

    CGColorSpaceRef colorSpace;
    CGBitmapInfo bitmapInfo;
    size_t bitsPerPixel;

    if (bands == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
        bitmapInfo = (CGBitmapInfo)kCGImageAlphaNone;
        bitsPerPixel = 8;
    } else if (bands == 3) {
        colorSpace = CGColorSpaceCreateDeviceRGB();
        bitmapInfo = (CGBitmapInfo)kCGImageAlphaNone | kCGBitmapByteOrderDefault;
        bitsPerPixel = 24;
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
        bitmapInfo = (CGBitmapInfo)kCGImageAlphaLast | kCGBitmapByteOrderDefault;
        bitsPerPixel = 32;
    }

    CGImageRef cgImage = CGImageCreate(
        finalWidth, finalHeight,
        8, bitsPerPixel,
        finalWidth * (bitsPerPixel / 8),
        colorSpace,
        bitmapInfo,
        provider,
        NULL, false,
        kCGRenderingIntentDefault
    );

    CGColorSpaceRelease(colorSpace);
    CGDataProviderRelease(provider);

    if (!cgImage && error) {
        *error = [NSError errorWithDomain:VIPSErrorDomain
                                     code:-1
                                 userInfo:@{NSLocalizedDescriptionKey: @"Failed to create CGImage"}];
    }

    return cgImage;
}

#pragma mark - Instance Methods

- (CGImageRef)createCGImageWithError:(NSError **)error {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef result = [self createCGImageWithColorSpace:colorSpace error:error];
    CGColorSpaceRelease(colorSpace);
    return result;
}

- (CGImageRef)createCGImageWithColorSpace:(CGColorSpaceRef)colorSpace error:(NSError **)error {
    VipsImage *prepared = NULL;
    size_t dataSize = 0;
    void *data = NULL;

    // Get current image properties
    int bands = vips_image_get_bands(self.image);
    VipsInterpretation interpretation = vips_image_get_interpretation(self.image);

    // Convert to sRGB if needed (unless already RGB/sRGB or grayscale)
    VipsImage *srgbImage = NULL;
    if (interpretation != VIPS_INTERPRETATION_sRGB &&
        interpretation != VIPS_INTERPRETATION_RGB &&
        interpretation != VIPS_INTERPRETATION_B_W) {
        if (vips_colourspace(self.image, &srgbImage, VIPS_INTERPRETATION_sRGB, NULL) != 0) {
            if (error) {
                *error = [self.class errorFromVips];
            }
            return NULL;
        }
    } else {
        srgbImage = self.image;
        g_object_ref(srgbImage);
    }

    // Determine target format based on bands
    bands = vips_image_get_bands(srgbImage);

    // CoreGraphics needs either 1, 3, or 4 bands
    // Convert grayscale+alpha to RGBA, or ensure we have RGB/RGBA
    if (bands == 1) {
        // Grayscale without alpha - OK
        prepared = srgbImage;
        g_object_ref(prepared);
    } else if (bands == 2) {
        // Grayscale with alpha - convert to RGBA
        VipsImage *rgba = NULL;
        if (vips_colourspace(srgbImage, &rgba, VIPS_INTERPRETATION_sRGB, NULL) != 0) {
            g_object_unref(srgbImage);
            if (error) {
                *error = [self.class errorFromVips];
            }
            return NULL;
        }
        prepared = rgba;
    } else if (bands == 3) {
        // RGB without alpha - OK
        prepared = srgbImage;
        g_object_ref(prepared);
    } else if (bands >= 4) {
        // RGBA or more - use first 4 bands
        if (bands > 4) {
            if (vips_extract_band(srgbImage, &prepared, 0, "n", 4, NULL) != 0) {
                g_object_unref(srgbImage);
                if (error) {
                    *error = [self.class errorFromVips];
                }
                return NULL;
            }
        } else {
            prepared = srgbImage;
            g_object_ref(prepared);
        }
    } else {
        g_object_unref(srgbImage);
        if (error) {
            *error = [NSError errorWithDomain:VIPSErrorDomain
                                         code:-1
                                     userInfo:@{NSLocalizedDescriptionKey: @"Unsupported number of image bands"}];
        }
        return NULL;
    }

    g_object_unref(srgbImage);

    // Ensure 8-bit format
    VipsImage *cast = NULL;
    if (vips_image_get_format(prepared) != VIPS_FORMAT_UCHAR) {
        if (vips_cast_uchar(prepared, &cast, NULL) != 0) {
            g_object_unref(prepared);
            if (error) {
                *error = [self.class errorFromVips];
            }
            return NULL;
        }
        g_object_unref(prepared);
        prepared = cast;
    }

    // Get dimensions
    int width = vips_image_get_width(prepared);
    int height = vips_image_get_height(prepared);
    bands = vips_image_get_bands(prepared);

    // Write to memory
    data = vips_image_write_to_memory(prepared, &dataSize);
    g_object_unref(prepared);

    if (!data) {
        if (error) {
            *error = [self.class errorFromVips];
        }
        return NULL;
    }

    // Create data provider (takes ownership of data via callback)
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, data, dataSize, VIPSDataProviderReleaseCallback);

    if (!provider) {
        g_free(data);
        if (error) {
            *error = [NSError errorWithDomain:VIPSErrorDomain
                                         code:-1
                                     userInfo:@{NSLocalizedDescriptionKey: @"Failed to create CGDataProvider"}];
        }
        return NULL;
    }

    // Determine bitmap info based on alpha
    CGBitmapInfo bitmapInfo;
    size_t bitsPerComponent = 8;
    size_t bitsPerPixel;

    if (bands == 1) {
        // Grayscale
        bitsPerPixel = 8;
        bitmapInfo = (CGBitmapInfo)kCGImageAlphaNone;
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else if (bands == 3) {
        // RGB without alpha
        bitsPerPixel = 24;
        bitmapInfo = (CGBitmapInfo)kCGImageAlphaNone | kCGBitmapByteOrderDefault;
    } else {
        // RGBA with alpha (bands == 4)
        bitsPerPixel = 32;
        bitmapInfo = (CGBitmapInfo)kCGImageAlphaLast | kCGBitmapByteOrderDefault;
    }

    size_t bytesPerRow = width * (bitsPerPixel / 8);

    // Create the CGImage
    CGImageRef cgImage = CGImageCreate(
        width,
        height,
        bitsPerComponent,
        bitsPerPixel,
        bytesPerRow,
        colorSpace,
        bitmapInfo,
        provider,
        NULL,
        false,
        kCGRenderingIntentDefault
    );

    // Clean up (colorSpace for grayscale case)
    if (bands == 1) {
        CGColorSpaceRelease(colorSpace);
    }
    CGDataProviderRelease(provider);

    if (!cgImage && error) {
        *error = [NSError errorWithDomain:VIPSErrorDomain
                                     code:-1
                                 userInfo:@{NSLocalizedDescriptionKey: @"Failed to create CGImage"}];
    }

    return cgImage;
}

@end
