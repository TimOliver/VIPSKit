//
//  VIPSImageTransformTests.m
//  VIPSKitTests
//
//  Tests for VIPSImage+Transform: crop, rotate, flip, smart crop methods
//

#import "VIPSImageTestCase.h"

@interface VIPSImageTransformTests : VIPSImageTestCase
@end

@implementation VIPSImageTransformTests

#pragma mark - Crop Tests

- (void)testCrop {
    VIPSImage *image = [self createTestImageWithWidth:200 height:200];

    NSError *error = nil;
    VIPSImage *cropped = [image cropWithX:50 y:50 width:100 height:100 error:&error];

    XCTAssertNotNil(cropped, @"Should crop image");
    XCTAssertNil(error, @"Should not have error: %@", error);
    XCTAssertEqual(cropped.width, 100, @"Cropped width should match");
    XCTAssertEqual(cropped.height, 100, @"Cropped height should match");
}

- (void)testCropCorner {
    VIPSImage *image = [self createTestImageWithWidth:200 height:200];

    NSError *error = nil;
    VIPSImage *cropped = [image cropWithX:0 y:0 width:50 height:50 error:&error];

    XCTAssertNotNil(cropped, @"Should crop top-left corner");
    XCTAssertEqual(cropped.width, 50, @"Width should match");
    XCTAssertEqual(cropped.height, 50, @"Height should match");
}

- (void)testCropFullWidth {
    VIPSImage *image = [self createTestImageWithWidth:200 height:200];

    NSError *error = nil;
    VIPSImage *cropped = [image cropWithX:0 y:50 width:200 height:100 error:&error];

    XCTAssertNotNil(cropped, @"Should crop full width strip");
    XCTAssertEqual(cropped.width, 200, @"Width should be full");
    XCTAssertEqual(cropped.height, 100, @"Height should match");
}

#pragma mark - Rotation Tests

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

- (void)testRotate270 {
    VIPSImage *image = [self createTestImageWithWidth:200 height:100];

    NSError *error = nil;
    VIPSImage *rotated = [image rotateByDegrees:270 error:&error];

    XCTAssertNotNil(rotated, @"Should rotate image");
    XCTAssertEqual(rotated.width, 100, @"Width and height should swap");
    XCTAssertEqual(rotated.height, 200, @"Width and height should swap");
}

- (void)testRotateNegative90 {
    VIPSImage *image = [self createTestImageWithWidth:200 height:100];

    NSError *error = nil;
    VIPSImage *rotated = [image rotateByDegrees:-90 error:&error];

    XCTAssertNotNil(rotated, @"Should rotate image");
    XCTAssertEqual(rotated.width, 100, @"Width and height should swap");
    XCTAssertEqual(rotated.height, 200, @"Width and height should swap");
}

- (void)testRotate0 {
    VIPSImage *image = [self createTestImageWithWidth:200 height:100];

    NSError *error = nil;
    VIPSImage *rotated = [image rotateByDegrees:0 error:&error];

    XCTAssertNotNil(rotated, @"Should handle 0 degree rotation");
    XCTAssertEqual(rotated.width, 200, @"Width should stay same");
    XCTAssertEqual(rotated.height, 100, @"Height should stay same");
}

#pragma mark - Flip Tests

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
    XCTAssertEqual(flipped.width, image.width, @"Dimensions should not change");
    XCTAssertEqual(flipped.height, image.height, @"Dimensions should not change");
}

#pragma mark - Auto Rotate Tests

- (void)testAutoRotate {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSError *error = nil;
    VIPSImage *rotated = [image autoRotateWithError:&error];

    XCTAssertNotNil(rotated, @"Should auto-rotate image");
    XCTAssertNil(error, @"Should not have error: %@", error);
    // Without EXIF orientation, dimensions should stay the same
}

#pragma mark - Smart Crop Tests

- (void)testSmartCrop {
    VIPSImage *image = [self createTestImageWithWidth:400 height:300];

    NSError *error = nil;
    VIPSImage *cropped = [image smartCropToWidth:200 height:200 interesting:VIPSInterestingAttention error:&error];

    XCTAssertNotNil(cropped, @"Should smart crop image");
    XCTAssertNil(error, @"Should not have error: %@", error);
    XCTAssertEqual(cropped.width, 200, @"Should match target width");
    XCTAssertEqual(cropped.height, 200, @"Should match target height");
}

- (void)testSmartCropStrategies {
    VIPSImage *image = [self createTestImageWithWidth:400 height:300];
    NSError *error = nil;

    // Test different strategies
    VIPSInteresting strategies[] = {
        VIPSInterestingNone,
        VIPSInterestingCentre,
        VIPSInterestingEntropy,
        VIPSInterestingAttention,
        VIPSInterestingLow,
        VIPSInterestingHigh
    };

    for (int i = 0; i < 6; i++) {
        VIPSImage *cropped = [image smartCropToWidth:200 height:200 interesting:strategies[i] error:&error];
        XCTAssertNotNil(cropped, @"Should smart crop with strategy %d", i);
        XCTAssertEqual(cropped.width, 200, @"Width should match with strategy %d", i);
        XCTAssertEqual(cropped.height, 200, @"Height should match with strategy %d", i);
    }
}

- (void)testSmartCropPortrait {
    VIPSImage *image = [self createTestImageWithWidth:200 height:400];

    NSError *error = nil;
    VIPSImage *cropped = [image smartCropToWidth:150 height:150 interesting:VIPSInterestingEntropy error:&error];

    XCTAssertNotNil(cropped, @"Should smart crop portrait image");
    XCTAssertEqual(cropped.width, 150, @"Should match target width");
    XCTAssertEqual(cropped.height, 150, @"Should match target height");
}

@end
