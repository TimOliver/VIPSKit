//
//  VIPSImage+Transform.h
//  VIPSKit
//
//  Image transformation methods (crop, rotate, flip, smart crop)
//

#import "VIPSImage.h"

NS_ASSUME_NONNULL_BEGIN

@interface VIPSImage (Transform)

/// Crop a region from the image
- (nullable VIPSImage *)cropWithX:(NSInteger)x
                                y:(NSInteger)y
                            width:(NSInteger)width
                           height:(NSInteger)height
                            error:(NSError *_Nullable *_Nullable)error;

/// Rotate image by 90, 180, or 270 degrees
- (nullable VIPSImage *)rotateByDegrees:(NSInteger)degrees
                                  error:(NSError *_Nullable *_Nullable)error;

/// Flip image horizontally
- (nullable VIPSImage *)flipHorizontalWithError:(NSError *_Nullable *_Nullable)error;

/// Flip image vertically
- (nullable VIPSImage *)flipVerticalWithError:(NSError *_Nullable *_Nullable)error;

/// Auto-rotate based on EXIF orientation
- (nullable VIPSImage *)autoRotateWithError:(NSError *_Nullable *_Nullable)error;

/// Smart crop to target dimensions using content-aware cropping.
/// Analyzes image to find interesting regions before cropping.
/// @param width Target width
/// @param height Target height
/// @param interesting Strategy for finding interesting regions
/// @param error On return, contains error if method returns nil
/// @return Cropped image, or nil on error
- (nullable VIPSImage *)smartCropToWidth:(NSInteger)width
                                  height:(NSInteger)height
                             interesting:(VIPSInteresting)interesting
                                   error:(NSError *_Nullable *_Nullable)error;

@end

NS_ASSUME_NONNULL_END
