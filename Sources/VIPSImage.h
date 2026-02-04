//
//  VIPSImage.h
//  VIPSKit
//
//  Objective-C wrapper for libvips image processing
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Enumerations

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

/// Smart crop strategy for finding interesting regions
typedef NS_ENUM(NSInteger, VIPSInteresting) {
    VIPSInterestingNone,       ///< Don't look for interesting areas
    VIPSInterestingCentre,     ///< Crop from center
    VIPSInterestingEntropy,    ///< Crop to maximize entropy
    VIPSInterestingAttention,  ///< Crop using attention strategy (edges, skin tones, saturated colors)
    VIPSInterestingLow,        ///< Crop from low coordinate
    VIPSInterestingHigh        ///< Crop from high coordinate
};

/// Blend modes for image compositing
typedef NS_ENUM(NSInteger, VIPSBlendMode) {
    VIPSBlendModeClear,
    VIPSBlendModeSource,
    VIPSBlendModeOver,         ///< Standard alpha compositing (most common)
    VIPSBlendModeIn,
    VIPSBlendModeOut,
    VIPSBlendModeAtop,
    VIPSBlendModeDest,
    VIPSBlendModeDestOver,
    VIPSBlendModeDestIn,
    VIPSBlendModeDestOut,
    VIPSBlendModeDestAtop,
    VIPSBlendModeXor,
    VIPSBlendModeAdd,
    VIPSBlendModeSaturate,
    VIPSBlendModeMultiply,     ///< Darken by multiplying
    VIPSBlendModeScreen,       ///< Lighten (inverse of multiply)
    VIPSBlendModeOverlay,      ///< Multiply or screen depending on base
    VIPSBlendModeDarken,
    VIPSBlendModeLighten,
    VIPSBlendModeColourDodge,
    VIPSBlendModeColourBurn,
    VIPSBlendModeHardLight,
    VIPSBlendModeSoftLight,
    VIPSBlendModeDifference,
    VIPSBlendModeExclusion
};

#pragma mark - VIPSImageStatistics

/// Image statistics (min, max, mean, standard deviation)
@interface VIPSImageStatistics : NSObject
@property (nonatomic, readonly) double min;
@property (nonatomic, readonly) double max;
@property (nonatomic, readonly) double mean;
@property (nonatomic, readonly) double standardDeviation;
@end

#pragma mark - VIPSImage

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

/// Copy image pixels to memory, breaking lazy evaluation chain.
/// Call this after operations like thumbnail to allow the source image to be freed.
/// Returns a new VIPSImage that doesn't reference the original.
- (nullable VIPSImage *)copyToMemoryWithError:(NSError *_Nullable *_Nullable)error;

#pragma mark - Pixel Access

/// Access raw pixel data with zero-copy block-based API.
/// The pixel data is only valid within the block scope - do not store the pointer.
/// Data is 8-bit per channel, in RGB or RGBA format (check bands for alpha).
/// @param block Block called with pixel data and image dimensions
/// @param error On return, contains error if method returns NO
/// @return YES if successful, NO on error
- (BOOL)withPixelData:(void (NS_NOESCAPE ^)(const uint8_t *data,
                                            NSInteger width,
                                            NSInteger height,
                                            NSInteger bytesPerRow,
                                            NSInteger bands))block
                error:(NSError *_Nullable *_Nullable)error;

#pragma mark - Analysis

/// Find the bounding box of non-background pixels (trim margins).
/// Automatically detects the background color from image edges.
/// Uses a default threshold of 10.0 for pixel difference detection.
/// @param error On return, contains error if method returns CGRectNull
/// @return Bounding box of content, or CGRectNull on error
- (CGRect)findTrimWithError:(NSError *_Nullable *_Nullable)error;

/// Find the bounding box of non-background pixels with custom threshold.
/// Automatically detects the background color from image edges.
/// @param threshold How different a pixel must be from background to count as content (default 10.0)
/// @param error On return, contains error if method returns CGRectNull
/// @return Bounding box of content, or CGRectNull on error
- (CGRect)findTrimWithThreshold:(double)threshold
                          error:(NSError *_Nullable *_Nullable)error;

/// Find the bounding box of non-background pixels with custom threshold and background.
/// @param threshold How different a pixel must be from background to count as content
/// @param background Background color as array of doubles (e.g., @[@255, @255, @255] for white), or nil to auto-detect
/// @param error On return, contains error if method returns CGRectNull
/// @return Bounding box of content, or CGRectNull on error
- (CGRect)findTrimWithThreshold:(double)threshold
                     background:(nullable NSArray<NSNumber *> *)background
                          error:(NSError *_Nullable *_Nullable)error;

/// Get image statistics (min, max, mean, standard deviation) across all pixels.
/// For multi-band images, computes statistics across all bands combined.
/// @param error On return, contains error if method returns nil
/// @return Statistics object, or nil on error
- (nullable VIPSImageStatistics *)statisticsWithError:(NSError *_Nullable *_Nullable)error;

/// Get the average color of the image as per-band mean values.
/// Returns an array of doubles representing mean value for each band (e.g., [R, G, B] or [R, G, B, A]).
/// Values are in the range 0-255 for 8-bit images.
/// @param error On return, contains error if method returns nil
/// @return Array of per-band mean values, or nil on error
- (nullable NSArray<NSNumber *> *)averageColorWithError:(NSError *_Nullable *_Nullable)error;

/// Detect the background color by sampling the edges of the image.
/// Samples a thin strip around all four edges and returns the average color.
/// Useful for setting a matching background color in an image viewer.
/// @param error On return, contains error if method returns nil
/// @return Array of per-band mean values from edge pixels, or nil on error
- (nullable NSArray<NSNumber *> *)detectBackgroundColorWithError:(NSError *_Nullable *_Nullable)error;

/// Detect the background color by sampling edges with custom strip width.
/// @param stripWidth Width of edge strip to sample (default 10 pixels)
/// @param error On return, contains error if method returns nil
/// @return Array of per-band mean values from edge pixels, or nil on error
- (nullable NSArray<NSNumber *> *)detectBackgroundColorWithStripWidth:(NSInteger)stripWidth
                                                                error:(NSError *_Nullable *_Nullable)error;

#pragma mark - Arithmetic

/// Subtract another image from this image (pixel-wise: self - other).
/// Images should have the same dimensions. Result may contain negative values.
/// @param image The image to subtract
/// @param error On return, contains error if method returns nil
/// @return Result image, or nil on error
- (nullable VIPSImage *)subtract:(VIPSImage *)image error:(NSError *_Nullable *_Nullable)error;

/// Compute absolute value of each pixel.
/// Useful after subtraction to get absolute differences.
/// @param error On return, contains error if method returns nil
/// @return Result image, or nil on error
- (nullable VIPSImage *)absoluteWithError:(NSError *_Nullable *_Nullable)error;

@end

NS_ASSUME_NONNULL_END

// Category headers - import after main class definition
#import "VIPSImage+Loading.h"
#import "VIPSImage+Saving.h"
#import "VIPSImage+Resize.h"
#import "VIPSImage+Transform.h"
#import "VIPSImage+Color.h"
#import "VIPSImage+Filter.h"
#import "VIPSImage+CGImage.h"
#import "VIPSImage+Composite.h"
#import "VIPSImage+Tiling.h"
#import "VIPSImage+Caching.h"
