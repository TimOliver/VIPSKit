//
//  VIPSImageSavingTests.m
//  VIPSKitTests
//
//  Tests for VIPSImage+Saving: file saving and data export methods
//

#import "VIPSImageTestCase.h"

@interface VIPSImageSavingTests : VIPSImageTestCase
@end

@implementation VIPSImageSavingTests

#pragma mark - JPEG Export Tests

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

- (void)testExportToJPEGQualityRange {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];
    NSError *error = nil;

    // Test low quality
    NSData *lowQuality = [image dataWithFormat:VIPSImageFormatJPEG quality:10 error:&error];
    XCTAssertNotNil(lowQuality, @"Should export low quality JPEG");

    // Test high quality
    NSData *highQuality = [image dataWithFormat:VIPSImageFormatJPEG quality:100 error:&error];
    XCTAssertNotNil(highQuality, @"Should export high quality JPEG");

    // High quality should generally be larger
    XCTAssertGreaterThan(highQuality.length, lowQuality.length, @"High quality should be larger");
}

#pragma mark - PNG Export Tests

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

- (void)testExportToPNGWithAlpha {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100 bands:4];

    NSError *error = nil;
    NSData *pngData = [image dataWithFormat:VIPSImageFormatPNG quality:0 error:&error];

    XCTAssertNotNil(pngData, @"Should export RGBA image to PNG");
    XCTAssertNil(error, @"Should not have error: %@", error);
}

#pragma mark - WebP Export Tests

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

#pragma mark - File Saving Tests

- (void)testWriteToFile {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"test_output.jpg"];
    NSError *error = nil;

    BOOL success = [image writeToFile:tempPath error:&error];

    XCTAssertTrue(success, @"Should write to file: %@", error);
    XCTAssertNil(error, @"Should not have error");

    // Verify file exists
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:tempPath];
    XCTAssertTrue(exists, @"File should exist");

    // Cleanup
    [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
}

- (void)testWriteToFileWithFormat {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"test_output.png"];
    NSError *error = nil;

    BOOL success = [image writeToFile:tempPath format:VIPSImageFormatPNG quality:0 error:&error];

    XCTAssertTrue(success, @"Should write PNG to file: %@", error);
    XCTAssertNil(error, @"Should not have error");

    // Verify file exists and has PNG magic bytes
    NSData *data = [NSData dataWithContentsOfFile:tempPath];
    XCTAssertNotNil(data, @"Should read file");

    const unsigned char *bytes = (const unsigned char *)data.bytes;
    XCTAssertEqual(bytes[0], 0x89, @"Should have PNG magic byte");

    // Cleanup
    [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
}

#pragma mark - Roundtrip Tests

- (void)testJPEGRoundtrip {
    VIPSImage *original = [self createTestImageWithWidth:100 height:100];

    // Export to JPEG
    NSError *error = nil;
    NSData *jpegData = [original dataWithFormat:VIPSImageFormatJPEG quality:95 error:&error];
    XCTAssertNotNil(jpegData, @"Should export to JPEG");

    // Load back
    VIPSImage *loaded = [VIPSImage imageWithData:jpegData error:&error];
    XCTAssertNotNil(loaded, @"Should load JPEG data");
    XCTAssertEqual(loaded.width, original.width, @"Width should match");
    XCTAssertEqual(loaded.height, original.height, @"Height should match");
}

- (void)testPNGRoundtrip {
    VIPSImage *original = [self createTestImageWithWidth:100 height:100 bands:4];

    // Export to PNG
    NSError *error = nil;
    NSData *pngData = [original dataWithFormat:VIPSImageFormatPNG quality:0 error:&error];
    XCTAssertNotNil(pngData, @"Should export to PNG");

    // Load back
    VIPSImage *loaded = [VIPSImage imageWithData:pngData error:&error];
    XCTAssertNotNil(loaded, @"Should load PNG data");
    XCTAssertEqual(loaded.width, original.width, @"Width should match");
    XCTAssertEqual(loaded.height, original.height, @"Height should match");
    XCTAssertEqual(loaded.bands, original.bands, @"Bands should match");
}

@end
