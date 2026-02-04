//
//  VIPSImage+Filter.m
//  VIPSKit
//
//  Image filter methods (blur, sharpen)
//

#import "VIPSImage+Filter.h"
#import "VIPSImage+Private.h"

@implementation VIPSImage (Filter)

- (VIPSImage *)blurWithSigma:(double)sigma error:(NSError **)error {
    VipsImage *out = NULL;

    if (vips_gaussblur(self.image, &out, sigma, NULL) != 0) {
        if (error) {
            *error = [self.class errorFromVips];
        }
        return nil;
    }

    VIPSImage *result = [[VIPSImage alloc] init];
    result.image = out;
    return result;
}

- (VIPSImage *)sharpenWithSigma:(double)sigma error:(NSError **)error {
    VipsImage *out = NULL;

    if (vips_sharpen(self.image, &out, "sigma", sigma, NULL) != 0) {
        if (error) {
            *error = [self.class errorFromVips];
        }
        return nil;
    }

    VIPSImage *result = [[VIPSImage alloc] init];
    result.image = out;
    return result;
}

#pragma mark - Edge Detection

- (VIPSImage *)sobelWithError:(NSError **)error {
    VipsImage *out = NULL;

    if (vips_sobel(self.image, &out, NULL) != 0) {
        if (error) {
            *error = [self.class errorFromVips];
        }
        return nil;
    }

    VIPSImage *result = [[VIPSImage alloc] init];
    result.image = out;
    return result;
}

- (VIPSImage *)cannyWithSigma:(double)sigma error:(NSError **)error {
    VipsImage *out = NULL;

    if (vips_canny(self.image, &out, "sigma", sigma, NULL) != 0) {
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
