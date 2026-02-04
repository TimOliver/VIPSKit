//
//  VIPSImage+Color.m
//  VIPSKit
//
//  Color space and color manipulation methods
//

#import "VIPSImage+Color.h"
#import "VIPSImage+Private.h"
#import <math.h>
#import <math.h>

@implementation VIPSImage (Color)

- (VIPSImage *)grayscaleWithError:(NSError **)error {
    VipsImage *out = NULL;

    if (vips_colourspace(self.image, &out, VIPS_INTERPRETATION_B_W, NULL) != 0) {
        if (error) {
            *error = [self.class errorFromVips];
        }
        return nil;
    }

    VIPSImage *result = [[VIPSImage alloc] init];
    result.image = out;
    return result;
}

- (VIPSImage *)flattenWithRed:(NSInteger)red
                        green:(NSInteger)green
                         blue:(NSInteger)blue
                        error:(NSError **)error {
    VipsImage *out = NULL;
    VipsArrayDouble *background = vips_array_double_newv(3,
                                                          (double)red,
                                                          (double)green,
                                                          (double)blue);

    int result = vips_flatten(self.image, &out, "background", background, NULL);
    vips_area_unref(VIPS_AREA(background));

    if (result != 0) {
        if (error) {
            *error = [self.class errorFromVips];
        }
        return nil;
    }

    VIPSImage *wrapper = [[VIPSImage alloc] init];
    wrapper.image = out;
    return wrapper;
}

- (VIPSImage *)invertWithError:(NSError **)error {
    VipsImage *out = NULL;

    if (vips_invert(self.image, &out, NULL) != 0) {
        if (error) {
            *error = [self.class errorFromVips];
        }
        return nil;
    }

    VIPSImage *result = [[VIPSImage alloc] init];
    result.image = out;
    return result;
}

- (VIPSImage *)adjustBrightness:(double)brightness error:(NSError **)error {
    // Brightness: add a constant to all pixels
    // brightness is -1 to 1, map to -255 to 255
    double offset = brightness * 255.0;

    VipsImage *out = NULL;
    double a[] = {1.0, 1.0, 1.0};  // Multiplier (no change)
    double b[] = {offset, offset, offset};  // Offset

    if (vips_linear(self.image, &out, a, b, self.hasAlpha ? 3 : (int)self.bands, NULL) != 0) {
        if (error) {
            *error = [self.class errorFromVips];
        }
        return nil;
    }

    VIPSImage *result = [[VIPSImage alloc] init];
    result.image = out;
    return result;
}

- (VIPSImage *)adjustContrast:(double)contrast error:(NSError **)error {
    // Contrast: multiply around midpoint (127.5)
    // output = (input - 127.5) * contrast + 127.5
    // output = input * contrast + 127.5 * (1 - contrast)
    double offset = 127.5 * (1.0 - contrast);

    VipsImage *out = NULL;
    double a[] = {contrast, contrast, contrast};
    double b[] = {offset, offset, offset};

    if (vips_linear(self.image, &out, a, b, self.hasAlpha ? 3 : (int)self.bands, NULL) != 0) {
        if (error) {
            *error = [self.class errorFromVips];
        }
        return nil;
    }

    VIPSImage *result = [[VIPSImage alloc] init];
    result.image = out;
    return result;
}

- (VIPSImage *)adjustSaturation:(double)saturation error:(NSError **)error {
    // Use LCh color space for perceptually uniform saturation adjustment
    // Convert to LCh, multiply C (chroma) channel, convert back

    VipsImage *lch = NULL;
    VipsImage *adjusted = NULL;
    VipsImage *out = NULL;

    // Convert to LCh
    if (vips_colourspace(self.image, &lch, VIPS_INTERPRETATION_LCH, NULL) != 0) {
        if (error) {
            *error = [self.class errorFromVips];
        }
        return nil;
    }

    // Multiply the C (chroma) channel by saturation factor
    // LCh has bands: L, C, h - we want to multiply band 1 (C)
    double a[] = {1.0, saturation, 1.0};  // L unchanged, C multiplied, h unchanged
    double b[] = {0.0, 0.0, 0.0};

    if (vips_linear(lch, &adjusted, a, b, 3, NULL) != 0) {
        g_object_unref(lch);
        if (error) {
            *error = [self.class errorFromVips];
        }
        return nil;
    }
    g_object_unref(lch);

    // Convert back to sRGB
    if (vips_colourspace(adjusted, &out, VIPS_INTERPRETATION_sRGB, NULL) != 0) {
        g_object_unref(adjusted);
        if (error) {
            *error = [self.class errorFromVips];
        }
        return nil;
    }
    g_object_unref(adjusted);

    VIPSImage *result = [[VIPSImage alloc] init];
    result.image = out;
    return result;
}

- (VIPSImage *)adjustGamma:(double)gamma error:(NSError **)error {
    VipsImage *out = NULL;

    if (vips_gamma(self.image, &out, "exponent", 1.0 / gamma, NULL) != 0) {
        if (error) {
            *error = [self.class errorFromVips];
        }
        return nil;
    }

    VIPSImage *result = [[VIPSImage alloc] init];
    result.image = out;
    return result;
}

- (VIPSImage *)adjustBrightness:(double)brightness
                       contrast:(double)contrast
                     saturation:(double)saturation
                          error:(NSError **)error {
    // Combined adjustment - more efficient than separate calls
    // First apply brightness and contrast, then saturation

    // Step 1: Brightness and contrast combined
    // output = input * contrast + 127.5 * (1 - contrast) + brightness * 255
    double offset = 127.5 * (1.0 - contrast) + brightness * 255.0;

    VipsImage *bcAdjusted = NULL;
    double a[] = {contrast, contrast, contrast};
    double b[] = {offset, offset, offset};

    if (vips_linear(self.image, &bcAdjusted, a, b, self.hasAlpha ? 3 : (int)self.bands, NULL) != 0) {
        if (error) {
            *error = [self.class errorFromVips];
        }
        return nil;
    }

    // Step 2: Saturation adjustment
    if (fabs(saturation - 1.0) < 0.001) {
        // No saturation change needed
        VIPSImage *result = [[VIPSImage alloc] init];
        result.image = bcAdjusted;
        return result;
    }

    VipsImage *lch = NULL;
    VipsImage *satAdjusted = NULL;
    VipsImage *out = NULL;

    // Convert to LCh
    if (vips_colourspace(bcAdjusted, &lch, VIPS_INTERPRETATION_LCH, NULL) != 0) {
        g_object_unref(bcAdjusted);
        if (error) {
            *error = [self.class errorFromVips];
        }
        return nil;
    }
    g_object_unref(bcAdjusted);

    // Adjust chroma
    double sa[] = {1.0, saturation, 1.0};
    double sb[] = {0.0, 0.0, 0.0};

    if (vips_linear(lch, &satAdjusted, sa, sb, 3, NULL) != 0) {
        g_object_unref(lch);
        if (error) {
            *error = [self.class errorFromVips];
        }
        return nil;
    }
    g_object_unref(lch);

    // Convert back to sRGB
    if (vips_colourspace(satAdjusted, &out, VIPS_INTERPRETATION_sRGB, NULL) != 0) {
        g_object_unref(satAdjusted);
        if (error) {
            *error = [self.class errorFromVips];
        }
        return nil;
    }
    g_object_unref(satAdjusted);

    VIPSImage *result = [[VIPSImage alloc] init];
    result.image = out;
    return result;
}

@end
