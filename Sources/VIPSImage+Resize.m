//
//  VIPSImage+Resize.m
//  VIPSKit
//
//  Image resizing and thumbnail methods
//

#import "VIPSImage+Resize.h"
#import "VIPSImage+Private.h"

@implementation VIPSImage (Resize)

- (VIPSImage *)resizeToFitWidth:(NSInteger)width
                         height:(NSInteger)height
                          error:(NSError **)error {
    VipsImage *out = NULL;

    // vips_thumbnail_image does high-quality resize maintaining aspect ratio
    if (vips_thumbnail_image(self.image, &out, (int)width, "height", (int)height, NULL) != 0) {
        if (error) {
            *error = [self.class errorFromVips];
        }
        return nil;
    }

    VIPSImage *result = [[VIPSImage alloc] init];
    result.image = out;
    return result;
}

- (VIPSImage *)resizeWithScale:(double)scale error:(NSError **)error {
    return [self resizeWithScale:scale kernel:VIPSResizeKernelLanczos3 error:error];
}

- (VIPSImage *)resizeWithScale:(double)scale
                        kernel:(VIPSResizeKernel)kernel
                         error:(NSError **)error {
    VipsImage *out = NULL;
    VipsKernel vipsKernel;

    switch (kernel) {
        case VIPSResizeKernelNearest:
            vipsKernel = VIPS_KERNEL_NEAREST;
            break;
        case VIPSResizeKernelLinear:
            vipsKernel = VIPS_KERNEL_LINEAR;
            break;
        case VIPSResizeKernelCubic:
            vipsKernel = VIPS_KERNEL_CUBIC;
            break;
        case VIPSResizeKernelLanczos2:
            vipsKernel = VIPS_KERNEL_LANCZOS2;
            break;
        case VIPSResizeKernelLanczos3:
        default:
            vipsKernel = VIPS_KERNEL_LANCZOS3;
            break;
    }

    if (vips_resize(self.image, &out, scale, "kernel", vipsKernel, NULL) != 0) {
        if (error) {
            *error = [self.class errorFromVips];
        }
        return nil;
    }

    VIPSImage *result = [[VIPSImage alloc] init];
    result.image = out;
    return result;
}

- (VIPSImage *)resizeToWidth:(NSInteger)width
                      height:(NSInteger)height
                       error:(NSError **)error {
    double hScale = (double)width / self.width;
    double vScale = (double)height / self.height;

    VipsImage *out = NULL;

    if (vips_resize(self.image, &out, hScale, "vscale", vScale, NULL) != 0) {
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
