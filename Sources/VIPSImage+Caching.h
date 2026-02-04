//
//  VIPSImage+Caching.h
//  VIPSKit
//
//  Caching methods with explicit format control
//

#import "VIPSImage.h"

NS_ASSUME_NONNULL_BEGIN

@interface VIPSImage (Caching)

/// Export image data as lossless WebP for disk caching.
/// Lossless WebP is typically 30% smaller than PNG with no quality loss.
/// @param error On return, contains error if method returns nil
/// @return Lossless WebP data suitable for caching
- (nullable NSData *)cacheDataWithError:(NSError *_Nullable *_Nullable)error;

/// Export image data for caching with explicit format and quality.
/// @param format The image format to use
/// @param quality Quality for lossy formats (1-100), ignored for PNG/lossless
/// @param lossless YES for lossless encoding (WebP/JXL only), NO for lossy
/// @param error On return, contains error if method returns nil
/// @return Encoded image data
- (nullable NSData *)cacheDataWithFormat:(VIPSImageFormat)format
                                 quality:(NSInteger)quality
                                lossless:(BOOL)lossless
                                   error:(NSError *_Nullable *_Nullable)error;

/// Write image to cache file as lossless WebP.
/// Automatically appends .webp extension if not present.
/// @param path Path to write cache file
/// @param error On return, contains error if method returns NO
/// @return YES if successful
- (BOOL)writeToCacheFile:(NSString *)path
                   error:(NSError *_Nullable *_Nullable)error;

/// Write image to cache file with explicit format and quality.
/// @param path Path to write cache file
/// @param format The image format to use
/// @param quality Quality for lossy formats (1-100), ignored for PNG/lossless
/// @param lossless YES for lossless encoding (WebP/JXL only), NO for lossy
/// @param error On return, contains error if method returns NO
/// @return YES if successful
- (BOOL)writeToCacheFile:(NSString *)path
                  format:(VIPSImageFormat)format
                 quality:(NSInteger)quality
                lossless:(BOOL)lossless
                   error:(NSError *_Nullable *_Nullable)error;

@end

NS_ASSUME_NONNULL_END
