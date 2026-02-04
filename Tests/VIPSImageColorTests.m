//
//  VIPSImageColorTests.m
//  VIPSKitTests
//
//  Tests for VIPSImage+Color: color space and color manipulation methods
//

#import "VIPSImageTestCase.h"

@interface VIPSImageColorTests : VIPSImageTestCase
@end

@implementation VIPSImageColorTests

#pragma mark - Grayscale Tests

- (void)testGrayscale {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    VIPSImage *gray = [image grayscaleWithError:&error];

    XCTAssertNotNil(gray, @"Should convert to grayscale");
    XCTAssertNil(error, @"Should not have error: %@", error);
    XCTAssertEqual(gray.bands, 1, @"Grayscale should have 1 band");
}

- (void)testGrayscaleFromRGBA {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100 bands:4];

    NSError *error = nil;
    VIPSImage *gray = [image grayscaleWithError:&error];

    XCTAssertNotNil(gray, @"Should convert RGBA to grayscale");
    // Grayscale conversion may produce 1 or 2 bands (with alpha)
    XCTAssertLessThanOrEqual(gray.bands, 2, @"Should have 1 or 2 bands");
}

#pragma mark - Flatten Tests

- (void)testFlattenAlpha {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100 bands:4];

    NSError *error = nil;
    VIPSImage *flattened = [image flattenWithRed:255 green:255 blue:255 error:&error];

    XCTAssertNotNil(flattened, @"Should flatten alpha");
    XCTAssertNil(error, @"Should not have error: %@", error);
    XCTAssertFalse(flattened.hasAlpha, @"Flattened image should not have alpha");
}

- (void)testFlattenWithDifferentBackgrounds {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100 bands:4];
    NSError *error = nil;

    // White background
    VIPSImage *white = [image flattenWithRed:255 green:255 blue:255 error:&error];
    XCTAssertNotNil(white, @"Should flatten with white background");

    // Black background
    VIPSImage *black = [image flattenWithRed:0 green:0 blue:0 error:&error];
    XCTAssertNotNil(black, @"Should flatten with black background");

    // Colored background
    VIPSImage *colored = [image flattenWithRed:128 green:64 blue:192 error:&error];
    XCTAssertNotNil(colored, @"Should flatten with colored background");
}

#pragma mark - Invert Tests

- (void)testInvert {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    VIPSImage *inverted = [image invertWithError:&error];

    XCTAssertNotNil(inverted, @"Should invert image");
    XCTAssertNil(error, @"Should not have error: %@", error);
    XCTAssertEqual(inverted.width, image.width, @"Dimensions should not change");
}

- (void)testDoubleInvert {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    VIPSImage *inverted1 = [image invertWithError:&error];
    XCTAssertNotNil(inverted1, @"Should invert image");

    VIPSImage *inverted2 = [inverted1 invertWithError:&error];
    XCTAssertNotNil(inverted2, @"Should double-invert image");
    // Double invert should return to original (approximately)
}

#pragma mark - Brightness Tests

- (void)testBrightnessAdjustment {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    VIPSImage *brightened = [image adjustBrightness:0.2 error:&error];

    XCTAssertNotNil(brightened, @"Should adjust brightness");
    XCTAssertNil(error, @"Should not have error: %@", error);
}

- (void)testBrightnessRange {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];
    NSError *error = nil;

    // Darken
    VIPSImage *darker = [image adjustBrightness:-0.5 error:&error];
    XCTAssertNotNil(darker, @"Should darken image");

    // Brighten
    VIPSImage *brighter = [image adjustBrightness:0.5 error:&error];
    XCTAssertNotNil(brighter, @"Should brighten image");
}

#pragma mark - Contrast Tests

- (void)testContrastAdjustment {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    VIPSImage *contrasted = [image adjustContrast:1.5 error:&error];

    XCTAssertNotNil(contrasted, @"Should adjust contrast");
    XCTAssertNil(error, @"Should not have error: %@", error);
}

- (void)testContrastRange {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];
    NSError *error = nil;

    // Low contrast
    VIPSImage *lowContrast = [image adjustContrast:0.5 error:&error];
    XCTAssertNotNil(lowContrast, @"Should reduce contrast");

    // High contrast
    VIPSImage *highContrast = [image adjustContrast:2.0 error:&error];
    XCTAssertNotNil(highContrast, @"Should increase contrast");
}

#pragma mark - Saturation Tests

- (void)testSaturationAdjustment {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    VIPSImage *saturated = [image adjustSaturation:1.5 error:&error];

    XCTAssertNotNil(saturated, @"Should adjust saturation");
    XCTAssertNil(error, @"Should not have error: %@", error);
}

- (void)testDesaturate {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    VIPSImage *desaturated = [image adjustSaturation:0.0 error:&error];

    XCTAssertNotNil(desaturated, @"Should desaturate image");
    // Full desaturation should produce grayscale-like result
}

#pragma mark - Gamma Tests

- (void)testGammaAdjustment {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    VIPSImage *gammaCorrected = [image adjustGamma:2.2 error:&error];

    XCTAssertNotNil(gammaCorrected, @"Should adjust gamma");
    XCTAssertNil(error, @"Should not have error: %@", error);
}

- (void)testGammaRange {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];
    NSError *error = nil;

    // Lighten midtones
    VIPSImage *lighter = [image adjustGamma:0.5 error:&error];
    XCTAssertNotNil(lighter, @"Should lighten with low gamma");

    // Darken midtones
    VIPSImage *darker = [image adjustGamma:2.0 error:&error];
    XCTAssertNotNil(darker, @"Should darken with high gamma");
}

#pragma mark - Combined Adjustment Tests

- (void)testCombinedAdjustment {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    VIPSImage *adjusted = [image adjustBrightness:0.1 contrast:1.2 saturation:1.1 error:&error];

    XCTAssertNotNil(adjusted, @"Should apply combined adjustments");
    XCTAssertNil(error, @"Should not have error: %@", error);
}

- (void)testCombinedAdjustmentNoSaturationChange {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    // When saturation is 1.0, it should skip the saturation adjustment
    VIPSImage *adjusted = [image adjustBrightness:0.2 contrast:1.5 saturation:1.0 error:&error];

    XCTAssertNotNil(adjusted, @"Should apply B/C without saturation change");
    XCTAssertNil(error, @"Should not have error: %@", error);
}

@end
