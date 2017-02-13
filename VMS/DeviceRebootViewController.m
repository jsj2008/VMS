//
//  DeviceRebootViewController.m
//  
//
//  Created by mac_dev on 16/5/23.
//
//

#import "DeviceRebootViewController.h"

@interface DeviceRebootViewController ()

@end

@implementation DeviceRebootViewController

#pragma mark - public api
- (void)fetch
{}

- (void)push
{}

- (NSString *)description
{
    return NSLocalizedString(@"Reboot", nil);
}

- (SVC_OPTION)option
{
    return 0;
}

- (void)performReboot
{
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        DispatchCenter *center = [DispatchCenter sharedDispatchCenter];
        FOSCAM_NET_CONFIG config;
        BOOL success = [center setConfig:&config forType:FOSCAM_NET_CONFIG_SYSTEM_RESTART toDevice:self.device];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success)
                [self onReboot];
            else
                [self alert:NSLocalizedString(@"failed to reboot", nil) info:@""];
            
            [self setActivity:NO];
        });
    });
}

- (void)onReboot
{
    if ([self.delegate respondsToSelector:@selector(svc:deviceInfoDidChange:)]) {
        [self.delegate svc:self deviceInfoDidChange:[NSNotification notificationWithName:KEY_REBOOT_NOTIFICATION
                                                                                  object:self
                                                                                userInfo:@{KEY_RELOAD_WAIT_TIME : @100}]];
    }
}

#pragma mark - action
- (IBAction)reboot:(id)sender
{
    NSAlert *alert = [[NSAlert alloc] init];
    
    alert.messageText = NSLocalizedString(@"are you sure reboot now?", nil);
    alert.informativeText = @"";
    alert.alertStyle = NSAlertStyleWarning;
    
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel",nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
    
    if (NSAlertSecondButtonReturn == [alert runModal]) {
        [self performReboot];
    }
}
@end
