//
//  VIPSImage.m
//  VIPSKit
//
//  Core implementation: initialization, properties, memory management
//

#import "VIPSImage+Private.h"

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
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Disable glib's slice allocator which can cause issues when statically linked.
        // This must be set BEFORE any glib functions are called.
        setenv("G_SLICE", "always-malloc", 1);

        // Also disable glib's debug flags that might interfere
        setenv("G_DEBUG", "gc-friendly", 1);
    });

    if (VIPS_INIT("VIPSKit") != 0) {
        if (error) {
            *error = [self errorFromVips];
        }
        return NO;
    }

    // CRITICAL: Disable operation cache IMMEDIATELY after init.
    // The cache uses glib hash tables which can crash when statically linked.
    // This must happen before ANY vips operations use the cache.
    vips_cache_set_max(0);
    vips_cache_set_max_mem(0);
    vips_cache_set_max_files(0);

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

+ (void)clearCache {
    // Note: vips_cache_drop_all() can corrupt glib hash table state when
    // statically linked. Since we disable the cache at init (vips_cache_set_max(0)),
    // this is effectively a no-op anyway. We skip the call to avoid crashes.
    // If caching is re-enabled in the future, this will need to be revisited.
}

+ (void)setCacheMaxOperations:(NSInteger)max {
    // WARNING: Enabling cache (max > 0) may cause crashes due to glib hash table
    // issues when statically linked. Use with caution.
    vips_cache_set_max((int)max);
}

+ (void)setCacheMaxMemory:(NSInteger)bytes {
    vips_cache_set_max_mem((size_t)bytes);
}

+ (void)setCacheMaxFiles:(NSInteger)max {
    vips_cache_set_max_files((int)max);
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

@end
