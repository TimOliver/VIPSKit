//
//  VIPSImage+Transform.m
//  VIPSKit
//
//  Image transformation methods (crop, rotate, flip)
//

#import "VIPSImage+Private.h"

@implementation VIPSImage (Transform)

- (VIPSImage *)cropWithX:(NSInteger)x
                       y:(NSInteger)y
                   width:(NSInteger)width
                  height:(NSInteger)height
                   error:(NSError **)error {
    VipsImage *out = NULL;

    if (vips_crop(self.image, &out, (int)x, (int)y, (int)width, (int)height, NULL) != 0) {
        if (error) {
            *error = [self.class errorFromVips];
        }
        return nil;
    }

    VIPSImage *result = [[VIPSImage alloc] init];
    result.image = out;
    return result;
}

- (VIPSImage *)rotateByDegrees:(NSInteger)degrees error:(NSError **)error {
    VipsImage *out = NULL;
    VipsAngle angle;

    switch (degrees % 360) {
        case 90:
        case -270:
            angle = VIPS_ANGLE_D90;
            break;
        case 180:
        case -180:
            angle = VIPS_ANGLE_D180;
            break;
        case 270:
        case -90:
            angle = VIPS_ANGLE_D270;
            break;
        default:
            angle = VIPS_ANGLE_D0;
            break;
    }

    if (vips_rot(self.image, &out, angle, NULL) != 0) {
        if (error) {
            *error = [self.class errorFromVips];
        }
        return nil;
    }

    VIPSImage *result = [[VIPSImage alloc] init];
    result.image = out;
    return result;
}

- (VIPSImage *)flipHorizontalWithError:(NSError **)error {
    VipsImage *out = NULL;

    if (vips_flip(self.image, &out, VIPS_DIRECTION_HORIZONTAL, NULL) != 0) {
        if (error) {
            *error = [self.class errorFromVips];
        }
        return nil;
    }

    VIPSImage *result = [[VIPSImage alloc] init];
    result.image = out;
    return result;
}

- (VIPSImage *)flipVerticalWithError:(NSError **)error {
    VipsImage *out = NULL;

    if (vips_flip(self.image, &out, VIPS_DIRECTION_VERTICAL, NULL) != 0) {
        if (error) {
            *error = [self.class errorFromVips];
        }
        return nil;
    }

    VIPSImage *result = [[VIPSImage alloc] init];
    result.image = out;
    return result;
}

- (VIPSImage *)autoRotateWithError:(NSError **)error {
    VipsImage *out = NULL;

    if (vips_autorot(self.image, &out, NULL) != 0) {
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
