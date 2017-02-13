//
//  P2PViewController.m
//  
//
//  Created by mac_dev on 16/5/23.
//
//

#import "P2PViewController.h"

@interface P2PViewController ()

@property (nonatomic,weak) IBOutlet NSTextField *uid;
@property (nonatomic,assign) BOOL p2pEnable;
@property (nonatomic,weak) IBOutlet NSTextField *p2pPort;

@end

@implementation P2PViewController
@synthesize p2pEnableInfo = _p2pEnableInfo;
@synthesize p2pInfo = _p2pInfo;
@synthesize p2pPortInfo = _p2pPortInfo;

#pragma mark - public api
- (void)fetch
{
    [self setActivity:YES];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FOSCAM_NET_CONFIG config;
        FOS_P2PINFO p2pInfo;
        FOS_P2PENABLE p2pEnable;
        FOS_P2PPORT p2pPort;
        
        void *infos[] = {
            &p2pInfo,
            &p2pEnable,
            &p2pPort,
        };
        
        FOSCAM_NET_CONFIG_TYPE types[3] = {
            FOSCAM_NET_CONFIG_NETWORK_P2P_INFO,
            FOSCAM_NET_CONFIG_NETWORK_P2P_ENABLE,
            FOSCAM_NET_CONFIG_NETWORK_P2P_PORT
        };
        
        BOOL success = YES;
        for (int i = 0; (i < 3) && success; i++) {
            config.info = infos[i];
            success = [[DispatchCenter sharedDispatchCenter] getConfig:&config
                                                               forType:types[i]
                                                            fromDevice:self.device];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [self setP2pInfo:p2pInfo];
                [self setP2pEnableInfo:p2pEnable];
                [self setP2pPortInfo :p2pPort];
                [self setActivity:NO];
            } else
                [self alert:NSLocalizedString(@"failed to get the settings", nil)
                       info:NSLocalizedString(@"time out", nil)];
        });
    });
}

- (void)push
{
    P2P_ERR code = [self parserUID];
    if (code != P2P_NO_ERR) {
        [self alert:NSLocalizedString(@"failed to set the settings", nil)
               info:[self errMsg:code]];
        return;
    }
    
    [self setActivity:YES];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FOSCAM_NET_CONFIG config;
        FOS_P2PENABLE p2pEnable = self.p2pEnableInfo;
        FOS_P2PPORT p2pPort = self.p2pPortInfo;
        
        void *infos[2] = {
            &p2pEnable,
            &p2pPort
        };
        
        FOSCAM_NET_CONFIG_TYPE types[2] = {
            FOSCAM_NET_CONFIG_NETWORK_P2P_ENABLE,
            FOSCAM_NET_CONFIG_NETWORK_P2P_PORT,
        };
        
        BOOL success = YES;
        for (int i = 0; (i < 2) && success; i++) {
            config.info = infos[i];
            success = [[DispatchCenter sharedDispatchCenter] setConfig:&config
                                                               forType:types[i]
                                                              toDevice:self.device];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success)
                [self onP2pInfoChange];
            else
                [self alert:NSLocalizedString(@"failed to set the settings", nil)
                       info:NSLocalizedString(@"time out", nil)];
            [self setActivity:NO];
        });
    });
}

- (NSString *)description
{
    return NSLocalizedString(@"P2P", nil);
}

- (SVC_OPTION)option
{
    return SVC_REFRESH | SVC_SAVE;
}

#pragma mark - private api
- (P2P_ERR)parserUID
{
    if (self.p2pPort.integerValue < VMS_MIN_PORT || self.p2pPort.integerValue > VMS_MAX_PORT)
        return P2P_INVALID_P2P_PORT;
    
    return P2P_NO_ERR;
}

- (NSString *)errMsg :(P2P_ERR)code
{
    switch (code) {
        case P2P_NO_ERR:
            return NSLocalizedString(@"success", nil);
        
        case P2P_INVALID_P2P_PORT:
            return NSLocalizedString(@"invalid port", nil);
            
        default:
            return NSLocalizedString(@"unknow error", nil);
    }
}

- (void)onP2pInfoChange
{
    NSLog(@"Running in class %@ selector '%@'",self.className,NSStringFromSelector(_cmd));
    
    if ([self.delegate respondsToSelector:@selector(svc:deviceInfoDidChange:)]) {
        [self.delegate svc:self deviceInfoDidChange:[NSNotification notificationWithName:@"p2p change"
                                                                                  object:self
                                                                                userInfo:@{KEY_RELOAD_WAIT_TIME : @30}]];
    }
}

#pragma mark - setter && getter
- (void)setP2pEnableInfo:(FOS_P2PENABLE)p2pEnableInfo
{
    _p2pEnableInfo = p2pEnableInfo;
    self.p2pEnable = p2pEnableInfo.enable;
}

- (FOS_P2PENABLE)p2pEnableInfo
{
    _p2pEnableInfo.enable = self.p2pEnable;
    return _p2pEnableInfo;
}

- (void)setP2pInfo:(FOS_P2PINFO)p2pInfo
{
    _p2pInfo = p2pInfo;
    [self.uid setStringValue:[self safetyText:[NSString stringWithCString:p2pInfo.uid encoding:NSASCIIStringEncoding]]];
}

- (FOS_P2PINFO)p2pInfo
{
    [self.uid.stringValue getCString:_p2pInfo.uid maxLength:UID_LEN encoding:NSASCIIStringEncoding];
    
    return _p2pInfo;
}

- (void)setP2pPortInfo:(FOS_P2PPORT)p2pPortInfo
{
    _p2pPortInfo = p2pPortInfo;
    [self.p2pPort setIntValue:p2pPortInfo.port];
}

- (FOS_P2PPORT)p2pPortInfo
{
    _p2pPortInfo.port = [self.p2pPort intValue];
    return _p2pPortInfo;
}

@end
