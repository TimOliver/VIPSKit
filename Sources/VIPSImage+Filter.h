//
//  VIPSImage+Filter.h
//  VIPSKit
//
//  Image filter methods (blur, sharpen, edge detection)
//

#import "VIPSImage.h"

NS_ASSUME_NONNULL_BEGIN

@interface VIPSImage (Filter)

#pragma mark - Blur and Sharpen

/// Apply Gaussian blur
- (nullable VIPSImage *)blurWithSigma:(double)sigma
                                error:(NSError *_Nullable *_Nullable)error;

/// Sharpen image
- (nullable VIPSImage *)sharpenWithSigma:(double)sigma
                                   error:(NSError *_Nullable *_Nullable)error;

#pragma mark - Edge Detection

/// Detect edges using Sobel operator.
/// Fast edge detection, returns grayscale edge magnitude image.
/// @param error On return, contains error if method returns nil
/// @return Edge-detected image, or nil on error
- (nullable VIPSImage *)sobelWithError:(NSError *_Nullable *_Nullable)error;

/// Detect edges using Canny algorithm.
/// More sophisticated edge detection with Gaussian smoothing.
/// @param sigma Standard deviation of Gaussian (1.4 is typical)
/// @param error On return, contains error if method returns nil
/// @return Edge-detected image, or nil on error
- (nullable VIPSImage *)cannyWithSigma:(double)sigma
                                 error:(NSError *_Nullable *_Nullable)error;

@end

NS_ASSUME_NONNULL_END
