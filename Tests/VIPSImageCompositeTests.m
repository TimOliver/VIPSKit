//
//  VIPSImageCompositeTests.m
//  VIPSKitTests
//
//  Tests for VIPSImage+Composite: image compositing and blending methods
//

#import "VIPSImageTestCase.h"

@interface VIPSImageCompositeTests : VIPSImageTestCase
@end

@implementation VIPSImageCompositeTests

#pragma mark - Basic Composite Tests

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

- (void)testCompositeAtCorners {
    VIPSImage *base = [self createTestImageWithWidth:100 height:100];
    VIPSImage *overlay = [self createTestImageWithWidth:20 height:20 bands:4];
    NSError *error = nil;

    // Top-left
    VIPSImage *topLeft = [base compositeWithOverlay:overlay mode:VIPSBlendModeOver x:0 y:0 error:&error];
    XCTAssertNotNil(topLeft, @"Should composite at top-left");

    // Top-right
    VIPSImage *topRight = [base compositeWithOverlay:overlay mode:VIPSBlendModeOver x:80 y:0 error:&error];
    XCTAssertNotNil(topRight, @"Should composite at top-right");

    // Bottom-left
    VIPSImage *bottomLeft = [base compositeWithOverlay:overlay mode:VIPSBlendModeOver x:0 y:80 error:&error];
    XCTAssertNotNil(bottomLeft, @"Should composite at bottom-left");

    // Bottom-right
    VIPSImage *bottomRight = [base compositeWithOverlay:overlay mode:VIPSBlendModeOver x:80 y:80 error:&error];
    XCTAssertNotNil(bottomRight, @"Should composite at bottom-right");
}

- (void)testCompositeCentered {
    VIPSImage *base = [self createTestImageWithWidth:100 height:100];
    VIPSImage *overlay = [self createTestImageWithWidth:50 height:50 bands:4];

    NSError *error = nil;
    VIPSImage *composited = [base compositeWithOverlay:overlay mode:VIPSBlendModeOver error:&error];

    XCTAssertNotNil(composited, @"Should composite centered");
    XCTAssertNil(error, @"Should not have error: %@", error);
    XCTAssertEqual(composited.width, base.width, @"Should maintain base dimensions");
}

#pragma mark - Blend Mode Tests

- (void)testBlendModeMultiply {
    VIPSImage *base = [self createTestImageWithWidth:100 height:100];
    VIPSImage *overlay = [self createTestImageWithWidth:100 height:100 bands:4];

    NSError *error = nil;
    VIPSImage *composited = [base compositeWithOverlay:overlay mode:VIPSBlendModeMultiply x:0 y:0 error:&error];

    XCTAssertNotNil(composited, @"Should composite with multiply");
    XCTAssertNil(error, @"Should not have error: %@", error);
}

- (void)testBlendModeScreen {
    VIPSImage *base = [self createTestImageWithWidth:100 height:100];
    VIPSImage *overlay = [self createTestImageWithWidth:100 height:100 bands:4];

    NSError *error = nil;
    VIPSImage *composited = [base compositeWithOverlay:overlay mode:VIPSBlendModeScreen x:0 y:0 error:&error];

    XCTAssertNotNil(composited, @"Should composite with screen");
    XCTAssertNil(error, @"Should not have error: %@", error);
}

- (void)testBlendModeOverlay {
    VIPSImage *base = [self createTestImageWithWidth:100 height:100];
    VIPSImage *overlay = [self createTestImageWithWidth:100 height:100 bands:4];

    NSError *error = nil;
    VIPSImage *composited = [base compositeWithOverlay:overlay mode:VIPSBlendModeOverlay x:0 y:0 error:&error];

    XCTAssertNotNil(composited, @"Should composite with overlay mode");
    XCTAssertNil(error, @"Should not have error: %@", error);
}

- (void)testBlendModeAdd {
    VIPSImage *base = [self createTestImageWithWidth:100 height:100];
    VIPSImage *overlay = [self createTestImageWithWidth:100 height:100 bands:4];

    NSError *error = nil;
    VIPSImage *composited = [base compositeWithOverlay:overlay mode:VIPSBlendModeAdd x:0 y:0 error:&error];

    XCTAssertNotNil(composited, @"Should composite with add");
    XCTAssertNil(error, @"Should not have error: %@", error);
}

- (void)testBlendModeDifference {
    VIPSImage *base = [self createTestImageWithWidth:100 height:100];
    VIPSImage *overlay = [self createTestImageWithWidth:100 height:100 bands:4];

    NSError *error = nil;
    VIPSImage *composited = [base compositeWithOverlay:overlay mode:VIPSBlendModeDifference x:0 y:0 error:&error];

    XCTAssertNotNil(composited, @"Should composite with difference");
    XCTAssertNil(error, @"Should not have error: %@", error);
}

#pragma mark - Multiple Blend Modes Test

- (void)testMultipleBlendModes {
    VIPSImage *base = [self createTestImageWithWidth:100 height:100];
    VIPSImage *overlay = [self createTestImageWithWidth:50 height:50 bands:4];
    NSError *error = nil;

    VIPSBlendMode modes[] = {
        VIPSBlendModeClear,
        VIPSBlendModeSource,
        VIPSBlendModeOver,
        VIPSBlendModeMultiply,
        VIPSBlendModeScreen,
        VIPSBlendModeOverlay,
        VIPSBlendModeDarken,
        VIPSBlendModeLighten,
        VIPSBlendModeAdd,
        VIPSBlendModeDifference,
        VIPSBlendModeExclusion
    };

    int numModes = sizeof(modes) / sizeof(modes[0]);
    for (int i = 0; i < numModes; i++) {
        VIPSImage *composited = [base compositeWithOverlay:overlay mode:modes[i] x:25 y:25 error:&error];
        XCTAssertNotNil(composited, @"Should composite with mode %d", modes[i]);
    }
}

#pragma mark - Export Composite Tests

- (void)testExportComposited {
    VIPSImage *base = [self createTestImageWithWidth:200 height:200];
    VIPSImage *overlay = [self createTestImageWithWidth:100 height:100 bands:4];

    NSError *error = nil;
    VIPSImage *composited = [base compositeWithOverlay:overlay mode:VIPSBlendModeOver x:50 y:50 error:&error];
    XCTAssertNotNil(composited, @"Should composite");

    // Export to verify the composition
    NSData *data = [composited dataWithFormat:VIPSImageFormatPNG quality:0 error:&error];
    XCTAssertNotNil(data, @"Should export composited image");
    XCTAssertGreaterThan(data.length, 0, @"Should have data");
}

@end
