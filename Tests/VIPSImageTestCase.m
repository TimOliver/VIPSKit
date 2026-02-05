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

- (VIPSImage *)createSolidColorImageWithWidth:(NSInteger)width
                                       height:(NSInteger)height
                                          red:(uint8_t)r
                                        green:(uint8_t)g
                                         blue:(uint8_t)b {
    NSMutableData *buffer = [NSMutableData dataWithLength:width * height * 3];
    unsigned char *bytes = (unsigned char *)buffer.mutableBytes;

    for (NSInteger i = 0; i < width * height; i++) {
        bytes[i * 3 + 0] = r;
        bytes[i * 3 + 1] = g;
        bytes[i * 3 + 2] = b;
    }

    NSError *error = nil;
    VIPSImage *image = [VIPSImage imageWithBuffer:buffer.bytes width:width height:height bands:3 error:&error];
    XCTAssertNotNil(image, @"Failed to create solid color image: %@", error);
    return image;
}

- (VIPSImage *)createSolidColorImageWithWidth:(NSInteger)width
                                       height:(NSInteger)height
                                          red:(uint8_t)r
                                        green:(uint8_t)g
                                         blue:(uint8_t)b
                                        alpha:(uint8_t)a {
    NSMutableData *buffer = [NSMutableData dataWithLength:width * height * 4];
    unsigned char *bytes = (unsigned char *)buffer.mutableBytes;

    for (NSInteger i = 0; i < width * height; i++) {
        bytes[i * 4 + 0] = r;
        bytes[i * 4 + 1] = g;
        bytes[i * 4 + 2] = b;
        bytes[i * 4 + 3] = a;
    }

    NSError *error = nil;
    VIPSImage *image = [VIPSImage imageWithBuffer:buffer.bytes width:width height:height bands:4 error:&error];
    XCTAssertNotNil(image, @"Failed to create solid color RGBA image: %@", error);
    return image;
}

- (VIPSImage *)createImageWithMarginsWidth:(NSInteger)width
                                    height:(NSInteger)height
                                marginSize:(NSInteger)margin
                             contentColorR:(uint8_t)contentR
                             contentColorG:(uint8_t)contentG
                             contentColorB:(uint8_t)contentB
                          backgroundColorR:(uint8_t)bgR
                          backgroundColorG:(uint8_t)bgG
                          backgroundColorB:(uint8_t)bgB {
    NSMutableData *buffer = [NSMutableData dataWithLength:width * height * 3];
    unsigned char *bytes = (unsigned char *)buffer.mutableBytes;

    for (NSInteger y = 0; y < height; y++) {
        for (NSInteger x = 0; x < width; x++) {
            NSInteger idx = (y * width + x) * 3;

            // Check if this pixel is in the margin area
            BOOL inMargin = (x < margin || x >= width - margin ||
                            y < margin || y >= height - margin);

            if (inMargin) {
                bytes[idx + 0] = bgR;
                bytes[idx + 1] = bgG;
                bytes[idx + 2] = bgB;
            } else {
                bytes[idx + 0] = contentR;
                bytes[idx + 1] = contentG;
                bytes[idx + 2] = contentB;
            }
        }
    }

    NSError *error = nil;
    VIPSImage *image = [VIPSImage imageWithBuffer:buffer.bytes width:width height:height bands:3 error:&error];
    XCTAssertNotNil(image, @"Failed to create image with margins: %@", error);
    return image;
}

- (VIPSImage *)createHorizontalGradientWidth:(NSInteger)width
                                      height:(NSInteger)height
                                 startColorR:(uint8_t)startR
                                 startColorG:(uint8_t)startG
                                 startColorB:(uint8_t)startB
                                   endColorR:(uint8_t)endR
                                   endColorG:(uint8_t)endG
                                   endColorB:(uint8_t)endB {
    NSMutableData *buffer = [NSMutableData dataWithLength:width * height * 3];
    unsigned char *bytes = (unsigned char *)buffer.mutableBytes;

    for (NSInteger y = 0; y < height; y++) {
        for (NSInteger x = 0; x < width; x++) {
            NSInteger idx = (y * width + x) * 3;
            double t = (double)x / (double)(width - 1);

            bytes[idx + 0] = (uint8_t)(startR + t * (endR - startR));
            bytes[idx + 1] = (uint8_t)(startG + t * (endG - startG));
            bytes[idx + 2] = (uint8_t)(startB + t * (endB - startB));
        }
    }

    NSError *error = nil;
    VIPSImage *image = [VIPSImage imageWithBuffer:buffer.bytes width:width height:height bands:3 error:&error];
    XCTAssertNotNil(image, @"Failed to create gradient image: %@", error);
    return image;
}

@end
