//
//  VIPSImageCGImageTests.m
//  VIPSKitTests
//
//  Tests for VIPSImage+CGImage: CoreGraphics integration methods
//

#import "VIPSImageTestCase.h"

@interface VIPSImageCGImageTests : VIPSImageTestCase
@end

@implementation VIPSImageCGImageTests

#pragma mark - Basic CGImage Tests

- (void)testCreateCGImage {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    CGImageRef cgImage = [image createCGImageWithError:&error];

    XCTAssertTrue(cgImage != NULL, @"Should create CGImage");
    XCTAssertNil(error, @"Should not have error: %@", error);
    XCTAssertEqual(CGImageGetWidth(cgImage), 100, @"CGImage width should match");
    XCTAssertEqual(CGImageGetHeight(cgImage), 100, @"CGImage height should match");

    if (cgImage) {
        CGImageRelease(cgImage);
    }
}

- (void)testCreateCGImageWithAlpha {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100 bands:4];

    NSError *error = nil;
    CGImageRef cgImage = [image createCGImageWithError:&error];

    XCTAssertTrue(cgImage != NULL, @"Should create CGImage from RGBA");
    XCTAssertNil(error, @"Should not have error: %@", error);

    if (cgImage) {
        // Check that it has alpha
        CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(cgImage);
        XCTAssertNotEqual(alphaInfo, kCGImageAlphaNone, @"Should have alpha channel");
        CGImageRelease(cgImage);
    }
}

- (void)testCreateCGImageGrayscale {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    VIPSImage *gray = [image grayscaleWithError:&error];
    XCTAssertNotNil(gray, @"Should convert to grayscale");

    CGImageRef cgImage = [gray createCGImageWithError:&error];
    XCTAssertTrue(cgImage != NULL, @"Should create CGImage from grayscale");
    XCTAssertNil(error, @"Should not have error: %@", error);

    if (cgImage) {
        CGImageRelease(cgImage);
    }
}

#pragma mark - Thumbnail CGImage Tests

- (void)testCreateThumbnailCGImageFromLargeFile {
    // Test direct decode to thumbnail CGImage
    NSString *path = [self pathForTestResource:@"superman.jpg"];
    if (!path) {
        XCTSkip(@"superman.jpg not found in test resources");
        return;
    }

    NSError *error = nil;
    CGImageRef cgImage = [VIPSImage createThumbnailFromFile:path width:200 height:200 error:&error];

    XCTAssertTrue(cgImage != NULL, @"Should create thumbnail CGImage: %@", error);
    XCTAssertNil(error, @"Should not have error");

    if (cgImage) {
        NSInteger width = CGImageGetWidth(cgImage);
        NSInteger height = CGImageGetHeight(cgImage);

        XCTAssertLessThanOrEqual(width, 200, @"Width should fit within bounds");
        XCTAssertLessThanOrEqual(height, 200, @"Height should fit within bounds");

        CGImageRelease(cgImage);
    }
}

- (void)testCreateThumbnailCGImageSmall {
    NSString *path = [self pathForTestResource:@"superman.jpg"];
    if (!path) {
        XCTSkip(@"superman.jpg not found in test resources");
        return;
    }

    NSError *error = nil;
    CGImageRef cgImage = [VIPSImage createThumbnailFromFile:path width:50 height:50 error:&error];

    XCTAssertTrue(cgImage != NULL, @"Should create small thumbnail CGImage");

    if (cgImage) {
        XCTAssertLessThanOrEqual((NSInteger)CGImageGetWidth(cgImage), 50, @"Width should fit");
        XCTAssertLessThanOrEqual((NSInteger)CGImageGetHeight(cgImage), 50, @"Height should fit");
        CGImageRelease(cgImage);
    }
}

#pragma mark - Color Space Tests

- (void)testCreateCGImageWithColorSpace {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef cgImage = [image createCGImageWithColorSpace:colorSpace error:&error];

    XCTAssertTrue(cgImage != NULL, @"Should create CGImage with custom color space");
    XCTAssertNil(error, @"Should not have error: %@", error);

    CGColorSpaceRelease(colorSpace);
    if (cgImage) {
        CGImageRelease(cgImage);
    }
}

#pragma mark - Edge Cases

- (void)testCreateCGImageFromProcessedImage {
    VIPSImage *image = [self createTestImageWithWidth:200 height:200];
    NSError *error = nil;

    // Apply some processing
    VIPSImage *processed = [image resizeWithScale:0.5 error:&error];
    XCTAssertNotNil(processed, @"Should resize");

    processed = [processed adjustContrast:1.2 error:&error];
    XCTAssertNotNil(processed, @"Should adjust contrast");

    // Create CGImage from processed result
    CGImageRef cgImage = [processed createCGImageWithError:&error];
    XCTAssertTrue(cgImage != NULL, @"Should create CGImage from processed image");
    XCTAssertEqual(CGImageGetWidth(cgImage), 100, @"Width should match processed size");

    if (cgImage) {
        CGImageRelease(cgImage);
    }
}

- (void)testCreateCGImageFromEdgeDetection {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];
    NSError *error = nil;

    // Test with Sobel (single-band output)
    VIPSImage *sobel = [image sobelWithError:&error];
    XCTAssertNotNil(sobel, @"Should apply Sobel");

    CGImageRef sobelCG = [sobel createCGImageWithError:&error];
    XCTAssertTrue(sobelCG != NULL, @"Should create CGImage from Sobel: %@", error);
    if (sobelCG) CGImageRelease(sobelCG);

    // Test with Canny (single-band output)
    VIPSImage *canny = [image cannyWithSigma:1.4 error:&error];
    XCTAssertNotNil(canny, @"Should apply Canny");

    CGImageRef cannyCG = [canny createCGImageWithError:&error];
    XCTAssertTrue(cannyCG != NULL, @"Should create CGImage from Canny: %@", error);
    if (cannyCG) CGImageRelease(cannyCG);
}

@end
