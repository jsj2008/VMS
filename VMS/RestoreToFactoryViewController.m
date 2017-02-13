//
//  RestoreToFactoryViewController.m
//  
//
//  Created by mac_dev on 16/5/23.
//
//

#import "RestoreToFactoryViewController.h"

@interface RestoreToFactoryViewController ()

@end

@implementation RestoreToFactoryViewController

#pragma mark - public api
- (void)fetch
{}

- (void)push
{}

- (NSString *)description
{
    return NSLocalizedString(@"Factory Reset", nil);
}

- (SVC_OPTION)option
{
    return 0;
}

- (void)performReset
{
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        FOSCAM_NET_CONFIG config;
        BOOL success = [[DispatchCenter sharedDispatchCenter] setConfig:&config
                                                                forType:FOSCAM_NET_CONFIG_SYSTEM_RESET
                                                               toDevice:self.device];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success)
                [self onRestore];
            else
                [self alert:NSLocalizedString(@"failed to factory reset", nil) info:@""];
            
            [self setActivity:NO];
        });
    });
}

- (void)onRestore
{
    if ([self.delegate respondsToSelector:@selector(svc:deviceInfoDidChange:)]) {
        [self.delegate svc:self deviceInfoDidChange:[NSNotification notificationWithName:KEY_RESTORE_NOTIFICATION
                                                                                  object:self
                                                                                userInfo:@{KEY_RELOAD_WAIT_TIME : @100}]];
    }
}

#pragma mark - action
- (IBAction)factoryReset:(id)sender
{
    NSAlert *alert = [[NSAlert alloc] init];
    
    alert.messageText = NSLocalizedString(@"are you sure to restore the factory settings?", nil);
    alert.informativeText = NSLocalizedString(@"Restore factory settings will cause the machine to reboot and restore user configuration information", nil);
    alert.alertStyle = NSAlertStyleWarning;
    
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel",nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
 
    if (NSAlertSecondButtonReturn == [alert runModal]) {
        [self performReset];
    }
}
@end
