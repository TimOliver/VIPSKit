//
//  VIPSImage+Caching.m
//  VIPSKit
//
//  Caching methods with explicit format control
//

#import "VIPSImage+Private.h"

@implementation VIPSImage (Caching)

- (NSData *)cacheDataWithError:(NSError **)error {
    // Default to lossless WebP
    return [self cacheDataWithFormat:VIPSImageFormatWebP quality:0 lossless:YES error:error];
}

- (NSData *)cacheDataWithFormat:(VIPSImageFormat)format
                        quality:(NSInteger)quality
                       lossless:(BOOL)lossless
                          error:(NSError **)error {
    void *buffer = NULL;
    size_t length = 0;
    int result = -1;

    switch (format) {
        case VIPSImageFormatJPEG:
            // JPEG doesn't support lossless
            result = vips_jpegsave_buffer(self.image, &buffer, &length, "Q", (int)quality, NULL);
            break;
        case VIPSImageFormatPNG:
            // PNG is always lossless
            result = vips_pngsave_buffer(self.image, &buffer, &length, NULL);
            break;
        case VIPSImageFormatWebP:
            if (lossless) {
                result = vips_webpsave_buffer(self.image, &buffer, &length, "lossless", TRUE, NULL);
            } else {
                result = vips_webpsave_buffer(self.image, &buffer, &length, "Q", (int)quality, NULL);
            }
            break;
        case VIPSImageFormatHEIF:
            result = vips_heifsave_buffer(self.image, &buffer, &length, "Q", (int)quality, NULL);
            break;
        case VIPSImageFormatAVIF:
            result = vips_heifsave_buffer(self.image, &buffer, &length,
                                          "Q", (int)quality,
                                          "compression", VIPS_FOREIGN_HEIF_COMPRESSION_AV1,
                                          NULL);
            break;
        case VIPSImageFormatJXL:
            if (lossless) {
                result = vips_jxlsave_buffer(self.image, &buffer, &length, "lossless", TRUE, NULL);
            } else {
                result = vips_jxlsave_buffer(self.image, &buffer, &length, "Q", (int)quality, NULL);
            }
            break;
        case VIPSImageFormatGIF:
            result = vips_gifsave_buffer(self.image, &buffer, &length, NULL);
            break;
        case VIPSImageFormatUnknown:
            if (error) {
                *error = [NSError errorWithDomain:VIPSErrorDomain
                                             code:-1
                                         userInfo:@{NSLocalizedDescriptionKey: @"Unknown format for cache export"}];
            }
            return nil;
    }

    if (result != 0 || !buffer) {
        if (error) {
            *error = [self.class errorFromVips];
        }
        return nil;
    }

    NSData *data = [NSData dataWithBytesNoCopy:buffer length:length freeWhenDone:YES];
    return data;
}

- (BOOL)writeToCacheFile:(NSString *)path error:(NSError **)error {
    // Default to lossless WebP
    return [self writeToCacheFile:path format:VIPSImageFormatWebP quality:0 lossless:YES error:error];
}

- (BOOL)writeToCacheFile:(NSString *)path
                  format:(VIPSImageFormat)format
                 quality:(NSInteger)quality
                lossless:(BOOL)lossless
                   error:(NSError **)error {

    // Ensure correct extension for the format
    NSString *finalPath = path;
    NSString *expectedExt = [self extensionForFormat:format];
    if (expectedExt && ![[path.pathExtension lowercaseString] isEqualToString:expectedExt]) {
        finalPath = [path stringByAppendingPathExtension:expectedExt];
    }

    int result = -1;

    switch (format) {
        case VIPSImageFormatJPEG:
            result = vips_jpegsave(self.image, finalPath.UTF8String, "Q", (int)quality, NULL);
            break;
        case VIPSImageFormatPNG:
            result = vips_pngsave(self.image, finalPath.UTF8String, NULL);
            break;
        case VIPSImageFormatWebP:
            if (lossless) {
                result = vips_webpsave(self.image, finalPath.UTF8String, "lossless", TRUE, NULL);
            } else {
                result = vips_webpsave(self.image, finalPath.UTF8String, "Q", (int)quality, NULL);
            }
            break;
        case VIPSImageFormatHEIF:
            result = vips_heifsave(self.image, finalPath.UTF8String, "Q", (int)quality, NULL);
            break;
        case VIPSImageFormatAVIF:
            result = vips_heifsave(self.image, finalPath.UTF8String,
                                   "Q", (int)quality,
                                   "compression", VIPS_FOREIGN_HEIF_COMPRESSION_AV1,
                                   NULL);
            break;
        case VIPSImageFormatJXL:
            if (lossless) {
                result = vips_jxlsave(self.image, finalPath.UTF8String, "lossless", TRUE, NULL);
            } else {
                result = vips_jxlsave(self.image, finalPath.UTF8String, "Q", (int)quality, NULL);
            }
            break;
        case VIPSImageFormatGIF:
            result = vips_gifsave(self.image, finalPath.UTF8String, NULL);
            break;
        case VIPSImageFormatUnknown:
            if (error) {
                *error = [NSError errorWithDomain:VIPSErrorDomain
                                             code:-1
                                         userInfo:@{NSLocalizedDescriptionKey: @"Unknown format for cache export"}];
            }
            return NO;
    }

    if (result != 0) {
        if (error) {
            *error = [self.class errorFromVips];
        }
        return NO;
    }

    return YES;
}

#pragma mark - Private

- (NSString *)extensionForFormat:(VIPSImageFormat)format {
    switch (format) {
        case VIPSImageFormatJPEG: return @"jpg";
        case VIPSImageFormatPNG: return @"png";
        case VIPSImageFormatWebP: return @"webp";
        case VIPSImageFormatHEIF: return @"heic";
        case VIPSImageFormatAVIF: return @"avif";
        case VIPSImageFormatJXL: return @"jxl";
        case VIPSImageFormatGIF: return @"gif";
        case VIPSImageFormatUnknown: return nil;
    }
    return nil;
}

@end
