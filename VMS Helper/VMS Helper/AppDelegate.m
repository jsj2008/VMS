//
//  AppDelegate.m
//  VMS Helper
//  该应用程序作为VMS的启动程序，仅在后台运行，启动完成后，自动退出
//  Created by mac_dev on 16/9/13.
//  Copyright © 2016年 mac_dev. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    NSString *path = [[[[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
    
    BOOL isLaunched = NO;
    NSArray *runningApplications = [[NSWorkspace sharedWorkspace] runningApplications];
    NSUInteger appCnt = runningApplications.count;
    NSLog(@"runningApplications count = %ld",appCnt);
    
    for (NSUInteger i = 0; i < appCnt; i++) {
        NSRunningApplication *app = runningApplications[i];
        NSString *bundleIdentifier = app.bundleIdentifier;
        
        NSLog(@"bundleIdentifier = %@",bundleIdentifier);
        if ([bundleIdentifier isEqualToString:@"com.foscam.vms"]) {
            isLaunched = YES;
            break;
        }
    }
    
    if (!isLaunched) {
        [[NSWorkspace sharedWorkspace] launchApplication:path];
    }
    
    [NSApp terminate:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
