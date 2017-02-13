//
//  IPViewController.m
//  
//
//  Created by mac_dev on 16/5/23.
//
//

#import "IPViewController.h"

@interface IPViewController ()

@end

@implementation IPViewController

#pragma mark - public api
- (void)fetch
{
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //设置IP信息
        FOSCAM_NET_CONFIG config;
        FOS_IPINFO ipInfo;
        config.info = &ipInfo;
        BOOL success = [[DispatchCenter sharedDispatchCenter] getConfig:&config
                                                                forType:FOSCAM_NET_CONFIG_NETWORK_IP
                                                             fromDevice:self.device];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success)
                [self setIpInfo :ipInfo];
            else
                [self alert:NSLocalizedString(@"failed to get the settings", nil)
                       info:NSLocalizedString(@"time out", nil)];
            
            [self setActivity:NO];
        });
    });
}

- (void)push
{
    NSVC_ERR code = [self parserIP];
    if (code != NSVC_NO_ERR) {
        [self alert:NSLocalizedString(@"failed to set the settings", nil)
               info:[self errMsg:code]];
        return;
    }
    
    [self setActivity:YES];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FOSCAM_NET_CONFIG config;
        FOS_IPINFO ipInfo = self.ipInfo;
        config.info = &ipInfo;
        
        BOOL success = [[DispatchCenter sharedDispatchCenter] setConfig:&config
                                                                forType:FOSCAM_NET_CONFIG_NETWORK_IP
                                                               toDevice:self.device];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success)
                [self onIPInfoChange:ipInfo];
            else
                [self alert:NSLocalizedString(@"failed to set the settings", nil)
                       info:NSLocalizedString(@"time out", nil)];
            
            [self setActivity:NO];
        });
    });
}

- (NSString *)description
{
    return NSLocalizedString(@"IP", nil);
}

- (void)onIPInfoChange :(FOS_IPINFO)ipInfo
{
    NSLog(@"Running in class %@ selector '%@'",self.className,NSStringFromSelector(_cmd));
    
    self.device.ip = [NSString stringWithCString:ipInfo.ip encoding:NSASCIIStringEncoding];
    
    if ([self.delegate respondsToSelector:@selector(svc:deviceInfoDidChange:)]) {
        [self.delegate svc:self deviceInfoDidChange:[NSNotification notificationWithName:@"ip change"
                                                                                  object:self
                                                                                userInfo:@{KEY_RELOAD_WAIT_TIME : @30}]];
    }
}

@end
