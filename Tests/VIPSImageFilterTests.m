//
//  VIPSImageFilterTests.m
//  VIPSKitTests
//
//  Tests for VIPSImage+Filter: blur, sharpen, and edge detection methods
//

#import "VIPSImageTestCase.h"

@interface VIPSImageFilterTests : VIPSImageTestCase
@end

@implementation VIPSImageFilterTests

#pragma mark - Blur Tests

- (void)testBlur {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    VIPSImage *blurred = [image blurWithSigma:2.0 error:&error];

    XCTAssertNotNil(blurred, @"Should blur image");
    XCTAssertNil(error, @"Should not have error: %@", error);
    XCTAssertEqual(blurred.width, image.width, @"Dimensions should not change");
}

- (void)testBlurRange {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];
    NSError *error = nil;

    // Light blur
    VIPSImage *lightBlur = [image blurWithSigma:0.5 error:&error];
    XCTAssertNotNil(lightBlur, @"Should apply light blur");

    // Heavy blur
    VIPSImage *heavyBlur = [image blurWithSigma:5.0 error:&error];
    XCTAssertNotNil(heavyBlur, @"Should apply heavy blur");
}

#pragma mark - Sharpen Tests

- (void)testSharpen {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    VIPSImage *sharpened = [image sharpenWithSigma:1.0 error:&error];

    XCTAssertNotNil(sharpened, @"Should sharpen image");
    XCTAssertNil(error, @"Should not have error: %@", error);
}

- (void)testSharpenRange {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];
    NSError *error = nil;

    // Light sharpen
    VIPSImage *lightSharpen = [image sharpenWithSigma:0.5 error:&error];
    XCTAssertNotNil(lightSharpen, @"Should apply light sharpen");

    // Strong sharpen
    VIPSImage *strongSharpen = [image sharpenWithSigma:2.0 error:&error];
    XCTAssertNotNil(strongSharpen, @"Should apply strong sharpen");
}

#pragma mark - Sobel Edge Detection Tests

- (void)testSobel {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    VIPSImage *edges = [image sobelWithError:&error];

    XCTAssertNotNil(edges, @"Should detect edges with Sobel");
    XCTAssertNil(error, @"Should not have error: %@", error);
}

- (void)testSobelCGImage {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    VIPSImage *edges = [image sobelWithError:&error];
    XCTAssertNotNil(edges, @"Should detect edges with Sobel");

    // Should be able to create CGImage from Sobel result
    CGImageRef cgImage = [edges createCGImageWithError:&error];
    XCTAssertNotNil((__bridge id)cgImage, @"Should create CGImage from Sobel result: %@", error);

    if (cgImage) {
        CGImageRelease(cgImage);
    }
}

#pragma mark - Canny Edge Detection Tests

- (void)testCanny {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    VIPSImage *edges = [image cannyWithSigma:1.4 error:&error];

    XCTAssertNotNil(edges, @"Should detect edges with Canny");
    XCTAssertNil(error, @"Should not have error: %@", error);
}

- (void)testCannySigmaRange {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];
    NSError *error = nil;

    // Low sigma (more noise)
    VIPSImage *lowSigma = [image cannyWithSigma:0.5 error:&error];
    XCTAssertNotNil(lowSigma, @"Should work with low sigma");

    // High sigma (smoother)
    VIPSImage *highSigma = [image cannyWithSigma:3.0 error:&error];
    XCTAssertNotNil(highSigma, @"Should work with high sigma");
}

- (void)testCannyCGImage {
    // Test creating CGImage from Canny edge detection result
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    VIPSImage *edges = [image cannyWithSigma:1.4 error:&error];
    XCTAssertNotNil(edges, @"Should detect edges with Canny");
    XCTAssertNil(error, @"Should not have error: %@", error);

    // Create CGImage from Canny result
    error = nil;
    CGImageRef cgImage = [edges createCGImageWithError:&error];
    XCTAssertNotNil((__bridge id)cgImage, @"Should create CGImage from Canny result, error: %@", error);

    if (cgImage) {
        CGImageRelease(cgImage);
    }
}

- (void)testCannyCGImageFromThumbnail {
    // Test creating CGImage from Canny of a thumbnail
    NSString *path = [self pathForTestResource:@"superman.jpg"];
    if (!path) {
        XCTSkip(@"superman.jpg not found in test resources");
        return;
    }

    NSError *error = nil;
    VIPSImage *thumbnail = [VIPSImage thumbnailFromFile:path width:200 height:200 error:&error];
    XCTAssertNotNil(thumbnail, @"Should create thumbnail");
    XCTAssertNil(error, @"Should not have error: %@", error);

    // Run Canny on thumbnail
    error = nil;
    VIPSImage *edges = [thumbnail cannyWithSigma:1.4 error:&error];
    XCTAssertNotNil(edges, @"Should detect edges with Canny");
    XCTAssertNil(error, @"Canny error: %@", error);

    // Create CGImage from Canny result
    error = nil;
    CGImageRef cgImage = [edges createCGImageWithError:&error];
    XCTAssertNotNil((__bridge id)cgImage, @"Should create CGImage from Canny result, error: %@", error);

    if (cgImage) {
        CGImageRelease(cgImage);
    }
}

#pragma mark - Filter Chain Tests

- (void)testFilterChain {
    VIPSImage *image = [self createTestImageWithWidth:200 height:200];
    NSError *error = nil;

    // Apply blur then sharpen
    VIPSImage *blurred = [image blurWithSigma:1.0 error:&error];
    XCTAssertNotNil(blurred, @"Should blur");

    VIPSImage *sharpened = [blurred sharpenWithSigma:1.0 error:&error];
    XCTAssertNotNil(sharpened, @"Should sharpen after blur");

    // Export to verify pipeline
    NSData *data = [sharpened dataWithFormat:VIPSImageFormatJPEG quality:80 error:&error];
    XCTAssertNotNil(data, @"Should export filter chain result");
}

@end
