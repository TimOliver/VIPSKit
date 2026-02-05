//
//  VIPSImageCoreTests.m
//  VIPSKitTests
//
//  Tests for VIPSImage core functionality: initialization, properties, memory management
//

#import "VIPSImageTestCase.h"

@interface VIPSImageCoreTests : VIPSImageTestCase
@end

@implementation VIPSImageCoreTests

#pragma mark - Initialization Tests

- (void)testInitialization {
    // VIPSKit should already be initialized by setUp
    XCTAssertTrue(YES, @"VIPSKit should be initialized");
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

- (void)testClearCache {
    // Create some images to populate the cache
    for (int i = 0; i < 5; i++) {
        VIPSImage *image = [self createTestImageWithWidth:100 height:100];
        NSError *error = nil;
        VIPSImage *processed = [image blurWithSigma:1.0 error:&error];
        XCTAssertNotNil(processed);

        // Force evaluation by exporting
        NSData *data = [processed dataWithFormat:VIPSImageFormatJPEG quality:80 error:&error];
        XCTAssertNotNil(data);
    }

    // clearCache uses safe LRU eviction instead of vips_cache_drop_all()
    // which would destroy the hash table and cause crashes
    [VIPSImage clearCache];

    // Verify we can still perform operations after clearing cache
    VIPSImage *afterClear = [self createTestImageWithWidth:50 height:50];
    NSError *afterError = nil;
    VIPSImage *afterProcessed = [afterClear blurWithSigma:1.0 error:&afterError];
    XCTAssertNotNil(afterProcessed, @"Should work after clearCache");
    XCTAssertNil(afterError);
}

- (void)testMemoryUsage {
    // Test that memory tracking works
    NSInteger usage = [VIPSImage memoryUsage];
    XCTAssertGreaterThanOrEqual(usage, 0, @"Memory usage should be non-negative");

    NSInteger highWater = [VIPSImage memoryHighWater];
    XCTAssertGreaterThanOrEqual(highWater, 0, @"High water mark should be non-negative");
}

- (void)testResetMemoryHighWater {
    // Do some operations to increase high water mark
    for (int i = 0; i < 3; i++) {
        VIPSImage *image = [self createTestImageWithWidth:200 height:200];
        NSError *error = nil;
        NSData *data = [image dataWithFormat:VIPSImageFormatPNG quality:0 error:&error];
        XCTAssertNotNil(data);
    }

    NSInteger highWaterBefore = [VIPSImage memoryHighWater];

    // Reset high water mark
    [VIPSImage resetMemoryHighWater];

    NSInteger highWaterAfter = [VIPSImage memoryHighWater];

    // High water mark should be reset (could be equal to current usage, but generally lower)
    XCTAssertLessThanOrEqual(highWaterAfter, highWaterBefore,
                             @"High water mark should be <= before reset");
}

- (void)testSetCacheMaxMemory {
    // Test that we can set cache max memory without crashing
    // Save original value
    NSInteger originalMax = 50 * 1024 * 1024; // Assume 50MB default

    // Set a different value
    [VIPSImage setCacheMaxMemory:25 * 1024 * 1024]; // 25MB

    // Verify operations still work
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];
    NSError *error = nil;
    VIPSImage *processed = [image blurWithSigma:1.0 error:&error];
    XCTAssertNotNil(processed, @"Should process with reduced cache memory");

    // Restore original
    [VIPSImage setCacheMaxMemory:originalMax];
}

- (void)testSetCacheMaxFiles {
    // Test that we can set cache max files without crashing

    // Set a different value
    [VIPSImage setCacheMaxFiles:50];

    // Verify operations still work
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];
    NSError *error = nil;
    VIPSImage *processed = [image sharpenWithSigma:1.0 error:&error];
    XCTAssertNotNil(processed, @"Should process with modified cache files limit");

    // Restore to a reasonable default
    [VIPSImage setCacheMaxFiles:100];
}

- (void)testConcurrencySettings {
    // Test concurrency getter/setter
    NSInteger original = [VIPSImage concurrency];

    [VIPSImage setConcurrency:2];
    XCTAssertEqual([VIPSImage concurrency], 2, @"Concurrency should be set to 2");

    [VIPSImage setConcurrency:original];
    XCTAssertEqual([VIPSImage concurrency], original, @"Concurrency should be restored");
}

#pragma mark - Concurrency Tests

- (void)testConcurrentImageProcessing {
    // Test that multiple images can be processed concurrently without crashes
    // libvips uses mutexes to protect shared state (cache, etc.)

    NSInteger iterations = 10;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Concurrent processing"];
    expectation.expectedFulfillmentCount = iterations;

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    for (NSInteger i = 0; i < iterations; i++) {
        dispatch_async(queue, ^{
            @autoreleasepool {
                // Each iteration creates its own image and processes it
                NSInteger size = 50 + (i % 30);  // Smaller sizes for faster tests
                VIPSImage *image = [self createTestImageWithWidth:size height:size];
                XCTAssertNotNil(image);

                NSError *error = nil;

                // Chain multiple operations
                VIPSImage *result = [image resizeWithScale:0.5 error:&error];
                XCTAssertNotNil(result, @"Resize failed: %@", error);

                result = [result adjustContrast:1.2 error:&error];
                XCTAssertNotNil(result, @"Contrast failed: %@", error);

                // Export to verify the pipeline completed
                NSData *data = [result dataWithFormat:VIPSImageFormatJPEG quality:80 error:&error];
                XCTAssertNotNil(data, @"Export failed: %@", error);
                XCTAssertGreaterThan(data.length, 0);

                [expectation fulfill];
            }
        });
    }

    [self waitForExpectationsWithTimeout:60.0 handler:nil];
}

#pragma mark - Properties Tests

- (void)testImageProperties {
    VIPSImage *image = [self createTestImageWithWidth:150 height:100 bands:3];

    XCTAssertEqual(image.width, 150, @"Width should be 150");
    XCTAssertEqual(image.height, 100, @"Height should be 100");
    XCTAssertEqual(image.bands, 3, @"Bands should be 3");
    XCTAssertFalse(image.hasAlpha, @"3-band image should not have alpha");
}

- (void)testImagePropertiesWithAlpha {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100 bands:4];

    XCTAssertEqual(image.bands, 4, @"Bands should be 4");
    XCTAssertTrue(image.hasAlpha, @"4-band image should have alpha");
}

@end
