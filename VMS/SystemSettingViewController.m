//
//  SystemSettingViewController.m
//  VMS
//
//  Created by mac_dev on 15/8/29.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "SystemSettingViewController.h"

@interface SystemSettingViewController ()
@property (weak) IBOutlet NSTextField *path;
@end

@implementation SystemSettingViewController

#pragma mrak - public api
- (void)refetch:(NSInteger)tag
{
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^
    {
        switch (tag) {
            case 0: {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setActivity:NO];
                });
            }
                break;
            case 1: {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setActivity:NO];
                });
            }
                break;
                
            case 2: {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setActivity:NO];
                });
            }
                break;
            default: {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setActivity:NO];
                });
            }
                break;
        }
    });
}

#pragma mark - action
- (IBAction)backupConfigFile :(id)sender
{
    NSSavePanel *panel = [NSSavePanel savePanel];
    panel.canCreateDirectories = YES;
   
    
    if ([panel runModal] == NSModalResponseOK) {
        //NSString *path = [[[panel URLs] objectAtIndex:0] path];
        //[self.path setStringValue:path];
    }
}

- (IBAction)browse:(id)sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseDirectories = YES;
    panel.canChooseFiles = NO;
    
    if ([panel runModal] == NSModalResponseOK) {
        NSString *path = [[[panel URLs] objectAtIndex:0] path];
        [self.path setStringValue:path];
    }
}

- (IBAction)import :(id)sender
{
    
}

- (IBAction)factoryReset:(id)sender
{
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        DispatchCenter *center = [DispatchCenter sharedDispatchCenter];
        FOSCAM_NET_CONFIG config;
        [center setConfig:&config forType:FOSCAM_NET_CONFIG_SYSTEM_RESET toDevice:self.device];
     
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setActivity:NO];
        });
    });
}


- (IBAction)reboot:(id)sender
{
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        DispatchCenter *center = [DispatchCenter sharedDispatchCenter];
        FOSCAM_NET_CONFIG config;
        [center setConfig:&config forType:FOSCAM_NET_CONFIG_SYSTEM_RESTART toDevice:self.device];
    
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setActivity:NO];
        });
    });
}
#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

@end
