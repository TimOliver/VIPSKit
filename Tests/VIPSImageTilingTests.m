//
//  VIPSImageTilingTests.m
//  VIPSKitTests
//
//  Tests for VIPSImage+Tiling: tiling and region extraction methods
//

#import "VIPSImageTestCase.h"

@interface VIPSImageTilingTests : VIPSImageTestCase
@end

@implementation VIPSImageTilingTests

#pragma mark - Tile Calculation Tests

- (void)testTileRects {
    VIPSImage *image = [self createTestImageWithWidth:200 height:200];

    NSArray<NSValue *> *tiles = [image tileRectsWithTileWidth:100 tileHeight:100];

    XCTAssertEqual(tiles.count, 4, @"200x200 image with 100x100 tiles should have 4 tiles");

    // Verify first tile
    CGRect firstTile;
    [tiles[0] getValue:&firstTile];
    XCTAssertEqual(firstTile.origin.x, 0, @"First tile X should be 0");
    XCTAssertEqual(firstTile.origin.y, 0, @"First tile Y should be 0");
    XCTAssertEqual(firstTile.size.width, 100, @"First tile width should be 100");
    XCTAssertEqual(firstTile.size.height, 100, @"First tile height should be 100");
}

- (void)testTileRectsUnevenDivision {
    VIPSImage *image = [self createTestImageWithWidth:250 height:150];

    NSArray<NSValue *> *tiles = [image tileRectsWithTileWidth:100 tileHeight:100];

    // Should have 3 columns x 2 rows = 6 tiles
    XCTAssertEqual(tiles.count, 6, @"250x150 image with 100x100 tiles should have 6 tiles");

    // Verify last tile (should be partial)
    CGRect lastTile;
    [tiles.lastObject getValue:&lastTile];
    XCTAssertEqual(lastTile.size.width, 50, @"Last column width should be 50");
    XCTAssertEqual(lastTile.size.height, 50, @"Last row height should be 50");
}

- (void)testTileRectsSmallTiles {
    VIPSImage *image = [self createTestImageWithWidth:100 height:100];

    NSArray<NSValue *> *tiles = [image tileRectsWithTileWidth:25 tileHeight:25];

    XCTAssertEqual(tiles.count, 16, @"100x100 image with 25x25 tiles should have 16 tiles");
}

#pragma mark - Strip Tests

- (void)testNumberOfStrips {
    VIPSImage *image = [self createTestImageWithWidth:100 height:500];

    NSInteger numStrips = [image numberOfStripsWithHeight:100];

    XCTAssertEqual(numStrips, 5, @"500px height with 100px strips should have 5 strips");
}

- (void)testNumberOfStripsUneven {
    VIPSImage *image = [self createTestImageWithWidth:100 height:550];

    NSInteger numStrips = [image numberOfStripsWithHeight:100];

    XCTAssertEqual(numStrips, 6, @"550px height with 100px strips should have 6 strips (last partial)");
}

- (void)testStripAtIndex {
    VIPSImage *image = [self createTestImageWithWidth:100 height:500];
    NSError *error = nil;

    // First strip
    VIPSImage *strip0 = [image stripAtIndex:0 height:100 error:&error];
    XCTAssertNotNil(strip0, @"Should extract first strip");
    XCTAssertEqual(strip0.width, 100, @"Strip width should match image width");
    XCTAssertEqual(strip0.height, 100, @"Strip height should match requested height");

    // Middle strip
    VIPSImage *strip2 = [image stripAtIndex:2 height:100 error:&error];
    XCTAssertNotNil(strip2, @"Should extract middle strip");
    XCTAssertEqual(strip2.height, 100, @"Strip height should match requested height");

    // Last strip
    VIPSImage *strip4 = [image stripAtIndex:4 height:100 error:&error];
    XCTAssertNotNil(strip4, @"Should extract last strip");
}

- (void)testStripAtIndexPartial {
    VIPSImage *image = [self createTestImageWithWidth:100 height:250];
    NSError *error = nil;

    // Last strip should be partial (50px instead of 100px)
    VIPSImage *lastStrip = [image stripAtIndex:2 height:100 error:&error];
    XCTAssertNotNil(lastStrip, @"Should extract partial strip");
    XCTAssertEqual(lastStrip.height, 50, @"Last strip should be partial height");
}

- (void)testStripAtIndexOutOfBounds {
    VIPSImage *image = [self createTestImageWithWidth:100 height:200];
    NSError *error = nil;

    VIPSImage *strip = [image stripAtIndex:5 height:100 error:&error];
    XCTAssertNil(strip, @"Should fail for out-of-bounds index");
    XCTAssertNotNil(error, @"Should have error for out-of-bounds index");
}

#pragma mark - Region Extraction Tests

- (void)testExtractRegionFromFile {
    NSString *path = [self pathForTestResource:@"superman.jpg"];
    if (!path) {
        XCTSkip(@"superman.jpg not found in test resources");
        return;
    }

    NSError *error = nil;
    VIPSImage *region = [VIPSImage extractRegionFromFile:path x:10 y:10 width:100 height:100 error:&error];

    XCTAssertNotNil(region, @"Should extract region from file: %@", error);
    XCTAssertNil(error, @"Should not have error");
    XCTAssertEqual(region.width, 100, @"Region width should match");
    XCTAssertEqual(region.height, 100, @"Region height should match");
}

- (void)testExtractRegionFromData {
    NSString *path = [self pathForTestResource:@"superman.jpg"];
    if (!path) {
        XCTSkip(@"superman.jpg not found in test resources");
        return;
    }

    NSData *data = [NSData dataWithContentsOfFile:path];
    XCTAssertNotNil(data, @"Should load file data");

    NSError *error = nil;
    VIPSImage *region = [VIPSImage extractRegionFromData:data x:0 y:0 width:50 height:50 error:&error];

    XCTAssertNotNil(region, @"Should extract region from data: %@", error);
    XCTAssertNil(error, @"Should not have error");
    XCTAssertEqual(region.width, 50, @"Region width should match");
    XCTAssertEqual(region.height, 50, @"Region height should match");
}

#pragma mark - Processing Strips Tests

- (void)testProcessAllStrips {
    VIPSImage *image = [self createTestImageWithWidth:100 height:300];
    NSError *error = nil;

    NSInteger stripHeight = 100;
    NSInteger numStrips = [image numberOfStripsWithHeight:stripHeight];

    for (NSInteger i = 0; i < numStrips; i++) {
        VIPSImage *strip = [image stripAtIndex:i height:stripHeight error:&error];
        XCTAssertNotNil(strip, @"Should extract strip %ld", (long)i);
        XCTAssertEqual(strip.width, image.width, @"Strip width should match");
    }
}

@end
