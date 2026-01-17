//
//  AppDelegate.m
//  TestHost
//
//  Minimal test host app for VIPSKit unit tests
//

#import "AppDelegate.h"
@import VIPSKit;

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Initialize VIPSKit
    NSError *error = nil;
    if (![VIPSImage initializeWithError:&error]) {
        NSLog(@"Failed to initialize VIPSKit: %@", error);
    }
    return YES;
}

@end
