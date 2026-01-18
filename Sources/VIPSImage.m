//
//  VIPSImage.m
//  VIPSKit
//
//  Core implementation: initialization, properties, memory management
//

#import "VIPSImage+Private.h"
#import <objc/runtime.h>
#import <objc/message.h>

NSString *const VIPSErrorDomain = @"org.libvips.VIPSKit";

@implementation VIPSImage

#pragma mark - Error Handling

+ (NSError *)errorFromVips {
    const char *msg = vips_error_buffer();
    NSString *message = msg ? [NSString stringWithUTF8String:msg] : @"Unknown VIPS error";
    vips_error_clear();
    return [NSError errorWithDomain:VIPSErrorDomain
                               code:-1
                           userInfo:@{NSLocalizedDescriptionKey: message}];
}

#pragma mark - Lifecycle

+ (BOOL)initializeWithError:(NSError **)error {
    if (VIPS_INIT("VIPSKit") != 0) {
        if (error) {
            *error = [self errorFromVips];
        }
        return NO;
    }

    // Configure cache for typical usage.
    vips_cache_set_max(100);
    vips_cache_set_max_mem(50 * 1024 * 1024);  // 50MB
    vips_cache_set_max_files(10);

    // Default to single-threaded for batch processing
    // (parallelize across images, not within single image)
    vips_concurrency_set(1);

    return YES;
}

+ (void)shutdown {
    vips_shutdown();
}

- (instancetype)initWithVipsImage:(VipsImage *)image {
    self = [super init];
    if (self) {
        _image = image;
        g_object_ref(image);
    }
    return self;
}

- (void)dealloc {
    if (_image) {
        g_object_unref(_image);
    }
}

#pragma mark - Properties

- (NSInteger)width {
    return vips_image_get_width(self.image);
}

- (NSInteger)height {
    return vips_image_get_height(self.image);
}

- (NSInteger)bands {
    return vips_image_get_bands(self.image);
}

- (BOOL)hasAlpha {
    return vips_image_hasalpha(self.image);
}

- (NSString *)loaderName {
    const char *loader = NULL;
    if (vips_image_get_string(self.image, VIPS_META_LOADER, &loader) == 0 && loader) {
        return [NSString stringWithUTF8String:loader];
    }
    return nil;
}

- (VIPSImageFormat)sourceFormat {
    NSString *loader = self.loaderName;
    if (!loader) {
        return VIPSImageFormatUnknown;
    }

    if ([loader hasPrefix:@"jpeg"] || [loader hasPrefix:@"jpg"]) {
        return VIPSImageFormatJPEG;
    } else if ([loader hasPrefix:@"png"]) {
        return VIPSImageFormatPNG;
    } else if ([loader hasPrefix:@"webp"]) {
        return VIPSImageFormatWebP;
    } else if ([loader hasPrefix:@"heif"]) {
        // Check for AVIF specifically - heifload handles both
        const char *compression = NULL;
        if (vips_image_get_string(self.image, "heif-compression", &compression) == 0 && compression) {
            if (strcmp(compression, "av1") == 0) {
                return VIPSImageFormatAVIF;
            }
        }
        return VIPSImageFormatHEIF;
    } else if ([loader hasPrefix:@"jxl"]) {
        return VIPSImageFormatJXL;
    } else if ([loader hasPrefix:@"gif"]) {
        return VIPSImageFormatGIF;
    }

    return VIPSImageFormatUnknown;
}

#pragma mark - Class Memory Management

+ (void)setCacheMaxOperations:(NSInteger)max {
    vips_cache_set_max((int)max);
}

+ (void)setCacheMaxMemory:(NSInteger)bytes {
    vips_cache_set_max_mem((size_t)bytes);
}

+ (void)setCacheMaxFiles:(NSInteger)max {
    vips_cache_set_max_files((int)max);
}

+ (void)clearCache {
    // Don't use vips_cache_drop_all() - it destroys the hash table entirely
    // and sets vips_cache_table to NULL, causing crashes on subsequent operations.
    //
    // Instead, use the safe approach: temporarily set max to 0 to evict all
    // cached operations via the normal LRU mechanism, then restore the limit.
    int originalMax = vips_cache_get_max();
    vips_cache_set_max(0);  // Triggers vips_cache_trim() which evicts everything
    vips_cache_set_max(originalMax);  // Restore
}

+ (NSInteger)memoryUsage {
    return (NSInteger)vips_tracked_get_mem();
}

+ (NSInteger)memoryHighWater {
    return (NSInteger)vips_tracked_get_mem_highwater();
}

+ (void)resetMemoryHighWater {
    vips_tracked_get_mem_highwater();
}

+ (void)setConcurrency:(NSInteger)threads {
    vips_concurrency_set((int)threads);
}

+ (NSInteger)concurrency {
    return (NSInteger)vips_concurrency_get();
}

#pragma mark - Instance Memory Management

- (VIPSImage *)copyToMemoryWithError:(NSError **)error {
    VipsImage *out = vips_image_copy_memory(self.image);

    if (!out) {
        if (error) {
            *error = [self.class errorFromVips];
        }
        return nil;
    }

    VIPSImage *result = [[VIPSImage alloc] init];
    result.image = out;
    return result;
}

#pragma mark - Pixel Access

- (BOOL)withPixelData:(void (NS_NOESCAPE ^)(const uint8_t *data,
                                            NSInteger width,
                                            NSInteger height,
                                            NSInteger bytesPerRow,
                                            NSInteger bands))block
                error:(NSError **)error {
    if (!block) {
        return YES;
    }

    VipsImage *prepared = NULL;

    // Convert to sRGB if needed
    VipsInterpretation interpretation = vips_image_get_interpretation(self.image);
    if (interpretation != VIPS_INTERPRETATION_sRGB &&
        interpretation != VIPS_INTERPRETATION_RGB &&
        interpretation != VIPS_INTERPRETATION_B_W) {
        if (vips_colourspace(self.image, &prepared, VIPS_INTERPRETATION_sRGB, NULL) != 0) {
            if (error) {
                *error = [self.class errorFromVips];
            }
            return NO;
        }
    } else {
        prepared = self.image;
        g_object_ref(prepared);
    }

    // Ensure 8-bit format
    if (vips_image_get_format(prepared) != VIPS_FORMAT_UCHAR) {
        VipsImage *cast = NULL;
        if (vips_cast_uchar(prepared, &cast, NULL) != 0) {
            g_object_unref(prepared);
            if (error) {
                *error = [self.class errorFromVips];
            }
            return NO;
        }
        g_object_unref(prepared);
        prepared = cast;
    }

    // Get dimensions
    int width = vips_image_get_width(prepared);
    int height = vips_image_get_height(prepared);
    int bands = vips_image_get_bands(prepared);
    size_t bytesPerRow = (size_t)width * (size_t)bands;

    // Write to contiguous memory buffer (single copy from vips pipeline)
    size_t dataSize = 0;
    void *data = vips_image_write_to_memory(prepared, &dataSize);
    g_object_unref(prepared);

    if (!data) {
        if (error) {
            *error = [self.class errorFromVips];
        }
        return NO;
    }

    // Call block with pixel data
    block((const uint8_t *)data, width, height, (NSInteger)bytesPerRow, bands);

    // Free the pixel data
    g_free(data);

    return YES;
}

#pragma mark - Analysis

- (CGRect)findTrimWithError:(NSError **)error {
    return [self findTrimWithThreshold:10.0 background:nil error:error];
}

- (CGRect)findTrimWithThreshold:(double)threshold error:(NSError **)error {
    return [self findTrimWithThreshold:threshold background:nil error:error];
}

- (CGRect)findTrimWithThreshold:(double)threshold
                     background:(NSArray<NSNumber *> *)background
                          error:(NSError **)error {
    int left = 0, top = 0, width = 0, height = 0;
    int result;

    if (background && background.count > 0) {
        // Build VipsArrayDouble from the background array
        double *bgValues = g_malloc(sizeof(double) * background.count);
        for (NSUInteger i = 0; i < background.count; i++) {
            bgValues[i] = background[i].doubleValue;
        }
        VipsArrayDouble *bgArray = vips_array_double_new(bgValues, (int)background.count);
        g_free(bgValues);

        result = vips_find_trim(self.image, &left, &top, &width, &height,
                                "threshold", threshold,
                                "background", bgArray,
                                NULL);
        vips_area_unref(VIPS_AREA(bgArray));
    } else {
        // Auto-detect background
        result = vips_find_trim(self.image, &left, &top, &width, &height,
                                "threshold", threshold,
                                NULL);
    }

    if (result != 0) {
        if (error) {
            *error = [self.class errorFromVips];
        }
        return CGRectNull;
    }

    return CGRectMake(left, top, width, height);
}

#pragma mark - Debug Support

- (id)debugQuickLookObject {
    // Xcode calls this method to show image previews in the debugger
    CGImageRef cgImage = [self createCGImageWithError:nil];
    if (!cgImage) {
        return [NSString stringWithFormat:@"VIPSImage %ldx%ld (%ld bands)",
                (long)self.width, (long)self.height, (long)self.bands];
    }

    // Use runtime lookup for UIImage to avoid compile-time UIKit dependency
    // UIKit is linked at runtime but headers may not be available during build
    Class UIImageClass = NSClassFromString(@"UIImage");
    if (UIImageClass) {
        // Use objc_msgSend to call +[UIImage imageWithCGImage:]
        SEL selector = NSSelectorFromString(@"imageWithCGImage:");
        if ([UIImageClass respondsToSelector:selector]) {
            // Cast objc_msgSend to the correct function signature
            id (*msgSend)(Class, SEL, CGImageRef) = (id (*)(Class, SEL, CGImageRef))objc_msgSend;
            id image = msgSend(UIImageClass, selector, cgImage);
            CGImageRelease(cgImage);
            return image;
        }
    }

    CGImageRelease(cgImage);
    return [NSString stringWithFormat:@"VIPSImage %ldx%ld (%ld bands)",
            (long)self.width, (long)self.height, (long)self.bands];
}

@end
