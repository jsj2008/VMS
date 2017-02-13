//
//  JFPreferencePanelController+StartUp.m
//  VMS
//
//  Created by mac_dev on 2016/10/24.
//  Copyright © 2016年 mac_dev. All rights reserved.
//

#import "JFPreferencePanelController+StartUp.h"
#import <ServiceManagement/ServiceManagement.h>

@implementation JFPreferencePanelController (StartUp)

+ (BOOL)setStartupAtBoot :(BOOL)isStartUp
{
    NSURL *helperUrl = [[[NSBundle mainBundle] bundleURL] URLByAppendingPathComponent:@"Contents/Library/LoginItems/VMS Helper.app"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[helperUrl path]]) {
        /*OSStatus status = LSRegisterURL((__bridge CFURLRef _Nonnull)(helperUrl), self.autoRun);
         
         if (status != noErr) {
         NSLog(@"LSRegisterURL failed!");
         }*/
        
        NSBundle *bundle = [NSBundle bundleWithURL:helperUrl];
        NSString *identifier = bundle.bundleIdentifier;//@"com.foscam.vms.helper";
        
        return SMLoginItemSetEnabled((__bridge CFStringRef)identifier, isStartUp);
    }
    
    return NO;
}

@end
