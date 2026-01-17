//
//  VIPSImage.h
//  VIPSKit
//
//  Objective-C wrapper for libvips image processing
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

/// Image format for saving and detection
typedef NS_ENUM(NSInteger, VIPSImageFormat) {
    VIPSImageFormatUnknown = -1,
    VIPSImageFormatJPEG,
    VIPSImageFormatPNG,
    VIPSImageFormatWebP,
    VIPSImageFormatHEIF,
    VIPSImageFormatAVIF,
    VIPSImageFormatJXL,
    VIPSImageFormatGIF
};

/// Resize kernel/interpolation method
typedef NS_ENUM(NSInteger, VIPSResizeKernel) {
    VIPSResizeKernelNearest,
    VIPSResizeKernelLinear,
    VIPSResizeKernelCubic,
    VIPSResizeKernelLanczos2,
    VIPSResizeKernelLanczos3
};

/// Image processing wrapper for libvips
@interface VIPSImage : NSObject

#pragma mark - Properties

/// Width of the image in pixels
@property (nonatomic, readonly) NSInteger width;

/// Height of the image in pixels
@property (nonatomic, readonly) NSInteger height;

/// Number of bands (channels) in the image
@property (nonatomic, readonly) NSInteger bands;

/// Whether the image has an alpha channel
@property (nonatomic, readonly) BOOL hasAlpha;

/// Detected source format of the image (based on loader used)
@property (nonatomic, readonly) VIPSImageFormat sourceFormat;

/// Loader name used to load the image (e.g., "jpegload", "pngload")
@property (nonatomic, readonly, nullable) NSString *loaderName;

#pragma mark - Initialization

/// Initialize the VIPS library. Call once at app startup.
+ (BOOL)initializeWithError:(NSError *_Nullable *_Nullable)error;

/// Shutdown the VIPS library. Call at app termination.
+ (void)shutdown;

#pragma mark - Memory Management

/// Clear all cached operations and free associated memory.
/// Call this after processing to release memory held by libvips cache.
+ (void)clearCache;

/// Set maximum number of operations to cache (default is 1000).
/// Set to 0 to disable operation caching entirely.
+ (void)setCacheMaxOperations:(NSInteger)max;

/// Set maximum memory used by operation cache in bytes.
/// Set to 0 for no limit based on memory.
+ (void)setCacheMaxMemory:(NSInteger)bytes;

/// Set maximum number of open files in cache.
+ (void)setCacheMaxFiles:(NSInteger)max;

/// Get current memory usage tracked by VIPS in bytes.
+ (NSInteger)memoryUsage;

/// Get peak memory usage tracked by VIPS in bytes.
+ (NSInteger)memoryHighWater;

/// Reset peak memory tracking.
+ (void)resetMemoryHighWater;

/// Set the number of threads used by VIPS for processing (affects JXL, resize, etc).
/// Default after initialize is 1 (single-threaded, optimal for batch processing).
/// Set to 0 for auto-detect (all CPU cores) for single-image processing.
+ (void)setConcurrency:(NSInteger)threads;

/// Get the current VIPS concurrency setting.
+ (NSInteger)concurrency;

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

/// Decode directly to a downscaled CGImage with minimal peak memory.
/// Decodes, resizes, converts to CGImage, and releases decode buffers in one operation.
/// This is the most memory-efficient path for thumbnail generation.
/// @return CGImage that caller must release with CGImageRelease
+ (nullable CGImageRef)createThumbnailFromFile:(NSString *)path
                                         width:(NSInteger)width
                                        height:(NSInteger)height
                                         error:(NSError *_Nullable *_Nullable)error CF_RETURNS_RETAINED;

/// Create an image from NSData
+ (nullable instancetype)imageWithData:(NSData *)data
                                 error:(NSError *_Nullable *_Nullable)error;

/// Create an image from raw pixel buffer
+ (nullable instancetype)imageWithBuffer:(const void *)buffer
                                   width:(NSInteger)width
                                  height:(NSInteger)height
                                   bands:(NSInteger)bands
                                   error:(NSError *_Nullable *_Nullable)error;

#pragma mark - Saving

/// Save image to file (format determined by extension)
- (BOOL)writeToFile:(NSString *)path error:(NSError *_Nullable *_Nullable)error;

/// Save image to file with specific format and quality
- (BOOL)writeToFile:(NSString *)path
             format:(VIPSImageFormat)format
            quality:(NSInteger)quality
              error:(NSError *_Nullable *_Nullable)error;

/// Export image to NSData in specified format
- (nullable NSData *)dataWithFormat:(VIPSImageFormat)format
                            quality:(NSInteger)quality
                              error:(NSError *_Nullable *_Nullable)error;

#pragma mark - Resizing

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

#pragma mark - Transformations

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

#pragma mark - Color Operations

/// Convert to grayscale
- (nullable VIPSImage *)grayscaleWithError:(NSError *_Nullable *_Nullable)error;

/// Flatten alpha channel against a background color (RGB 0-255)
- (nullable VIPSImage *)flattenWithRed:(NSInteger)red
                                 green:(NSInteger)green
                                  blue:(NSInteger)blue
                                 error:(NSError *_Nullable *_Nullable)error;

#pragma mark - Filters

/// Apply Gaussian blur
- (nullable VIPSImage *)blurWithSigma:(double)sigma
                                error:(NSError *_Nullable *_Nullable)error;

/// Sharpen image
- (nullable VIPSImage *)sharpenWithSigma:(double)sigma
                                   error:(NSError *_Nullable *_Nullable)error;

#pragma mark - Tiling

/// Calculate tile rects for dividing the image into tiles of the given size.
/// The last row/column of tiles may be smaller if the image doesn't divide evenly.
/// @param tileWidth Desired width of each tile
/// @param tileHeight Desired height of each tile
/// @return Array of CGRect values wrapped in NSValue, row-major order (left-to-right, top-to-bottom)
- (NSArray<NSValue *> *)tileRectsWithTileWidth:(NSInteger)tileWidth
                                    tileHeight:(NSInteger)tileHeight;

/// Number of horizontal strips needed to cover the image with strips of given height.
/// @param stripHeight Height of each strip
/// @return Number of strips (last strip may be shorter)
- (NSInteger)numberOfStripsWithHeight:(NSInteger)stripHeight;

/// Extract a horizontal strip from the image (full width, partial height).
/// For a 500x30000 image with stripHeight=1000, you'd have 30 strips.
/// @param index Strip index (0-based, from top)
/// @param stripHeight Height of each strip (last strip may be shorter)
/// @param error On return, contains error if method returns nil
/// @return The strip image, or nil on error
- (nullable VIPSImage *)stripAtIndex:(NSInteger)index
                              height:(NSInteger)stripHeight
                               error:(NSError *_Nullable *_Nullable)error;

/// Extract a region directly from a file without fully loading the image.
/// This is more memory-efficient than loading the full image and cropping.
/// Uses sequential access internally for optimal memory usage.
/// @param path Path to the image file
/// @param x X coordinate of region origin
/// @param y Y coordinate of region origin
/// @param width Width of region to extract
/// @param height Height of region to extract
/// @param error On return, contains error if method returns nil
/// @return The extracted region, or nil on error
+ (nullable instancetype)extractRegionFromFile:(NSString *)path
                                             x:(NSInteger)x
                                             y:(NSInteger)y
                                         width:(NSInteger)width
                                        height:(NSInteger)height
                                         error:(NSError *_Nullable *_Nullable)error;

/// Extract a region from compressed image data without fully decoding.
/// Same as extractRegionFromFile: but for in-memory data.
/// @param data Compressed image data (JPEG, PNG, etc.)
/// @param x X coordinate of region origin
/// @param y Y coordinate of region origin
/// @param width Width of region to extract
/// @param height Height of region to extract
/// @param error On return, contains error if method returns nil
/// @return The extracted region, or nil on error
+ (nullable instancetype)extractRegionFromData:(NSData *)data
                                             x:(NSInteger)x
                                             y:(NSInteger)y
                                         width:(NSInteger)width
                                        height:(NSInteger)height
                                         error:(NSError *_Nullable *_Nullable)error;

#pragma mark - Memory Management

/// Copy image pixels to memory, breaking lazy evaluation chain.
/// Call this after operations like thumbnail to allow the source image to be freed.
/// Returns a new VIPSImage that doesn't reference the original.
- (nullable VIPSImage *)copyToMemoryWithError:(NSError *_Nullable *_Nullable)error;

#pragma mark - CoreGraphics Integration

/// Create a CGImage from the vips image (caller must release with CGImageRelease)
/// This is the most efficient way to display the image as it avoids encoding/decoding.
- (nullable CGImageRef)createCGImageWithError:(NSError *_Nullable *_Nullable)error CF_RETURNS_RETAINED;

/// Create a CGImage with specified color space (caller must release with CGImageRelease)
- (nullable CGImageRef)createCGImageWithColorSpace:(CGColorSpaceRef)colorSpace
                                             error:(NSError *_Nullable *_Nullable)error CF_RETURNS_RETAINED;

#pragma mark - Caching

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
