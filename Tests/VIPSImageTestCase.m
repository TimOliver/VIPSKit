//
//  VIPSImageTestCase.m
//  VIPSKitTests
//
//  Base test case class with shared setup and helper methods
//

#import "VIPSImageTestCase.h"

static BOOL sVIPSInitialized = NO;

@implementation VIPSImageTestCase

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
