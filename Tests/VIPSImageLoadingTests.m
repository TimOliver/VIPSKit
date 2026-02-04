//
//  VIPSImageLoadingTests.m
//  VIPSKitTests
//
//  Tests for VIPSImage+Loading: image creation and loading methods
//

#import "VIPSImageTestCase.h"

@interface VIPSImageLoadingTests : VIPSImageTestCase
@end

@implementation VIPSImageLoadingTests

#pragma mark - Buffer Loading Tests

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

- (void)testCreateImageFromGrayscaleBuffer {
    NSInteger width = 100;
    NSInteger height = 100;
    NSInteger bands = 1;
    NSMutableData *buffer = [NSMutableData dataWithLength:width * height * bands];

    // Fill with gradient
    unsigned char *bytes = (unsigned char *)buffer.mutableBytes;
    for (NSInteger y = 0; y < height; y++) {
        for (NSInteger x = 0; x < width; x++) {
            bytes[y * width + x] = (unsigned char)(x * 255 / width);
        }
    }

    NSError *error = nil;
    VIPSImage *image = [VIPSImage imageWithBuffer:buffer.bytes width:width height:height bands:bands error:&error];

    XCTAssertNotNil(image, @"Should create grayscale image from buffer");
    XCTAssertNil(error, @"Should not have error");
    XCTAssertEqual(image.bands, 1, @"Should have 1 band");
    XCTAssertFalse(image.hasAlpha, @"Grayscale image should not have alpha");
}

#pragma mark - File Loading Tests

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
}

- (void)testLoadSequentialAccess {
    NSString *path = [self pathForTestResource:@"superman.jpg"];
    if (!path) {
        XCTSkip(@"superman.jpg not found in test resources");
        return;
    }

    NSError *error = nil;
    VIPSImage *image = [VIPSImage imageWithContentsOfFileSequential:path error:&error];

    XCTAssertNotNil(image, @"Should load image with sequential access: %@", error);
    XCTAssertNil(error, @"Should not have error");
    XCTAssertGreaterThan(image.width, 0, @"Should have valid width");
}

#pragma mark - Image Info Tests

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
}

#pragma mark - Thumbnail Loading Tests

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

- (void)testThumbnailFromData {
    NSString *path = [self pathForTestResource:@"superman.jpg"];
    if (!path) {
        XCTSkip(@"superman.jpg not found in test resources");
        return;
    }

    NSData *data = [NSData dataWithContentsOfFile:path];
    XCTAssertNotNil(data, @"Should load file data");

    NSError *error = nil;
    VIPSImage *thumbnail = [VIPSImage thumbnailFromData:data width:150 height:150 error:&error];

    XCTAssertNotNil(thumbnail, @"Should create thumbnail from data: %@", error);
    XCTAssertNil(error, @"Should not have error");
    XCTAssertLessThanOrEqual(thumbnail.width, 150, @"Width should fit within bounds");
    XCTAssertLessThanOrEqual(thumbnail.height, 150, @"Height should fit within bounds");
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

#pragma mark - Data Loading Tests

- (void)testLoadFromData {
    NSString *path = [self pathForTestResource:@"superman.jpg"];
    if (!path) {
        XCTSkip(@"superman.jpg not found in test resources");
        return;
    }

    NSData *data = [NSData dataWithContentsOfFile:path];
    XCTAssertNotNil(data, @"Should load file data");

    NSError *error = nil;
    VIPSImage *image = [VIPSImage imageWithData:data error:&error];

    XCTAssertNotNil(image, @"Should create image from data: %@", error);
    XCTAssertNil(error, @"Should not have error");
    XCTAssertGreaterThan(image.width, 0, @"Should have valid width");
}

@end
