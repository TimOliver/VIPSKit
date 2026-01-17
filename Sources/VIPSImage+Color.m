//
//  VIPSImage+Color.m
//  VIPSKit
//
//  Color space and color manipulation methods
//

#import "VIPSImage+Private.h"

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

@end
