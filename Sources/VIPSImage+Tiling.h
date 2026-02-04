//
//  VIPSImage+Tiling.h
//  VIPSKit
//
//  Tiling and region extraction for large images
//

#import "VIPSImage.h"

NS_ASSUME_NONNULL_BEGIN

@interface VIPSImage (Tiling)

#pragma mark - Tile Calculation

/// Calculate tile rects for dividing the image into tiles of the given size.
/// The last row/column of tiles may be smaller if the image doesn't divide evenly.
/// @param tileWidth Desired width of each tile
/// @param tileHeight Desired height of each tile
/// @return Array of CGRect values wrapped in NSValue, row-major order (left-to-right, top-to-bottom)
- (NSArray<NSValue *> *)tileRectsWithTileWidth:(NSInteger)tileWidth
                                    tileHeight:(NSInteger)tileHeight;

#pragma mark - Strip Extraction

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

#pragma mark - Region Extraction

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

@end

NS_ASSUME_NONNULL_END
