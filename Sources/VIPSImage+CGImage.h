//
//  VIPSImage+CGImage.h
//  VIPSKit
//
//  CoreGraphics integration methods
//

#import "VIPSImage.h"

NS_ASSUME_NONNULL_BEGIN

@interface VIPSImage (CGImage)

#pragma mark - Class Methods

/// Decode directly to a downscaled CGImage with minimal peak memory.
/// Decodes, resizes, converts to CGImage, and releases decode buffers in one operation.
/// This is the most memory-efficient path for thumbnail generation.
/// @return CGImage that caller must release with CGImageRelease
+ (nullable CGImageRef)createThumbnailFromFile:(NSString *)path
                                         width:(NSInteger)width
                                        height:(NSInteger)height
                                         error:(NSError *_Nullable *_Nullable)error CF_RETURNS_RETAINED;

#pragma mark - Instance Methods

/// Create a CGImage from the vips image (caller must release with CGImageRelease)
/// This is the most efficient way to display the image as it avoids encoding/decoding.
- (nullable CGImageRef)createCGImageWithError:(NSError *_Nullable *_Nullable)error CF_RETURNS_RETAINED;

/// Create a CGImage with specified color space (caller must release with CGImageRelease)
- (nullable CGImageRef)createCGImageWithColorSpace:(CGColorSpaceRef)colorSpace
                                             error:(NSError *_Nullable *_Nullable)error CF_RETURNS_RETAINED;

@end

NS_ASSUME_NONNULL_END
