//
//  VIPSImage+Private.h
//  VIPSKit
//
//  Private header exposing internals for category implementations
//

#import "VIPSImage.h"
#import "vips/vips.h"

NS_ASSUME_NONNULL_BEGIN

/// Error domain for VIPS errors
extern NSString *const VIPSErrorDomain;

@interface VIPSImage ()

/// The underlying libvips image object
@property (nonatomic, assign) VipsImage *image;

/// Initialize with an existing VipsImage (takes ownership via ref)
- (instancetype)initWithVipsImage:(VipsImage *)image;

/// Create an NSError from the current vips error buffer
+ (NSError *)errorFromVips;

@end

NS_ASSUME_NONNULL_END
