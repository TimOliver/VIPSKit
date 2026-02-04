//
//  VIPSImage+Resize.h
//  VIPSKit
//
//  Image resizing and thumbnail methods
//

#import "VIPSImage.h"

NS_ASSUME_NONNULL_BEGIN

@interface VIPSImage (Resize)

/// Resize image to fit within the given dimensions, maintaining aspect ratio.
/// Uses high-quality downscaling (Lanczos3). For low-memory thumbnailing from
/// files or data, use the class methods thumbnailFromFile: or thumbnailFromData: instead.
- (nullable VIPSImage *)resizeToFitWidth:(NSInteger)width
                                  height:(NSInteger)height
                                   error:(NSError *_Nullable *_Nullable)error;

/// Resize image by scale factor
- (nullable VIPSImage *)resizeWithScale:(double)scale
                                  error:(NSError *_Nullable *_Nullable)error;

/// Resize image by scale factor with specific kernel
- (nullable VIPSImage *)resizeWithScale:(double)scale
                                 kernel:(VIPSResizeKernel)kernel
                                  error:(NSError *_Nullable *_Nullable)error;

/// Resize image to exact dimensions
- (nullable VIPSImage *)resizeToWidth:(NSInteger)width
                               height:(NSInteger)height
                                error:(NSError *_Nullable *_Nullable)error;

@end

NS_ASSUME_NONNULL_END
