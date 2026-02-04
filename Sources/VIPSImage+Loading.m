//
//  VIPSImage+Loading.m
//  VIPSKit
//
//  Image loading and creation methods
//

#import "VIPSImage+Loading.h"
#import "VIPSImage+Private.h"

@implementation VIPSImage (Loading)

#pragma mark - Image Info

+ (BOOL)getImageInfoAtPath:(NSString *)path
                     width:(NSInteger *)width
                    height:(NSInteger *)height
                    format:(VIPSImageFormat *)format
                     error:(NSError **)error {
    // Use sequential access mode - this reads only the header, not pixel data
    VipsImage *image = vips_image_new_from_file(path.UTF8String,
                                                  "access", VIPS_ACCESS_SEQUENTIAL,
                                                  NULL);
    if (!image) {
        if (error) {
            *error = [self errorFromVips];
        }
        return NO;
    }

    // Extract dimensions
    if (width) {
        *width = vips_image_get_width(image);
    }
    if (height) {
        *height = vips_image_get_height(image);
    }

    // Extract format from loader name
    if (format) {
        const char *loader = NULL;
        *format = VIPSImageFormatUnknown;

        if (vips_image_get_string(image, VIPS_META_LOADER, &loader) == 0 && loader) {
            NSString *loaderName = [NSString stringWithUTF8String:loader];

            if ([loaderName hasPrefix:@"jpeg"] || [loaderName hasPrefix:@"jpg"]) {
                *format = VIPSImageFormatJPEG;
            } else if ([loaderName hasPrefix:@"png"]) {
                *format = VIPSImageFormatPNG;
            } else if ([loaderName hasPrefix:@"webp"]) {
                *format = VIPSImageFormatWebP;
            } else if ([loaderName hasPrefix:@"heif"]) {
                // Check for AVIF
                const char *compression = NULL;
                if (vips_image_get_string(image, "heif-compression", &compression) == 0 &&
                    compression && strcmp(compression, "av1") == 0) {
                    *format = VIPSImageFormatAVIF;
                } else {
                    *format = VIPSImageFormatHEIF;
                }
            } else if ([loaderName hasPrefix:@"jxl"]) {
                *format = VIPSImageFormatJXL;
            } else if ([loaderName hasPrefix:@"gif"]) {
                *format = VIPSImageFormatGIF;
            }
        }
    }

    // Release immediately - we only needed the header
    g_object_unref(image);

    return YES;
}

#pragma mark - File Loading

+ (instancetype)imageWithContentsOfFile:(NSString *)path error:(NSError **)error {
    VIPSImage *wrapper = [[VIPSImage alloc] init];
    wrapper.image = vips_image_new_from_file(path.UTF8String, NULL);

    if (!wrapper.image) {
        if (error) {
            *error = [self errorFromVips];
        }
        return nil;
    }

    return wrapper;
}

+ (instancetype)thumbnailFromFile:(NSString *)path
                            width:(NSInteger)width
                           height:(NSInteger)height
                            error:(NSError **)error {
    VipsImage *out = NULL;

    // vips_thumbnail uses shrink-on-load internally - decodes at reduced resolution
    // This is much more memory efficient than loading full then resizing
    if (vips_thumbnail(path.UTF8String, &out, (int)width, "height", (int)height, NULL) != 0) {
        if (error) {
            *error = [self errorFromVips];
        }
        return nil;
    }

    VIPSImage *wrapper = [[VIPSImage alloc] init];
    wrapper.image = out;
    return wrapper;
}

+ (instancetype)thumbnailFromData:(NSData *)data
                            width:(NSInteger)width
                           height:(NSInteger)height
                            error:(NSError **)error {
    VipsImage *out = NULL;

    // vips_thumbnail_buffer uses shrink-on-load internally - decodes at reduced resolution
    // Cast away const - vips doesn't modify the buffer
    if (vips_thumbnail_buffer((void *)data.bytes, data.length, &out, (int)width, "height", (int)height, NULL) != 0) {
        if (error) {
            *error = [self errorFromVips];
        }
        return nil;
    }

    VIPSImage *wrapper = [[VIPSImage alloc] init];
    wrapper.image = out;
    return wrapper;
}

+ (instancetype)imageWithContentsOfFileSequential:(NSString *)path error:(NSError **)error {
    VIPSImage *wrapper = [[VIPSImage alloc] init];

    // Sequential access mode - processes row by row, doesn't need whole image in memory
    wrapper.image = vips_image_new_from_file(path.UTF8String,
                                              "access", VIPS_ACCESS_SEQUENTIAL,
                                              NULL);

    if (!wrapper.image) {
        if (error) {
            *error = [self errorFromVips];
        }
        return nil;
    }

    return wrapper;
}

#pragma mark - Data Loading

+ (instancetype)imageWithData:(NSData *)data error:(NSError **)error {
    VIPSImage *wrapper = [[VIPSImage alloc] init];
    wrapper.image = vips_image_new_from_buffer(data.bytes, data.length, "", NULL);

    if (!wrapper.image) {
        if (error) {
            *error = [self errorFromVips];
        }
        return nil;
    }

    return wrapper;
}

+ (instancetype)imageWithBuffer:(const void *)buffer
                          width:(NSInteger)width
                         height:(NSInteger)height
                          bands:(NSInteger)bands
                          error:(NSError **)error {
    // Create image from memory - assumes 8-bit unsigned data
    VipsImage *image = vips_image_new_from_memory_copy(buffer,
                                                        width * height * bands,
                                                        (int)width,
                                                        (int)height,
                                                        (int)bands,
                                                        VIPS_FORMAT_UCHAR);

    if (!image) {
        if (error) {
            *error = [self.class errorFromVips];
        }
        return nil;
    }

    // Set the color interpretation directly on the struct.
    // Images from memory default to VIPS_INTERPRETATION_MULTIBAND which causes
    // color operations to fail. We set the Type field directly to avoid using
    // vips_copy() which goes through the operation cache (which has issues with
    // statically linked glib).
    image->Type = (bands <= 2) ? VIPS_INTERPRETATION_B_W : VIPS_INTERPRETATION_sRGB;

    VIPSImage *wrapper = [[VIPSImage alloc] init];
    wrapper.image = image;
    return wrapper;
}

@end
