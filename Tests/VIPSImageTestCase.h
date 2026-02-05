//
//  VIPSImageTestCase.h
//  VIPSKitTests
//
//  Base test case class with shared setup and helper methods
//

#import <XCTest/XCTest.h>
#import "VIPSImage.h"

NS_ASSUME_NONNULL_BEGIN

@interface VIPSImageTestCase : XCTestCase

/// Path to a test resource file, or nil if not found
- (nullable NSString *)pathForTestResource:(NSString *)filename;

/// Create a test image with RGB gradient pattern
- (VIPSImage *)createTestImageWithWidth:(NSInteger)width height:(NSInteger)height;

/// Create a test image with specified number of bands
- (VIPSImage *)createTestImageWithWidth:(NSInteger)width height:(NSInteger)height bands:(NSInteger)bands;

/// Create a solid color image (RGB, values 0-255)
- (VIPSImage *)createSolidColorImageWithWidth:(NSInteger)width
                                       height:(NSInteger)height
                                          red:(uint8_t)r
                                        green:(uint8_t)g
                                         blue:(uint8_t)b;

/// Create a solid color image with alpha (RGBA, values 0-255)
- (VIPSImage *)createSolidColorImageWithWidth:(NSInteger)width
                                       height:(NSInteger)height
                                          red:(uint8_t)r
                                        green:(uint8_t)g
                                         blue:(uint8_t)b
                                        alpha:(uint8_t)a;

/// Create an image with colored content surrounded by margins
/// Content is centered, margins filled with background color
- (VIPSImage *)createImageWithMarginsWidth:(NSInteger)width
                                    height:(NSInteger)height
                                marginSize:(NSInteger)margin
                             contentColorR:(uint8_t)contentR
                             contentColorG:(uint8_t)contentG
                             contentColorB:(uint8_t)contentB
                          backgroundColorR:(uint8_t)bgR
                          backgroundColorG:(uint8_t)bgG
                          backgroundColorB:(uint8_t)bgB;

/// Create a horizontal gradient image (left to right: startColor to endColor)
- (VIPSImage *)createHorizontalGradientWidth:(NSInteger)width
                                      height:(NSInteger)height
                                 startColorR:(uint8_t)startR
                                 startColorG:(uint8_t)startG
                                 startColorB:(uint8_t)startB
                                   endColorR:(uint8_t)endR
                                   endColorG:(uint8_t)endG
                                   endColorB:(uint8_t)endB;

@end

NS_ASSUME_NONNULL_END
