//
//  VIPSImage+Color.h
//  VIPSKit
//
//  Color space and color manipulation methods
//

#import "VIPSImage.h"

NS_ASSUME_NONNULL_BEGIN

@interface VIPSImage (Color)

/// Convert to grayscale
- (nullable VIPSImage *)grayscaleWithError:(NSError *_Nullable *_Nullable)error;

/// Flatten alpha channel against a background color (RGB 0-255)
- (nullable VIPSImage *)flattenWithRed:(NSInteger)red
                                 green:(NSInteger)green
                                  blue:(NSInteger)blue
                                 error:(NSError *_Nullable *_Nullable)error;

/// Invert colors (negative)
- (nullable VIPSImage *)invertWithError:(NSError *_Nullable *_Nullable)error;

/// Adjust brightness.
/// @param brightness Brightness adjustment (-1.0 to 1.0, 0 = no change)
/// @param error On return, contains error if method returns nil
/// @return Adjusted image, or nil on error
- (nullable VIPSImage *)adjustBrightness:(double)brightness
                                   error:(NSError *_Nullable *_Nullable)error;

/// Adjust contrast.
/// @param contrast Contrast multiplier (0.5 to 2.0, 1.0 = no change)
/// @param error On return, contains error if method returns nil
/// @return Adjusted image, or nil on error
- (nullable VIPSImage *)adjustContrast:(double)contrast
                                 error:(NSError *_Nullable *_Nullable)error;

/// Adjust saturation.
/// @param saturation Saturation multiplier (0 = grayscale, 1.0 = no change, 2.0 = double)
/// @param error On return, contains error if method returns nil
/// @return Adjusted image, or nil on error
- (nullable VIPSImage *)adjustSaturation:(double)saturation
                                   error:(NSError *_Nullable *_Nullable)error;

/// Adjust gamma (brightness curve).
/// @param gamma Gamma value (< 1.0 lightens midtones, > 1.0 darkens midtones)
/// @param error On return, contains error if method returns nil
/// @return Adjusted image, or nil on error
- (nullable VIPSImage *)adjustGamma:(double)gamma
                              error:(NSError *_Nullable *_Nullable)error;

/// Adjust brightness, contrast, and saturation in one operation.
/// More efficient than calling each method separately.
/// @param brightness Brightness adjustment (-1.0 to 1.0, 0 = no change)
/// @param contrast Contrast multiplier (0.5 to 2.0, 1.0 = no change)
/// @param saturation Saturation multiplier (0 = grayscale, 1.0 = no change)
/// @param error On return, contains error if method returns nil
/// @return Adjusted image, or nil on error
- (nullable VIPSImage *)adjustBrightness:(double)brightness
                                contrast:(double)contrast
                              saturation:(double)saturation
                                   error:(NSError *_Nullable *_Nullable)error;

@end

NS_ASSUME_NONNULL_END
