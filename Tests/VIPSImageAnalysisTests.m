//
//  VIPSImageAnalysisTests.m
//  VIPSKitTests
//
//  Tests for VIPSImage analysis methods: findTrim, statistics, averageColor,
//  detectBackgroundColor, and arithmetic operations (subtract, absolute)
//

#import "VIPSImageTestCase.h"

@interface VIPSImageAnalysisTests : VIPSImageTestCase
@end

@implementation VIPSImageAnalysisTests

#pragma mark - Statistics Tests

- (void)testStatisticsSolidColor {
    // Create a solid gray image - all pixels are (128, 128, 128)
    VIPSImage *image = [self createSolidColorImageWithWidth:50 height:50 red:128 green:128 blue:128];

    NSError *error = nil;
    VIPSImageStatistics *stats = [image statisticsWithError:&error];

    XCTAssertNotNil(stats, @"Should get statistics: %@", error);
    XCTAssertNil(error);

    // For a solid color image, min == max == mean, stddev should be small
    XCTAssertEqualWithAccuracy(stats.min, stats.max, 1.0, @"Min and max should be equal for solid color");
    XCTAssertEqualWithAccuracy(stats.mean, stats.min, 1.0, @"Mean should equal min/max for solid color");
    XCTAssertLessThan(stats.standardDeviation, 5.0, @"StdDev should be near 0 for solid color");
}

- (void)testStatisticsGradient {
    // Create a gradient from black (0) to white (255)
    VIPSImage *image = [self createHorizontalGradientWidth:256 height:10
                                               startColorR:0 startColorG:0 startColorB:0
                                                 endColorR:255 endColorG:255 endColorB:255];

    NSError *error = nil;
    VIPSImageStatistics *stats = [image statisticsWithError:&error];

    XCTAssertNotNil(stats, @"Should get statistics: %@", error);

    // Gradient should have min near 0, max near 255
    XCTAssertLessThan(stats.min, 10.0, @"Min should be near 0");
    XCTAssertGreaterThan(stats.max, 245.0, @"Max should be near 255");
    XCTAssertGreaterThan(stats.standardDeviation, 50.0, @"StdDev should be significant for gradient");
}

#pragma mark - Average Color Tests

- (void)testAverageColorBasic {
    VIPSImage *image = [self createSolidColorImageWithWidth:50 height:50 red:128 green:128 blue:128];

    NSError *error = nil;
    NSArray<NSNumber *> *avgColor = [image averageColorWithError:&error];

    XCTAssertNotNil(avgColor, @"Should get average color: %@", error);
    XCTAssertNil(error, @"Should not have error");
    XCTAssertEqual(avgColor.count, 3, @"Should have 3 channels (RGB)");

    // All channels should return reasonable values
    for (NSNumber *val in avgColor) {
        XCTAssertGreaterThanOrEqual(val.doubleValue, 0.0, @"Value should be >= 0");
        XCTAssertLessThanOrEqual(val.doubleValue, 255.0, @"Value should be <= 255");
    }
}

- (void)testAverageColorWithAlpha {
    VIPSImage *image = [self createSolidColorImageWithWidth:50 height:50 red:200 green:100 blue:50 alpha:128];

    NSError *error = nil;
    NSArray<NSNumber *> *avgColor = [image averageColorWithError:&error];

    XCTAssertNotNil(avgColor, @"Should get average color: %@", error);
    XCTAssertEqual(avgColor.count, 4, @"Should have 4 channels (RGBA)");
}

- (void)testAverageColorGradient {
    // Gradient from red to blue
    VIPSImage *image = [self createHorizontalGradientWidth:100 height:50
                                               startColorR:255 startColorG:0 startColorB:0
                                                 endColorR:0 endColorG:0 endColorB:255];

    NSError *error = nil;
    NSArray<NSNumber *> *avgColor = [image averageColorWithError:&error];

    XCTAssertNotNil(avgColor, @"Should get average color: %@", error);
    XCTAssertEqual(avgColor.count, 3, @"Should have 3 channels");
}

#pragma mark - Detect Background Color Tests

- (void)testDetectBackgroundColorBasic {
    // Image with white margins around red content
    VIPSImage *image = [self createImageWithMarginsWidth:100 height:100 marginSize:20
                                           contentColorR:255 contentColorG:0 contentColorB:0
                                        backgroundColorR:255 backgroundColorG:255 backgroundColorB:255];

    NSError *error = nil;
    NSArray<NSNumber *> *bgColor = [image detectBackgroundColorWithError:&error];

    XCTAssertNotNil(bgColor, @"Should detect background color: %@", error);
    XCTAssertEqual(bgColor.count, 3, @"Should have 3 channels");
}

- (void)testDetectBackgroundColorBlackMargins {
    // Image with black margins around green content
    VIPSImage *image = [self createImageWithMarginsWidth:100 height:100 marginSize:15
                                           contentColorR:0 contentColorG:255 contentColorB:0
                                        backgroundColorR:0 backgroundColorG:0 backgroundColorB:0];

    NSError *error = nil;
    NSArray<NSNumber *> *bgColor = [image detectBackgroundColorWithError:&error];

    XCTAssertNotNil(bgColor, @"Should detect background color: %@", error);
    XCTAssertEqual(bgColor.count, 3, @"Should have 3 channels");
}

- (void)testDetectBackgroundColorWithStripWidth {
    // Image with gray margins
    VIPSImage *image = [self createImageWithMarginsWidth:100 height:100 marginSize:25
                                           contentColorR:255 contentColorG:0 contentColorB:0
                                        backgroundColorR:128 backgroundColorG:128 backgroundColorB:128];

    NSError *error = nil;
    NSArray<NSNumber *> *bgColor = [image detectBackgroundColorWithStripWidth:20 error:&error];

    XCTAssertNotNil(bgColor, @"Should detect background color with strip width: %@", error);
    XCTAssertEqual(bgColor.count, 3, @"Should have 3 channels");
}

#pragma mark - Find Trim Tests

- (void)testFindTrimWhiteMargins {
    // 100x100 image with 20px white margins around red content
    // Content should be 60x60 starting at (20, 20)
    VIPSImage *image = [self createImageWithMarginsWidth:100 height:100 marginSize:20
                                           contentColorR:255 contentColorG:0 contentColorB:0
                                        backgroundColorR:255 backgroundColorG:255 backgroundColorB:255];

    NSError *error = nil;
    CGRect bounds = [image findTrimWithError:&error];

    XCTAssertNil(error, @"Should not have error: %@", error);
    XCTAssertFalse(CGRectIsEmpty(bounds), @"Bounds should not be empty");

    // Content area should be approximately 60x60 at (20, 20)
    XCTAssertEqualWithAccuracy(bounds.origin.x, 20.0, 3.0, @"X origin should be ~20");
    XCTAssertEqualWithAccuracy(bounds.origin.y, 20.0, 3.0, @"Y origin should be ~20");
    XCTAssertEqualWithAccuracy(bounds.size.width, 60.0, 3.0, @"Width should be ~60");
    XCTAssertEqualWithAccuracy(bounds.size.height, 60.0, 3.0, @"Height should be ~60");
}

- (void)testFindTrimBlackMargins {
    // 150x100 image with 25px black margins around green content
    VIPSImage *image = [self createImageWithMarginsWidth:150 height:100 marginSize:25
                                           contentColorR:0 contentColorG:255 contentColorB:0
                                        backgroundColorR:0 backgroundColorG:0 backgroundColorB:0];

    NSError *error = nil;
    CGRect bounds = [image findTrimWithError:&error];

    XCTAssertNil(error, @"Should not have error: %@", error);
    XCTAssertFalse(CGRectIsEmpty(bounds), @"Bounds should not be empty");

    // Content area: 150 - 2*25 = 100 wide, 100 - 2*25 = 50 tall
    XCTAssertGreaterThan(bounds.size.width, 0, @"Width should be > 0");
    XCTAssertGreaterThan(bounds.size.height, 0, @"Height should be > 0");
}

- (void)testFindTrimWithThreshold {
    VIPSImage *image = [self createImageWithMarginsWidth:100 height:100 marginSize:15
                                           contentColorR:200 contentColorG:50 contentColorB:50
                                        backgroundColorR:255 backgroundColorG:255 backgroundColorB:255];

    NSError *error = nil;
    CGRect bounds = [image findTrimWithThreshold:10.0 error:&error];

    XCTAssertNil(error, @"Should not have error: %@", error);
    XCTAssertFalse(CGRectIsEmpty(bounds), @"Bounds should not be empty");
}

- (void)testFindTrimWithExplicitBackground {
    VIPSImage *image = [self createImageWithMarginsWidth:100 height:100 marginSize:10
                                           contentColorR:100 contentColorG:100 contentColorB:100
                                        backgroundColorR:200 backgroundColorG:200 backgroundColorB:200];

    NSError *error = nil;
    CGRect bounds = [image findTrimWithThreshold:5.0 background:@[@200, @200, @200] error:&error];

    XCTAssertNil(error, @"Should not have error: %@", error);
    XCTAssertFalse(CGRectIsEmpty(bounds), @"Bounds should not be empty");

    // Content should be 80x80 at (10, 10)
    XCTAssertEqualWithAccuracy(bounds.origin.x, 10.0, 3.0, @"X origin should be ~10");
    XCTAssertEqualWithAccuracy(bounds.origin.y, 10.0, 3.0, @"Y origin should be ~10");
    XCTAssertEqualWithAccuracy(bounds.size.width, 80.0, 3.0, @"Width should be ~80");
    XCTAssertEqualWithAccuracy(bounds.size.height, 80.0, 3.0, @"Height should be ~80");
}

- (void)testFindTrimNoMargins {
    // Solid color image - no margins to trim
    VIPSImage *image = [self createSolidColorImageWithWidth:50 height:50 red:128 green:128 blue:128];

    NSError *error = nil;
    CGRect bounds = [image findTrimWithError:&error];

    XCTAssertNil(error, @"Should not have error: %@", error);

    // Entire image should be returned since it's uniform
    XCTAssertEqualWithAccuracy(bounds.origin.x, 0.0, 1.0, @"X origin should be 0");
    XCTAssertEqualWithAccuracy(bounds.origin.y, 0.0, 1.0, @"Y origin should be 0");
    XCTAssertEqualWithAccuracy(bounds.size.width, 50.0, 1.0, @"Width should be 50");
    XCTAssertEqualWithAccuracy(bounds.size.height, 50.0, 1.0, @"Height should be 50");
}

#pragma mark - Image Arithmetic Tests

- (void)testSubtractIdenticalImages {
    // Subtracting identical images should give zeros
    VIPSImage *image1 = [self createSolidColorImageWithWidth:50 height:50 red:100 green:100 blue:100];
    VIPSImage *image2 = [self createSolidColorImageWithWidth:50 height:50 red:100 green:100 blue:100];

    NSError *error = nil;
    VIPSImage *diff = [image1 subtract:image2 error:&error];

    XCTAssertNotNil(diff, @"Should subtract images: %@", error);
    XCTAssertNil(error);

    // Get statistics - difference should be zero
    VIPSImageStatistics *stats = [diff statisticsWithError:&error];
    XCTAssertNotNil(stats);
    XCTAssertEqualWithAccuracy(stats.mean, 0.0, 1.0, @"Mean difference should be ~0");
}

- (void)testSubtractDifferentImages {
    VIPSImage *image1 = [self createSolidColorImageWithWidth:50 height:50 red:200 green:200 blue:200];
    VIPSImage *image2 = [self createSolidColorImageWithWidth:50 height:50 red:100 green:100 blue:100];

    NSError *error = nil;
    VIPSImage *diff = [image1 subtract:image2 error:&error];

    XCTAssertNotNil(diff, @"Should subtract images: %@", error);

    // The difference should be non-zero
    VIPSImageStatistics *stats = [diff statisticsWithError:&error];
    XCTAssertNotNil(stats);
    XCTAssertGreaterThan(fabs(stats.mean), 50.0, @"Mean difference should be significant");
}

- (void)testAbsolute {
    // Create images where subtraction gives negative values
    VIPSImage *image1 = [self createSolidColorImageWithWidth:50 height:50 red:50 green:50 blue:50];
    VIPSImage *image2 = [self createSolidColorImageWithWidth:50 height:50 red:100 green:100 blue:100];

    NSError *error = nil;
    VIPSImage *diff = [image1 subtract:image2 error:&error];
    XCTAssertNotNil(diff, @"Should subtract images");

    // The raw difference is negative (-50), take absolute value
    VIPSImage *absDiff = [diff absoluteWithError:&error];
    XCTAssertNotNil(absDiff, @"Should get absolute value: %@", error);

    // Absolute difference should be positive
    VIPSImageStatistics *stats = [absDiff statisticsWithError:&error];
    XCTAssertNotNil(stats);
    XCTAssertGreaterThan(stats.mean, 0.0, @"Mean absolute difference should be positive");
}

- (void)testSubtractAndAbsoluteForSimilarity {
    // Real-world use case: comparing two images for similarity
    VIPSImage *image1 = [self createHorizontalGradientWidth:100 height:50
                                                startColorR:0 startColorG:0 startColorB:0
                                                  endColorR:255 endColorG:255 endColorB:255];

    // Slightly different gradient
    VIPSImage *image2 = [self createHorizontalGradientWidth:100 height:50
                                                startColorR:10 startColorG:10 startColorB:10
                                                  endColorR:245 endColorG:245 endColorB:245];

    NSError *error = nil;
    VIPSImage *diff = [image1 subtract:image2 error:&error];
    XCTAssertNotNil(diff);

    VIPSImage *absDiff = [diff absoluteWithError:&error];
    XCTAssertNotNil(absDiff);

    VIPSImageStatistics *stats = [absDiff statisticsWithError:&error];
    XCTAssertNotNil(stats);

    // Images are similar, so mean difference should be small
    XCTAssertLessThan(stats.mean, 20.0, @"Similar images should have low mean difference");
}

@end
