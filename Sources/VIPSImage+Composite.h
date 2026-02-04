//
//  VIPSImage+Composite.h
//  VIPSKit
//
//  Image compositing and blending methods
//

#import "VIPSImage.h"

NS_ASSUME_NONNULL_BEGIN

@interface VIPSImage (Composite)

/// Composite an overlay image onto this image using the specified blend mode.
/// @param overlay The image to composite on top
/// @param mode The blend mode to use
/// @param x X position of overlay on base image
/// @param y Y position of overlay on base image
/// @param error On return, contains error if method returns nil
/// @return Composited image, or nil on error
- (nullable VIPSImage *)compositeWithOverlay:(VIPSImage *)overlay
                                        mode:(VIPSBlendMode)mode
                                           x:(NSInteger)x
                                           y:(NSInteger)y
                                       error:(NSError *_Nullable *_Nullable)error;

/// Composite an overlay image centered on this image.
/// @param overlay The image to composite on top
/// @param mode The blend mode to use
/// @param error On return, contains error if method returns nil
/// @return Composited image, or nil on error
- (nullable VIPSImage *)compositeWithOverlay:(VIPSImage *)overlay
                                        mode:(VIPSBlendMode)mode
                                       error:(NSError *_Nullable *_Nullable)error;

@end

NS_ASSUME_NONNULL_END
