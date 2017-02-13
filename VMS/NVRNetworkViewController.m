//
//  NVRNetworkViewController.m
//  
//
//  Created by mac_dev on 16/5/25.
//
//

#import "NVRNetworkViewController.h"

@interface NVRNetworkViewController ()

@property(nonatomic,weak) IBOutlet NSPopUpButton *networkTypeBtn;
@property(nonatomic,weak) IBOutlet NSPopUpButton *upnpOptionBtn;

@end

@implementation NVRNetworkViewController

#pragma mark - public api
- (void)fetch
{
    [self setActivity:YES];
    
    DispatchCenter *center = [DispatchCenter sharedDispatchCenter];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //设置IP信息
        FOSCAM_NVR_CONFIG config;
        char xml[OUT_BUFFER_LENGTH] = {0};
        
        config.output = xml;
        config.outputLen = OUT_BUFFER_LENGTH;
        
        BOOL success = NO;
        FOS_IPINFO ipInfo;
        FOS_PORTINFO portInfo;
        BOOL isUpnp = NO;
        if ([center getConfig:&config forType:FOSCAM_NVR_CONFIG_NET fromDevice:self.device]) {
            //解析结果
            NSError *err = nil;
            NSString *rawString = [NSString stringWithCString:xml encoding:NSASCIIStringEncoding];
            NSLog(@"%@",rawString);
            //NSArray *values = [self parserCGIXml:rawString error:&err];
            NSDictionary *dict = [XMLHelper parserCGIXml:rawString error:&err];
            
            if (!err/* && values.count == 11*/) {
                //查看是否成功
                if ([[dict valueForKey:@"result"] intValue] == 0) {
                    success = YES;
                    ipInfo.isDHCP = [[dict valueForKey:@"isDHCP"] boolValue];
                    isUpnp = [[dict valueForKey:@"isUPNP"] boolValue];
                    portInfo.webPort = [[dict valueForKey:@"httpPort"] intValue];
                    portInfo.httpsPort = [[dict valueForKey:@"httpsPort"] intValue];
                    [[dict valueForKey:@"ip"] getCString:ipInfo.ip maxLength:IPADDR_LEN encoding:NSASCIIStringEncoding];
                    [[dict valueForKey:@"gate"] getCString:ipInfo.gate maxLength:GATE_LEN encoding:NSASCIIStringEncoding];
                    [[dict valueForKey:@"mask"] getCString:ipInfo.mask maxLength:MASK_LEN encoding:NSASCIIStringEncoding];
                    [[dict valueForKey:@"dns1"] getCString:ipInfo.dns1 maxLength:DNS_LEN encoding:NSASCIIStringEncoding];
                    [[dict valueForKey:@"dns2"] getCString:ipInfo.dns2 maxLength:DNS_LEN encoding:NSASCIIStringEncoding];
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [self setIpInfo :ipInfo];
                [self setPortInfo:portInfo];
                [self setIsUPNP:isUpnp];
            } else
                [self alert:NSLocalizedString(@"failed to get the settings", nil)
                       info:NSLocalizedString(@"time out", nil)];
            [self setActivity:NO];
        });
    });
}

- (void)push
{
    NSVC_ERR ipRet = [self parserIP];
    if (ipRet != NSVC_NO_ERR) {
        [self alert:NSLocalizedString(@"failed to set the settings", nil)
               info:[self errMsg:ipRet]];
        return;
    }
    
    NSVC_ERR portRet = [self parserPort];
    if (portRet != NSVC_NO_ERR) {
        [self alert:NSLocalizedString(@"failed to set the settings", nil)
               info:[self errMsg:portRet]];
        return;
    }
    
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FOSCAM_NVR_CONFIG config;
        FOS_NVR_NETINFO netInfo;
        char xml[OUT_BUFFER_LENGTH] = {0};
        
        netInfo.isUPNP = self.isUPNP;
        netInfo.ipInfo = self.ipInfo;
        netInfo.portInfo = self.portInfo;
        config.input = &netInfo;
        config.output = xml;
        config.outputLen = OUT_BUFFER_LENGTH;

        BOOL success = NO;
        if ([[DispatchCenter sharedDispatchCenter] setConfig:&config forType:FOSCAM_NVR_CONFIG_NET toDevice:self.device]) {
            //解析结果
            NSError *err = nil;
            NSString *rawString = [NSString stringWithCString:xml encoding:NSASCIIStringEncoding];
            NSDictionary *values = [XMLHelper parserCGIXml:rawString error:&err];
            
            if (DEBUG_CGI) {
                NSLog(@"%@",rawString);
            }
            
            if (!err) {
                NSNumber *result = [values valueForKey:KEY_XML_RESULT];
                success = result && (result.intValue == 0);
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success)
                [self onNetConfigChange:netInfo];
            else
                [self alert:NSLocalizedString(@"failed to set the settings", nil)
                       info:NSLocalizedString(@"time out",nil)];
            [self setActivity:NO];
        });
    });
}

- (NSString *)description
{
    return NSLocalizedString(@"Network", nil);
}

- (void)onNetConfigChange :(FOS_NVR_NETINFO)nvrNetInfo
{
    NSLog(@"Running in class %@ selector '%@'",self.className,NSStringFromSelector(_cmd));
    
    self.device.port = nvrNetInfo.portInfo.webPort;
    self.device.ip = [NSString stringWithCString:nvrNetInfo.ipInfo.ip encoding:NSASCIIStringEncoding];
    
    if ([self.delegate respondsToSelector:@selector(svc:deviceInfoDidChange:)]) {
        [self.delegate svc:self deviceInfoDidChange:[NSNotification notificationWithName:@"net info change"
                                                                                  object:self
                                                                                userInfo:@{KEY_RELOAD_WAIT_TIME : @30}]];
    }
}

#pragma mark - data
- (NSArray *)networkTypes
{
    return @[NSLocalizedString(@"DHCP", nil),
             NSLocalizedString(@"Static IP", nil)];
}

- (NSArray *)upnpOptions
{
    return @[NSLocalizedString(@"off", nil) ,
             NSLocalizedString(@"on", nil)];
}

#pragma mark - setter & getter
- (void)setNetworkTypeBtn:(NSPopUpButton *)networkTypeBtn
{
    _networkTypeBtn = networkTypeBtn;
    [self setControl:_networkTypeBtn withTitles:[self networkTypes]];
}

- (void)setUpnpOptionBtn:(NSPopUpButton *)upnpOptionBtn
{
    _upnpOptionBtn = upnpOptionBtn;
    [self setControl:_upnpOptionBtn withTitles:[self upnpOptions]];
}
@end
