//
//  VIPSImage+Saving.h
//  VIPSKit
//
//  Image saving and export methods
//

#import "VIPSImage.h"

NS_ASSUME_NONNULL_BEGIN

@interface VIPSImage (Saving)

#pragma mark - File Saving

/// Save image to file (format determined by extension)
- (BOOL)writeToFile:(NSString *)path error:(NSError *_Nullable *_Nullable)error;

/// Save image to file with specific format and quality
- (BOOL)writeToFile:(NSString *)path
             format:(VIPSImageFormat)format
            quality:(NSInteger)quality
              error:(NSError *_Nullable *_Nullable)error;

#pragma mark - Data Export

/// Export image to NSData in specified format
- (nullable NSData *)dataWithFormat:(VIPSImageFormat)format
                            quality:(NSInteger)quality
                              error:(NSError *_Nullable *_Nullable)error;

@end

NS_ASSUME_NONNULL_END
