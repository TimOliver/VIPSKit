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

@end

NS_ASSUME_NONNULL_END
