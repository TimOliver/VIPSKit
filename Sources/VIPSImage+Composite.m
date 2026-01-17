//
//  VIPSImage+Composite.m
//  VIPSKit
//
//  Image compositing and blending methods
//

#import "VIPSImage+Private.h"

@implementation VIPSImage (Composite)

- (VIPSImage *)compositeWithOverlay:(VIPSImage *)overlay
                               mode:(VIPSBlendMode)mode
                                  x:(NSInteger)x
                                  y:(NSInteger)y
                              error:(NSError **)error {
    VipsImage *out = NULL;
    int vipsMode = (int)mode;

    // Create position arrays (vips_composite2 expects arrays for x/y)
    int xArr[] = {(int)x};
    int yArr[] = {(int)y};
    VipsArrayInt *xArray = vips_array_int_new(xArr, 1);
    VipsArrayInt *yArray = vips_array_int_new(yArr, 1);

    // vips_composite2 composites overlay onto base with positioning
    int result = vips_composite2(self.image, overlay.image, &out, vipsMode,
                                  "x", xArray, "y", yArray, NULL);

    vips_area_unref(VIPS_AREA(xArray));
    vips_area_unref(VIPS_AREA(yArray));

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

- (VIPSImage *)compositeWithOverlay:(VIPSImage *)overlay
                               mode:(VIPSBlendMode)mode
                              error:(NSError **)error {
    // Center the overlay on this image
    NSInteger x = (self.width - overlay.width) / 2;
    NSInteger y = (self.height - overlay.height) / 2;

    return [self compositeWithOverlay:overlay mode:mode x:x y:y error:error];
}

@end
