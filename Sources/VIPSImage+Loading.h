//
//  VIPSImage+Loading.h
//  VIPSKit
//
//  Image loading and creation methods
//

#import "VIPSImage.h"

NS_ASSUME_NONNULL_BEGIN

@interface VIPSImage (Loading)

#pragma mark - Image Info

/// Get image dimensions and format without fully loading the image.
/// This only reads the file header, making it very fast and memory-efficient.
/// @param path Path to the image file
/// @param width On return, contains the image width (pass NULL to ignore)
/// @param height On return, contains the image height (pass NULL to ignore)
/// @param format On return, contains the detected format (pass NULL to ignore)
/// @param error On return, contains error if method returns NO
/// @return YES if successful, NO on error
+ (BOOL)getImageInfoAtPath:(NSString *)path
                     width:(NSInteger *_Nullable)width
                    height:(NSInteger *_Nullable)height
                    format:(VIPSImageFormat *_Nullable)format
                     error:(NSError *_Nullable *_Nullable)error;

#pragma mark - File Loading

/// Create an image from a file path
+ (nullable instancetype)imageWithContentsOfFile:(NSString *)path
                                           error:(NSError *_Nullable *_Nullable)error;

/// Load and thumbnail in one step - uses shrink-on-load for minimal memory.
/// This decodes directly at reduced resolution, much more efficient than
/// loading full image then resizing. Best for batch thumbnail generation.
+ (nullable instancetype)thumbnailFromFile:(NSString *)path
                                     width:(NSInteger)width
                                    height:(NSInteger)height
                                     error:(NSError *_Nullable *_Nullable)error;

/// Create thumbnail from NSData - uses shrink-on-load for minimal memory.
/// Same benefits as thumbnailFromFile but for in-memory data.
+ (nullable instancetype)thumbnailFromData:(NSData *)data
                                     width:(NSInteger)width
                                    height:(NSInteger)height
                                     error:(NSError *_Nullable *_Nullable)error;

/// Load image with sequential access (streaming mode).
/// Processes row-by-row to minimize memory for very large images.
/// The returned image must be processed sequentially (top to bottom).
+ (nullable instancetype)imageWithContentsOfFileSequential:(NSString *)path
                                                     error:(NSError *_Nullable *_Nullable)error;

#pragma mark - Data Loading

/// Create an image from NSData
+ (nullable instancetype)imageWithData:(NSData *)data
                                 error:(NSError *_Nullable *_Nullable)error;

/// Create an image from raw pixel buffer
+ (nullable instancetype)imageWithBuffer:(const void *)buffer
                                   width:(NSInteger)width
                                  height:(NSInteger)height
                                   bands:(NSInteger)bands
                                   error:(NSError *_Nullable *_Nullable)error;

@end

NS_ASSUME_NONNULL_END
