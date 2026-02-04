//
//  VIPSImageCachingTests.m
//  VIPSKitTests
//
//  Tests for VIPSImage+Caching: caching utilities with format control
//

#import "VIPSImageTestCase.h"

@interface VIPSImageCachingTests : VIPSImageTestCase
@end

@implementation VIPSImageCachingTests

#pragma mark - Default Cache Data Tests

- (void)testCacheDataDefault {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    NSData *cacheData = [image cacheDataWithError:&error];

    XCTAssertNotNil(cacheData, @"Should create cache data");
    XCTAssertNil(error, @"Should not have error: %@", error);
    XCTAssertGreaterThan(cacheData.length, 0, @"Cache data should not be empty");

    // Default is lossless WebP, check RIFF header
    const unsigned char *bytes = (const unsigned char *)cacheData.bytes;
    XCTAssertEqual(bytes[0], 'R', @"Should have RIFF header (WebP)");
    XCTAssertEqual(bytes[1], 'I', @"Should have RIFF header (WebP)");
    XCTAssertEqual(bytes[2], 'F', @"Should have RIFF header (WebP)");
    XCTAssertEqual(bytes[3], 'F', @"Should have RIFF header (WebP)");
}

#pragma mark - Format-Specific Cache Data Tests

- (void)testCacheDataWebPLossless {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    NSData *cacheData = [image cacheDataWithFormat:VIPSImageFormatWebP quality:0 lossless:YES error:&error];

    XCTAssertNotNil(cacheData, @"Should create lossless WebP cache data");
    XCTAssertNil(error, @"Should not have error: %@", error);

    // Check RIFF header
    const unsigned char *bytes = (const unsigned char *)cacheData.bytes;
    XCTAssertEqual(bytes[0], 'R', @"Should have RIFF header");
}

- (void)testCacheDataWebPLossy {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    NSData *lossyData = [image cacheDataWithFormat:VIPSImageFormatWebP quality:80 lossless:NO error:&error];

    XCTAssertNotNil(lossyData, @"Should create lossy WebP cache data");
    XCTAssertNil(error, @"Should not have error: %@", error);

    // Lossy should generally be smaller than lossless
    NSData *losslessData = [image cacheDataWithFormat:VIPSImageFormatWebP quality:0 lossless:YES error:&error];
    XCTAssertNotNil(losslessData, @"Should create lossless for comparison");
    // Note: This isn't always true for small test images, so just verify both work
}

- (void)testCacheDataPNG {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    NSData *cacheData = [image cacheDataWithFormat:VIPSImageFormatPNG quality:0 lossless:YES error:&error];

    XCTAssertNotNil(cacheData, @"Should create PNG cache data");
    XCTAssertNil(error, @"Should not have error: %@", error);

    // Check PNG header
    const unsigned char *bytes = (const unsigned char *)cacheData.bytes;
    XCTAssertEqual(bytes[0], 0x89, @"Should have PNG magic byte");
    XCTAssertEqual(bytes[1], 'P', @"Should have PNG magic byte");
}

- (void)testCacheDataJPEG {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    NSData *cacheData = [image cacheDataWithFormat:VIPSImageFormatJPEG quality:85 lossless:NO error:&error];

    XCTAssertNotNil(cacheData, @"Should create JPEG cache data");
    XCTAssertNil(error, @"Should not have error: %@", error);

    // Check JPEG header
    const unsigned char *bytes = (const unsigned char *)cacheData.bytes;
    XCTAssertEqual(bytes[0], 0xFF, @"Should have JPEG magic byte");
    XCTAssertEqual(bytes[1], 0xD8, @"Should have JPEG magic byte");
}

#pragma mark - Write to Cache File Tests

- (void)testWriteToCacheFileDefault {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"test_cache"];
    NSError *error = nil;

    BOOL success = [image writeToCacheFile:tempPath error:&error];

    XCTAssertTrue(success, @"Should write cache file: %@", error);
    XCTAssertNil(error, @"Should not have error");

    // Check file exists with .webp extension
    NSString *expectedPath = [tempPath stringByAppendingPathExtension:@"webp"];
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:expectedPath];
    XCTAssertTrue(exists, @"Cache file should exist with .webp extension");

    // Cleanup
    [[NSFileManager defaultManager] removeItemAtPath:expectedPath error:nil];
}

- (void)testWriteToCacheFileWithFormat {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"test_cache_png"];
    NSError *error = nil;

    BOOL success = [image writeToCacheFile:tempPath format:VIPSImageFormatPNG quality:0 lossless:YES error:&error];

    XCTAssertTrue(success, @"Should write PNG cache file: %@", error);

    // Check file exists with .png extension
    NSString *expectedPath = [tempPath stringByAppendingPathExtension:@"png"];
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:expectedPath];
    XCTAssertTrue(exists, @"Cache file should exist with .png extension");

    // Cleanup
    [[NSFileManager defaultManager] removeItemAtPath:expectedPath error:nil];
}

- (void)testWriteToCacheFileJXL {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"test_cache_jxl"];
    NSError *error = nil;

    BOOL success = [image writeToCacheFile:tempPath format:VIPSImageFormatJXL quality:0 lossless:YES error:&error];

    XCTAssertTrue(success, @"Should write JXL cache file: %@", error);

    // Check file exists with .jxl extension
    NSString *expectedPath = [tempPath stringByAppendingPathExtension:@"jxl"];
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:expectedPath];
    XCTAssertTrue(exists, @"Cache file should exist with .jxl extension");

    // Cleanup
    [[NSFileManager defaultManager] removeItemAtPath:expectedPath error:nil];
}

#pragma mark - Roundtrip Tests

- (void)testCacheRoundtrip {
    VIPSImage *original = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    NSData *cacheData = [original cacheDataWithError:&error];
    XCTAssertNotNil(cacheData, @"Should create cache data");

    VIPSImage *restored = [VIPSImage imageWithData:cacheData error:&error];
    XCTAssertNotNil(restored, @"Should restore from cache data");
    XCTAssertEqual(restored.width, original.width, @"Width should match");
    XCTAssertEqual(restored.height, original.height, @"Height should match");
}

- (void)testCacheRoundtripWithAlpha {
    VIPSImage *original = [self createTestImageWithWidth:100 height:100 bands:4];

    NSError *error = nil;
    // PNG preserves alpha
    NSData *cacheData = [original cacheDataWithFormat:VIPSImageFormatPNG quality:0 lossless:YES error:&error];
    XCTAssertNotNil(cacheData, @"Should create PNG cache data");

    VIPSImage *restored = [VIPSImage imageWithData:cacheData error:&error];
    XCTAssertNotNil(restored, @"Should restore from PNG cache data");
    XCTAssertTrue(restored.hasAlpha, @"Restored image should have alpha");
}

@end
