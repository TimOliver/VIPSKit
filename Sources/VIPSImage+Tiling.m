//
//  VIPSImage+Tiling.m
//  VIPSKit
//
//  Tiling and region extraction for large images
//

#import <Foundation/Foundation.h>
#import "VIPSImage+Private.h"

// Helper to create NSValue from CGRect in a cross-platform way
static inline NSValue *VIPSValueWithCGRect(CGRect rect) {
    return [NSValue valueWithBytes:&rect objCType:@encode(CGRect)];
}

@implementation VIPSImage (Tiling)

- (NSArray<NSValue *> *)tileRectsWithTileWidth:(NSInteger)tileWidth
                                    tileHeight:(NSInteger)tileHeight {
    if (tileWidth <= 0 || tileHeight <= 0) {
        return @[];
    }

    NSInteger imageWidth = self.width;
    NSInteger imageHeight = self.height;

    NSInteger cols = (imageWidth + tileWidth - 1) / tileWidth;   // Ceiling division
    NSInteger rows = (imageHeight + tileHeight - 1) / tileHeight;

    NSMutableArray<NSValue *> *rects = [NSMutableArray arrayWithCapacity:rows * cols];

    for (NSInteger row = 0; row < rows; row++) {
        for (NSInteger col = 0; col < cols; col++) {
            NSInteger x = col * tileWidth;
            NSInteger y = row * tileHeight;

            // Handle edge tiles that may be smaller
            NSInteger w = MIN(tileWidth, imageWidth - x);
            NSInteger h = MIN(tileHeight, imageHeight - y);

            CGRect rect = CGRectMake(x, y, w, h);
            [rects addObject:VIPSValueWithCGRect(rect)];
        }
    }

    return [rects copy];
}

- (NSInteger)numberOfStripsWithHeight:(NSInteger)stripHeight {
    if (stripHeight <= 0) {
        return 0;
    }
    return (self.height + stripHeight - 1) / stripHeight;  // Ceiling division
}

- (VIPSImage *)stripAtIndex:(NSInteger)index
                     height:(NSInteger)stripHeight
                      error:(NSError **)error {
    if (stripHeight <= 0) {
        if (error) {
            *error = [NSError errorWithDomain:VIPSErrorDomain
                                         code:-1
                                     userInfo:@{NSLocalizedDescriptionKey: @"Strip height must be positive"}];
        }
        return nil;
    }

    NSInteger numStrips = [self numberOfStripsWithHeight:stripHeight];

    if (index < 0 || index >= numStrips) {
        if (error) {
            *error = [NSError errorWithDomain:VIPSErrorDomain
                                         code:-1
                                     userInfo:@{NSLocalizedDescriptionKey:
                                         [NSString stringWithFormat:@"Strip index %ld out of range [0, %ld)",
                                          (long)index, (long)numStrips]}];
        }
        return nil;
    }

    NSInteger y = index * stripHeight;
    NSInteger actualHeight = MIN(stripHeight, self.height - y);

    // Use crop to extract the strip
    return [self cropWithX:0 y:y width:self.width height:actualHeight error:error];
}

+ (instancetype)extractRegionFromFile:(NSString *)path
                                    x:(NSInteger)x
                                    y:(NSInteger)y
                                width:(NSInteger)width
                               height:(NSInteger)height
                                error:(NSError **)error {
    // Load with sequential access for memory efficiency
    VipsImage *source = vips_image_new_from_file(path.UTF8String,
                                                   "access", VIPS_ACCESS_SEQUENTIAL,
                                                   NULL);
    if (!source) {
        if (error) {
            *error = [self errorFromVips];
        }
        return nil;
    }

    // Validate region bounds
    int sourceWidth = vips_image_get_width(source);
    int sourceHeight = vips_image_get_height(source);

    if (x < 0 || y < 0 || x + width > sourceWidth || y + height > sourceHeight) {
        g_object_unref(source);
        if (error) {
            *error = [NSError errorWithDomain:VIPSErrorDomain
                                         code:-1
                                     userInfo:@{NSLocalizedDescriptionKey:
                                         [NSString stringWithFormat:@"Region (%ld,%ld,%ld,%ld) exceeds image bounds (%d,%d)",
                                          (long)x, (long)y, (long)width, (long)height, sourceWidth, sourceHeight]}];
        }
        return nil;
    }

    // Extract the region
    VipsImage *region = NULL;
    if (vips_extract_area(source, &region, (int)x, (int)y, (int)width, (int)height, NULL) != 0) {
        g_object_unref(source);
        if (error) {
            *error = [self errorFromVips];
        }
        return nil;
    }

    // Copy to memory to break the reference to source and allow sequential access to work
    VipsImage *copied = vips_image_copy_memory(region);
    g_object_unref(region);
    g_object_unref(source);

    if (!copied) {
        if (error) {
            *error = [self errorFromVips];
        }
        return nil;
    }

    VIPSImage *wrapper = [[VIPSImage alloc] init];
    wrapper.image = copied;
    return wrapper;
}

+ (instancetype)extractRegionFromData:(NSData *)data
                                    x:(NSInteger)x
                                    y:(NSInteger)y
                                width:(NSInteger)width
                               height:(NSInteger)height
                                error:(NSError **)error {
    // Load from buffer with sequential access for memory efficiency
    VipsImage *source = vips_image_new_from_buffer(data.bytes, data.length, "",
                                                    "access", VIPS_ACCESS_SEQUENTIAL,
                                                    NULL);
    if (!source) {
        if (error) {
            *error = [self errorFromVips];
        }
        return nil;
    }

    // Validate region bounds
    int sourceWidth = vips_image_get_width(source);
    int sourceHeight = vips_image_get_height(source);

    if (x < 0 || y < 0 || x + width > sourceWidth || y + height > sourceHeight) {
        g_object_unref(source);
        if (error) {
            *error = [NSError errorWithDomain:VIPSErrorDomain
                                         code:-1
                                     userInfo:@{NSLocalizedDescriptionKey:
                                         [NSString stringWithFormat:@"Region (%ld,%ld,%ld,%ld) exceeds image bounds (%d,%d)",
                                          (long)x, (long)y, (long)width, (long)height, sourceWidth, sourceHeight]}];
        }
        return nil;
    }

    // Extract the region
    VipsImage *region = NULL;
    if (vips_extract_area(source, &region, (int)x, (int)y, (int)width, (int)height, NULL) != 0) {
        g_object_unref(source);
        if (error) {
            *error = [self errorFromVips];
        }
        return nil;
    }

    // Copy to memory to break the reference to source
    VipsImage *copied = vips_image_copy_memory(region);
    g_object_unref(region);
    g_object_unref(source);

    if (!copied) {
        if (error) {
            *error = [self errorFromVips];
        }
        return nil;
    }

    VIPSImage *wrapper = [[VIPSImage alloc] init];
    wrapper.image = copied;
    return wrapper;
}

@end
