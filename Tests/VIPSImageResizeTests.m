//
//  VIPSImageResizeTests.m
//  VIPSKitTests
//
//  Tests for VIPSImage+Resize: image resizing and scaling methods
//

#import "VIPSImageTestCase.h"

@interface VIPSImageResizeTests : VIPSImageTestCase
@end

@implementation VIPSImageResizeTests

#pragma mark - Scale Tests

- (void)testResizeByScale {
    VIPSImage *image = [self createTestImageWithWidth:200 height:200];
    XCTAssertNotNil(image, @"Should create test image");

    NSError *error = nil;
    VIPSImage *resized = [image resizeWithScale:0.5 error:&error];

    XCTAssertNotNil(resized, @"Should resize image");
    XCTAssertNil(error, @"Should not have error: %@", error);
    XCTAssertEqual(resized.width, 100, @"Width should be halved");
    XCTAssertEqual(resized.height, 100, @"Height should be halved");
}

- (void)testResizeByScaleUpscale {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    VIPSImage *resized = [image resizeWithScale:2.0 error:&error];

    XCTAssertNotNil(resized, @"Should upscale image");
    XCTAssertNil(error, @"Should not have error: %@", error);
    XCTAssertEqual(resized.width, 200, @"Width should be doubled");
    XCTAssertEqual(resized.height, 200, @"Height should be doubled");
}

- (void)testResizeWithKernels {
    VIPSImage *image = [self createTestImageWithWidth:200 height:200];
    NSError *error = nil;

    // Test different kernels
    VIPSResizeKernel kernels[] = {
        VIPSResizeKernelNearest,
        VIPSResizeKernelLinear,
        VIPSResizeKernelCubic,
        VIPSResizeKernelLanczos2,
        VIPSResizeKernelLanczos3
    };

    for (int i = 0; i < 5; i++) {
        VIPSImage *resized = [image resizeWithScale:0.5 kernel:kernels[i] error:&error];
        XCTAssertNotNil(resized, @"Should resize with kernel %d", i);
        XCTAssertEqual(resized.width, 100, @"Width should be halved with kernel %d", i);
    }
}

#pragma mark - Exact Dimension Tests

- (void)testResizeToExactDimensions {
    VIPSImage *image = [self createTestImageWithWidth:200 height:100];

    NSError *error = nil;
    VIPSImage *resized = [image resizeToWidth:50 height:25 error:&error];

    XCTAssertNotNil(resized, @"Should resize to exact dimensions");
    XCTAssertEqual(resized.width, 50, @"Width should match target");
    XCTAssertEqual(resized.height, 25, @"Height should match target");
}

- (void)testResizeToExactDimensionsNonProportional {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    VIPSImage *resized = [image resizeToWidth:200 height:50 error:&error];

    XCTAssertNotNil(resized, @"Should resize to non-proportional dimensions");
    XCTAssertEqual(resized.width, 200, @"Width should match target");
    XCTAssertEqual(resized.height, 50, @"Height should match target");
}

#pragma mark - Fit Tests

- (void)testResizeToFitLandscape {
    VIPSImage *image = [self createTestImageWithWidth:400 height:200];

    NSError *error = nil;
    VIPSImage *fitted = [image resizeToFitWidth:200 height:200 error:&error];

    XCTAssertNotNil(fitted, @"Should fit landscape image");
    XCTAssertNil(error, @"Should not have error: %@", error);
    XCTAssertEqual(fitted.width, 200, @"Width should be at target");
    XCTAssertEqual(fitted.height, 100, @"Height should maintain aspect ratio");
}

- (void)testResizeToFitPortrait {
    VIPSImage *image = [self createTestImageWithWidth:200 height:400];

    NSError *error = nil;
    VIPSImage *fitted = [image resizeToFitWidth:200 height:200 error:&error];

    XCTAssertNotNil(fitted, @"Should fit portrait image");
    XCTAssertEqual(fitted.width, 100, @"Width should maintain aspect ratio");
    XCTAssertEqual(fitted.height, 200, @"Height should be at target");
}

- (void)testResizeToFitSquare {
    VIPSImage *image = [self createTestImageWithWidth:400 height:400];

    NSError *error = nil;
    VIPSImage *fitted = [image resizeToFitWidth:200 height:200 error:&error];

    XCTAssertNotNil(fitted, @"Should fit square image");
    XCTAssertEqual(fitted.width, 200, @"Width should be at target");
    XCTAssertEqual(fitted.height, 200, @"Height should be at target");
}

- (void)testResizeToFitSmallerThanTarget {
    VIPSImage *image = [self createTestImageWithWidth:100 height:50];

    NSError *error = nil;
    VIPSImage *fitted = [image resizeToFitWidth:200 height:200 error:&error];

    XCTAssertNotNil(fitted, @"Should fit small image");
    // When using thumbnail, it may not upscale
    XCTAssertLessThanOrEqual(fitted.width, 200, @"Width should fit within bounds");
    XCTAssertLessThanOrEqual(fitted.height, 200, @"Height should fit within bounds");
}

#pragma mark - Large Image Tests

- (void)testLargeImageProcessingChain {
    // Test a chain of operations on a large image
    NSString *path = [self pathForTestResource:@"superman.jpg"];
    if (!path) {
        XCTSkip(@"superman.jpg not found in test resources");
        return;
    }

    NSError *error = nil;

    // Use shrink-on-load for initial load
    VIPSImage *image = [VIPSImage thumbnailFromFile:path width:800 height:800 error:&error];
    XCTAssertNotNil(image, @"Should load: %@", error);

    // Apply resize operations
    VIPSImage *result = [image resizeWithScale:0.5 error:&error];
    XCTAssertNotNil(result, @"Should resize: %@", error);
    XCTAssertLessThanOrEqual(result.width, 400, @"Should be smaller");

    result = [result resizeToFitWidth:100 height:100 error:&error];
    XCTAssertNotNil(result, @"Should fit: %@", error);
    XCTAssertLessThanOrEqual(result.width, 100, @"Should fit within bounds");
}

@end
