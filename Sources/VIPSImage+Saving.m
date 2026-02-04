//
//  VIPSImage+Saving.m
//  VIPSKit
//
//  Image saving and export methods
//

#import "VIPSImage+Saving.h"
#import "VIPSImage+Private.h"

@implementation VIPSImage (Saving)

#pragma mark - File Saving

- (BOOL)writeToFile:(NSString *)path error:(NSError **)error {
    if (vips_image_write_to_file(self.image, path.UTF8String, NULL) != 0) {
        if (error) {
            *error = [self.class errorFromVips];
        }
        return NO;
    }
    return YES;
}

- (BOOL)writeToFile:(NSString *)path
             format:(VIPSImageFormat)format
            quality:(NSInteger)quality
              error:(NSError **)error {

    int result = -1;

    switch (format) {
        case VIPSImageFormatJPEG:
            result = vips_jpegsave(self.image, path.UTF8String, "Q", (int)quality, NULL);
            break;
        case VIPSImageFormatPNG:
            result = vips_pngsave(self.image, path.UTF8String, NULL);
            break;
        case VIPSImageFormatWebP:
            result = vips_webpsave(self.image, path.UTF8String, "Q", (int)quality, NULL);
            break;
        case VIPSImageFormatHEIF:
            result = vips_heifsave(self.image, path.UTF8String, "Q", (int)quality, NULL);
            break;
        case VIPSImageFormatAVIF:
            result = vips_heifsave(self.image, path.UTF8String,
                                   "Q", (int)quality,
                                   "compression", VIPS_FOREIGN_HEIF_COMPRESSION_AV1,
                                   NULL);
            break;
        case VIPSImageFormatJXL:
            result = vips_jxlsave(self.image, path.UTF8String, "Q", (int)quality, NULL);
            break;
        case VIPSImageFormatGIF:
            result = vips_gifsave(self.image, path.UTF8String, NULL);
            break;
        case VIPSImageFormatUnknown:
            break;
    }

    if (result != 0) {
        if (error) {
            *error = [self.class errorFromVips];
        }
        return NO;
    }

    return YES;
}

#pragma mark - Data Export

- (NSData *)dataWithFormat:(VIPSImageFormat)format
                   quality:(NSInteger)quality
                     error:(NSError **)error {
    void *buffer = NULL;
    size_t length = 0;
    int result = -1;

    switch (format) {
        case VIPSImageFormatJPEG:
            result = vips_jpegsave_buffer(self.image, &buffer, &length, "Q", (int)quality, NULL);
            break;
        case VIPSImageFormatPNG:
            result = vips_pngsave_buffer(self.image, &buffer, &length, NULL);
            break;
        case VIPSImageFormatWebP:
            result = vips_webpsave_buffer(self.image, &buffer, &length, "Q", (int)quality, NULL);
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
            result = vips_jxlsave_buffer(self.image, &buffer, &length, "Q", (int)quality, NULL);
            break;
        case VIPSImageFormatGIF:
            result = vips_gifsave_buffer(self.image, &buffer, &length, NULL);
            break;
        case VIPSImageFormatUnknown:
            break;
    }

    if (result != 0 || !buffer) {
        if (error) {
            *error = [self.class errorFromVips];
        }
        return nil;
    }

    NSData *data = [NSData dataWithBytes:buffer length:length];
    g_free(buffer);
    return data;
}

@end
