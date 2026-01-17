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

    // vips_composite2 composites overlay onto base with positioning
    if (vips_composite2(self.image, overlay.image, &out, vipsMode,
                        "x", (int)x, "y", (int)y, NULL) != 0) {
        if (error) {
            *error = [self.class errorFromVips];
        }
        return nil;
    }

    VIPSImage *result = [[VIPSImage alloc] init];
    result.image = out;
    return result;
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
