//
//  PortViewController.m
//  
//
//  Created by mac_dev on 16/5/23.
//
//

#import "PortViewController.h"

@interface PortViewController ()
@end

@implementation PortViewController

#pragma mark - public api
- (void)fetch
{
    [self setActivity:YES];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FOSCAM_NET_CONFIG config;
        FOS_PORTINFO portInfo;
        config.info = &portInfo;
        BOOL success = [[DispatchCenter sharedDispatchCenter] getConfig:&config
                                                                forType:FOSCAM_NET_CONFIG_NETWORK_PORT
                                                             fromDevice:self.device];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success)
                [self setPortInfo:portInfo];
            else
                [self alert:NSLocalizedString(@"failed to get the settings", nil)
                       info:NSLocalizedString(@"time out", nil)];
            
            [self setActivity:NO];
        });
    });
}

- (void)push
{
    NSVC_ERR code = [self parserPort];
    if (code != NSVC_NO_ERR) {
        [self alert:NSLocalizedString(@"failed to set the settings", nil)
               info:[self errMsg:code]];
        return;
    }
    
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //设置Port信息
        FOSCAM_NET_CONFIG config;
        FOS_PORTINFO portInfo = self.portInfo;
        
        config.info = &portInfo;
        
        BOOL success = [[DispatchCenter sharedDispatchCenter] setConfig:&config
                                                                forType:FOSCAM_NET_CONFIG_NETWORK_PORT
                                                               toDevice:self.device];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success)
                [self onPortInfoChange:portInfo];
            else
                [self alert:NSLocalizedString(@"failed to set the settings", nil)
                       info:NSLocalizedString(@"time out", nil)];
            
            [self setActivity:NO];
        });
    });
}

- (NSString *)description
{
    return NSLocalizedString(@"Port", nil);
}

- (void)onPortInfoChange :(FOS_PORTINFO)portInfo
{
    NSLog(@"Running in class %@ selector '%@'",self.className,NSStringFromSelector(_cmd));
    
    self.device.port = portInfo.webPort;
    
    
    if ([self.delegate respondsToSelector:@selector(svc:deviceInfoDidChange:)]) {
        [self.delegate svc:self deviceInfoDidChange:[NSNotification notificationWithName:@"web port change"
                                                                                  object:self
                                                                                userInfo:@{KEY_RELOAD_WAIT_TIME : @30}]];
    }
}

@end
