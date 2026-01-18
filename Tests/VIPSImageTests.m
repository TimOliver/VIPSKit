//
//  VIPSImageTests.m
//  VIPSKitTests
//
//  Unit tests for VIPSKit
//

#import <XCTest/XCTest.h>
#import "VIPSImage.h"

@interface VIPSImageTests : XCTestCase
@end

@implementation VIPSImageTests

static BOOL sVIPSInitialized = NO;

- (void)setUp {
    [super setUp];
    if (!sVIPSInitialized) {
        NSError *error = nil;
        BOOL success = [VIPSImage initializeWithError:&error];
        XCTAssertTrue(success, @"Failed to initialize VIPSKit: %@", error);
        sVIPSInitialized = success;
    }
    XCTAssertTrue(sVIPSInitialized, @"VIPSKit not initialized");
}

#pragma mark - Initialization Tests

- (void)testInitialization {
    XCTAssertTrue(sVIPSInitialized, @"VIPSKit should be initialized");
}

#pragma mark - Image Creation Tests

- (void)testCreateImageFromBuffer {
    // Create a simple 100x100 RGB image buffer
    NSInteger width = 100;
    NSInteger height = 100;
    NSInteger bands = 3;
    NSMutableData *buffer = [NSMutableData dataWithLength:width * height * bands];

    // Fill with red pixels
    unsigned char *bytes = (unsigned char *)buffer.mutableBytes;
    for (NSInteger i = 0; i < width * height; i++) {
        bytes[i * 3 + 0] = 255;  // R
        bytes[i * 3 + 1] = 0;    // G
        bytes[i * 3 + 2] = 0;    // B
    }

    NSError *error = nil;
    VIPSImage *image = [VIPSImage imageWithBuffer:buffer.bytes width:width height:height bands:bands error:&error];

    XCTAssertNotNil(image, @"Should create image from buffer");
    XCTAssertNil(error, @"Should not have error: %@", error);
    XCTAssertEqual(image.width, width, @"Width should match");
    XCTAssertEqual(image.height, height, @"Height should match");
    XCTAssertEqual(image.bands, bands, @"Bands should match");
    XCTAssertFalse(image.hasAlpha, @"RGB image should not have alpha");
}

- (void)testCreateImageFromBufferWithAlpha {
    NSInteger width = 50;
    NSInteger height = 50;
    NSInteger bands = 4;
    NSMutableData *buffer = [NSMutableData dataWithLength:width * height * bands];

    // Fill with semi-transparent blue pixels
    unsigned char *bytes = (unsigned char *)buffer.mutableBytes;
    for (NSInteger i = 0; i < width * height; i++) {
        bytes[i * 4 + 0] = 0;    // R
        bytes[i * 4 + 1] = 0;    // G
        bytes[i * 4 + 2] = 255;  // B
        bytes[i * 4 + 3] = 128;  // A
    }

    NSError *error = nil;
    VIPSImage *image = [VIPSImage imageWithBuffer:buffer.bytes width:width height:height bands:bands error:&error];

    XCTAssertNotNil(image, @"Should create RGBA image from buffer");
    XCTAssertNil(error, @"Should not have error");
    XCTAssertEqual(image.bands, 4, @"Should have 4 bands");
    XCTAssertTrue(image.hasAlpha, @"RGBA image should have alpha");
}

#pragma mark - Transform Tests

- (void)testResize {
    VIPSImage *image = [self createTestImageWithWidth:200 height:200];
    XCTAssertNotNil(image, @"Should create test image");

    NSError *error = nil;
    VIPSImage *resized = [image resizeWithScale:0.5 error:&error];

    XCTAssertNotNil(resized, @"Should resize image");
    XCTAssertNil(error, @"Should not have error: %@", error);
    XCTAssertEqual(resized.width, 100, @"Width should be halved");
    XCTAssertEqual(resized.height, 100, @"Height should be halved");
}

- (void)testResizeToExactDimensions {
    VIPSImage *image = [self createTestImageWithWidth:200 height:100];

    NSError *error = nil;
    VIPSImage *resized = [image resizeToWidth:50 height:25 error:&error];

    XCTAssertNotNil(resized, @"Should resize to exact dimensions");
    XCTAssertEqual(resized.width, 50, @"Width should match target");
    XCTAssertEqual(resized.height, 25, @"Height should match target");
}

- (void)testCrop {
    VIPSImage *image = [self createTestImageWithWidth:200 height:200];

    NSError *error = nil;
    VIPSImage *cropped = [image cropWithX:50 y:50 width:100 height:100 error:&error];

    XCTAssertNotNil(cropped, @"Should crop image");
    XCTAssertNil(error, @"Should not have error: %@", error);
    XCTAssertEqual(cropped.width, 100, @"Cropped width should match");
    XCTAssertEqual(cropped.height, 100, @"Cropped height should match");
}

- (void)testRotate90 {
    VIPSImage *image = [self createTestImageWithWidth:200 height:100];

    NSError *error = nil;
    VIPSImage *rotated = [image rotateByDegrees:90 error:&error];

    XCTAssertNotNil(rotated, @"Should rotate image");
    XCTAssertNil(error, @"Should not have error: %@", error);
    XCTAssertEqual(rotated.width, 100, @"Width and height should swap");
    XCTAssertEqual(rotated.height, 200, @"Width and height should swap");
}

- (void)testRotate180 {
    VIPSImage *image = [self createTestImageWithWidth:200 height:100];

    NSError *error = nil;
    VIPSImage *rotated = [image rotateByDegrees:180 error:&error];

    XCTAssertNotNil(rotated, @"Should rotate image");
    XCTAssertEqual(rotated.width, 200, @"Width should stay same");
    XCTAssertEqual(rotated.height, 100, @"Height should stay same");
}

- (void)testFlipHorizontal {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    VIPSImage *flipped = [image flipHorizontalWithError:&error];

    XCTAssertNotNil(flipped, @"Should flip image");
    XCTAssertNil(error, @"Should not have error: %@", error);
    XCTAssertEqual(flipped.width, image.width, @"Dimensions should not change");
    XCTAssertEqual(flipped.height, image.height, @"Dimensions should not change");
}

- (void)testFlipVertical {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    VIPSImage *flipped = [image flipVerticalWithError:&error];

    XCTAssertNotNil(flipped, @"Should flip image");
    XCTAssertNil(error, @"Should not have error: %@", error);
}

- (void)testSmartCrop {
    VIPSImage *image = [self createTestImageWithWidth:400 height:300];

    NSError *error = nil;
    VIPSImage *cropped = [image smartCropToWidth:200 height:200 interesting:VIPSInterestingAttention error:&error];

    XCTAssertNotNil(cropped, @"Should smart crop image");
    XCTAssertNil(error, @"Should not have error: %@", error);
    XCTAssertEqual(cropped.width, 200, @"Should match target width");
    XCTAssertEqual(cropped.height, 200, @"Should match target height");
}

#pragma mark - Color Tests

- (void)testGrayscale {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    VIPSImage *gray = [image grayscaleWithError:&error];

    XCTAssertNotNil(gray, @"Should convert to grayscale");
    XCTAssertNil(error, @"Should not have error: %@", error);
    XCTAssertEqual(gray.bands, 1, @"Grayscale should have 1 band");
}

- (void)testInvert {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    VIPSImage *inverted = [image invertWithError:&error];

    XCTAssertNotNil(inverted, @"Should invert image");
    XCTAssertNil(error, @"Should not have error: %@", error);
}

- (void)testBrightnessAdjustment {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    VIPSImage *brightened = [image adjustBrightness:0.2 error:&error];

    XCTAssertNotNil(brightened, @"Should adjust brightness");
    XCTAssertNil(error, @"Should not have error: %@", error);
}

- (void)testContrastAdjustment {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    VIPSImage *contrasted = [image adjustContrast:1.5 error:&error];

    XCTAssertNotNil(contrasted, @"Should adjust contrast");
    XCTAssertNil(error, @"Should not have error: %@", error);
}

- (void)testSaturationAdjustment {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    VIPSImage *saturated = [image adjustSaturation:1.5 error:&error];

    XCTAssertNotNil(saturated, @"Should adjust saturation");
    XCTAssertNil(error, @"Should not have error: %@", error);
}

- (void)testGammaAdjustment {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    VIPSImage *gammaCorrected = [image adjustGamma:2.2 error:&error];

    XCTAssertNotNil(gammaCorrected, @"Should adjust gamma");
    XCTAssertNil(error, @"Should not have error: %@", error);
}

#pragma mark - Filter Tests

- (void)testBlur {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    VIPSImage *blurred = [image blurWithSigma:2.0 error:&error];

    XCTAssertNotNil(blurred, @"Should blur image");
    XCTAssertNil(error, @"Should not have error: %@", error);
}

- (void)testSharpen {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    VIPSImage *sharpened = [image sharpenWithSigma:1.0 error:&error];

    XCTAssertNotNil(sharpened, @"Should sharpen image");
    XCTAssertNil(error, @"Should not have error: %@", error);
}

- (void)testSobel {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    VIPSImage *edges = [image sobelWithError:&error];

    XCTAssertNotNil(edges, @"Should detect edges with Sobel");
    XCTAssertNil(error, @"Should not have error: %@", error);
}

- (void)testCanny {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    VIPSImage *edges = [image cannyWithSigma:1.4 error:&error];

    XCTAssertNotNil(edges, @"Should detect edges with Canny");
    XCTAssertNil(error, @"Should not have error: %@", error);
}

#pragma mark - Composite Tests

- (void)testCompositeOver {
    VIPSImage *base = [self createTestImageWithWidth:100 height:100];
    VIPSImage *overlay = [self createTestImageWithWidth:50 height:50 bands:4];

    NSError *error = nil;
    VIPSImage *composited = [base compositeWithOverlay:overlay mode:VIPSBlendModeOver x:25 y:25 error:&error];

    XCTAssertNotNil(composited, @"Should composite images");
    XCTAssertNil(error, @"Should not have error: %@", error);
    XCTAssertEqual(composited.width, base.width, @"Should maintain base dimensions");
    XCTAssertEqual(composited.height, base.height, @"Should maintain base dimensions");
}

#pragma mark - Export Tests

- (void)testExportToJPEG {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    NSData *jpegData = [image dataWithFormat:VIPSImageFormatJPEG quality:85 error:&error];

    XCTAssertNotNil(jpegData, @"Should export to JPEG");
    XCTAssertNil(error, @"Should not have error: %@", error);
    XCTAssertGreaterThan(jpegData.length, 0, @"JPEG data should not be empty");

    // Check JPEG magic bytes
    const unsigned char *bytes = (const unsigned char *)jpegData.bytes;
    XCTAssertEqual(bytes[0], 0xFF, @"Should have JPEG magic byte 1");
    XCTAssertEqual(bytes[1], 0xD8, @"Should have JPEG magic byte 2");
}

- (void)testExportToPNG {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    NSData *pngData = [image dataWithFormat:VIPSImageFormatPNG quality:0 error:&error];

    XCTAssertNotNil(pngData, @"Should export to PNG");
    XCTAssertNil(error, @"Should not have error: %@", error);

    // Check PNG magic bytes
    const unsigned char *bytes = (const unsigned char *)pngData.bytes;
    XCTAssertEqual(bytes[0], 0x89, @"Should have PNG magic byte 1");
    XCTAssertEqual(bytes[1], 'P', @"Should have PNG magic byte 2");
    XCTAssertEqual(bytes[2], 'N', @"Should have PNG magic byte 3");
    XCTAssertEqual(bytes[3], 'G', @"Should have PNG magic byte 4");
}

- (void)testExportToWebP {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    NSData *webpData = [image dataWithFormat:VIPSImageFormatWebP quality:80 error:&error];

    XCTAssertNotNil(webpData, @"Should export to WebP");
    XCTAssertNil(error, @"Should not have error: %@", error);

    // Check WebP magic bytes (RIFF....WEBP)
    const unsigned char *bytes = (const unsigned char *)webpData.bytes;
    XCTAssertEqual(bytes[0], 'R', @"Should have RIFF header");
    XCTAssertEqual(bytes[1], 'I', @"Should have RIFF header");
    XCTAssertEqual(bytes[2], 'F', @"Should have RIFF header");
    XCTAssertEqual(bytes[3], 'F', @"Should have RIFF header");
}

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

#pragma mark - Memory Management Tests

- (void)testCopyToMemory {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    VIPSImage *copied = [image copyToMemoryWithError:&error];

    XCTAssertNotNil(copied, @"Should copy to memory");
    XCTAssertNil(error, @"Should not have error: %@", error);
    XCTAssertEqual(copied.width, image.width, @"Dimensions should match");
    XCTAssertEqual(copied.height, image.height, @"Dimensions should match");
}

#pragma mark - Concurrency Tests

- (void)testConcurrentImageProcessing {
    // Test that multiple images can be processed concurrently without crashes
    // libvips uses mutexes to protect shared state (cache, etc.)

    NSInteger iterations = 20;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Concurrent processing"];
    expectation.expectedFulfillmentCount = iterations;

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    for (NSInteger i = 0; i < iterations; i++) {
        dispatch_async(queue, ^{
            @autoreleasepool {
                // Each iteration creates its own image and processes it
                NSInteger size = 100 + (i % 50);  // Vary sizes
                VIPSImage *image = [self createTestImageWithWidth:size height:size];
                XCTAssertNotNil(image);

                NSError *error = nil;

                // Chain multiple operations
                VIPSImage *result = [image resizeWithScale:0.5 error:&error];
                XCTAssertNotNil(result, @"Resize failed: %@", error);

                result = [result adjustContrast:1.2 error:&error];
                XCTAssertNotNil(result, @"Contrast failed: %@", error);

                result = [result blurWithSigma:1.0 error:&error];
                XCTAssertNotNil(result, @"Blur failed: %@", error);

                // Export to verify the pipeline completed
                NSData *data = [result dataWithFormat:VIPSImageFormatJPEG quality:80 error:&error];
                XCTAssertNotNil(data, @"Export failed: %@", error);
                XCTAssertGreaterThan(data.length, 0);

                [expectation fulfill];
            }
        });
    }

    [self waitForExpectationsWithTimeout:30.0 handler:nil];
}

#pragma mark - Large Image Tests

- (void)testLoadLargeImage {
    NSString *path = [self pathForTestResource:@"superman.jpg"];
    if (!path) {
        XCTSkip(@"superman.jpg not found in test resources");
        return;
    }

    NSError *error = nil;
    VIPSImage *image = [VIPSImage imageWithContentsOfFile:path error:&error];

    XCTAssertNotNil(image, @"Should load large image: %@", error);
    XCTAssertNil(error, @"Should not have error");
    XCTAssertGreaterThan(image.width, 0, @"Should have valid width");
    XCTAssertGreaterThan(image.height, 0, @"Should have valid height");

    NSLog(@"Large image dimensions: %ldx%ld", (long)image.width, (long)image.height);
}

- (void)testLargeImageInfo {
    NSString *path = [self pathForTestResource:@"superman.jpg"];
    if (!path) {
        XCTSkip(@"superman.jpg not found in test resources");
        return;
    }

    NSInteger width = 0, height = 0;
    VIPSImageFormat format = VIPSImageFormatUnknown;
    NSError *error = nil;

    // getImageInfo should be fast and memory-efficient (reads header only)
    BOOL success = [VIPSImage getImageInfoAtPath:path width:&width height:&height format:&format error:&error];

    XCTAssertTrue(success, @"Should get image info: %@", error);
    XCTAssertGreaterThan(width, 0, @"Should have valid width");
    XCTAssertGreaterThan(height, 0, @"Should have valid height");
    XCTAssertEqual(format, VIPSImageFormatJPEG, @"Should detect JPEG format");

    NSLog(@"Image info: %ldx%ld, format=%ld", (long)width, (long)height, (long)format);
}

- (void)testThumbnailFromLargeFile {
    // Tests shrink-on-load thumbnailing - most memory-efficient method
    NSString *path = [self pathForTestResource:@"superman.jpg"];
    if (!path) {
        XCTSkip(@"superman.jpg not found in test resources");
        return;
    }

    NSError *error = nil;
    VIPSImage *thumbnail = [VIPSImage thumbnailFromFile:path width:200 height:200 error:&error];

    XCTAssertNotNil(thumbnail, @"Should create thumbnail: %@", error);
    XCTAssertNil(error, @"Should not have error");

    // Thumbnail should be smaller than or equal to requested size
    XCTAssertLessThanOrEqual(thumbnail.width, 200, @"Width should fit within bounds");
    XCTAssertLessThanOrEqual(thumbnail.height, 200, @"Height should fit within bounds");

    // At least one dimension should be at target (aspect ratio preserved)
    BOOL widthAtTarget = (thumbnail.width == 200);
    BOOL heightAtTarget = (thumbnail.height == 200);
    XCTAssertTrue(widthAtTarget || heightAtTarget, @"At least one dimension should be at target");
}

- (void)testThumbnailingMethods {
    // Verify both thumbnailing approaches work and produce consistent results
    NSString *path = [self pathForTestResource:@"superman.jpg"];
    if (!path) {
        XCTSkip(@"superman.jpg not found in test resources");
        return;
    }

    NSError *error = nil;

    // Method 1: Shrink-on-load (recommended for memory efficiency)
    VIPSImage *thumb1 = [VIPSImage thumbnailFromFile:path width:200 height:200 error:&error];
    XCTAssertNotNil(thumb1, @"Shrink-on-load failed: %@", error);

    // Method 2: Full load then resize
    VIPSImage *fullImage = [VIPSImage imageWithContentsOfFile:path error:&error];
    XCTAssertNotNil(fullImage, @"Full load failed: %@", error);

    VIPSImage *thumb2 = [fullImage resizeToFitWidth:200 height:200 error:&error];
    XCTAssertNotNil(thumb2, @"Resize failed: %@", error);

    // Both should produce consistent dimensions
    XCTAssertEqual(thumb1.width, thumb2.width, @"Both methods should produce same width");
    XCTAssertEqual(thumb1.height, thumb2.height, @"Both methods should produce same height");
}

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

    // Apply a chain of operations
    VIPSImage *result = [image adjustContrast:1.1 error:&error];
    XCTAssertNotNil(result, @"Contrast failed: %@", error);

    result = [result adjustSaturation:1.2 error:&error];
    XCTAssertNotNil(result, @"Saturation failed: %@", error);

    result = [result sharpenWithSigma:0.5 error:&error];
    XCTAssertNotNil(result, @"Sharpen failed: %@", error);

    // Export to JPEG
    NSData *jpegData = [result dataWithFormat:VIPSImageFormatJPEG quality:85 error:&error];
    XCTAssertNotNil(jpegData, @"Export failed: %@", error);
    XCTAssertGreaterThan(jpegData.length, 0, @"Should have data");
}

#pragma mark - Helper Methods

- (NSString *)pathForTestResource:(NSString *)filename {
    // Try bundle resource path first (for running in Xcode)
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *path = [bundle pathForResource:[filename stringByDeletingPathExtension]
                                      ofType:[filename pathExtension]];
    if (path) {
        return path;
    }

    // Fallback to hardcoded path for command-line testing
    NSString *testResourcesPath = @"/Users/TiM/Developer/VIPSKit/Tests/TestResources";
    path = [testResourcesPath stringByAppendingPathComponent:filename];

    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return path;
    }

    return nil;
}

- (VIPSImage *)createTestImageWithWidth:(NSInteger)width height:(NSInteger)height {
    return [self createTestImageWithWidth:width height:height bands:3];
}

- (VIPSImage *)createTestImageWithWidth:(NSInteger)width height:(NSInteger)height bands:(NSInteger)bands {
    NSMutableData *buffer = [NSMutableData dataWithLength:width * height * bands];

    // Fill with gradient
    unsigned char *bytes = (unsigned char *)buffer.mutableBytes;
    for (NSInteger y = 0; y < height; y++) {
        for (NSInteger x = 0; x < width; x++) {
            NSInteger idx = (y * width + x) * bands;
            bytes[idx + 0] = (unsigned char)(x * 255 / width);     // R
            if (bands >= 2) bytes[idx + 1] = (unsigned char)(y * 255 / height);    // G
            if (bands >= 3) bytes[idx + 2] = 128;                  // B
            if (bands >= 4) bytes[idx + 3] = 200;                  // A
        }
    }

    NSError *error = nil;
    VIPSImage *image = [VIPSImage imageWithBuffer:buffer.bytes width:width height:height bands:bands error:&error];
    XCTAssertNotNil(image, @"Failed to create test image: %@", error);
    return image;
}

@end
