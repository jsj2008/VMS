//
//  DeviceStateViewController.m
//  
//
//  Created by mac_dev on 16/5/23.
//
//

#import "DeviceStateViewController.h"

@interface DeviceStateViewController ()
@property (nonatomic,weak) IBOutlet NSTextField *motionDetectAlarm;
@property (nonatomic,weak) IBOutlet NSTextField *record;
@property (nonatomic,weak) IBOutlet NSTextField *sdState;
@property (nonatomic,weak) IBOutlet NSTextField *sdFreeSpace;
@property (nonatomic,weak) IBOutlet NSTextField *sdTotalSpace;
@property (nonatomic,weak) IBOutlet NSTextField *ntpState;
@property (nonatomic,weak) IBOutlet NSTextField *ddnsState;
@property (nonatomic,weak) IBOutlet NSTextField *upnpState;
@property (nonatomic,weak) IBOutlet NSTextField *wifiConnectedAP;
@property (nonatomic,weak) IBOutlet NSTextField *infraLedState;
@end

@implementation DeviceStateViewController

#pragma mark - public api
- (void)fetch
{
    [self setActivity:YES];
    
    __block FOSCAM_NET_CONFIG config;
    DispatchCenter *center = [DispatchCenter sharedDispatchCenter];
    CDevice *device = self.device;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FOS_DEVSTATE devState;
        config.info = &devState;
        BOOL success = [center getConfig:&config forType:FOSCAM_NET_CONFIG_DEVICE_STATE fromDevice:device];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success)
                [self setDeviceState :devState];
            else
                [self alert:NSLocalizedString(@"failed to get the settings", nil)
                       info:NSLocalizedString(@"time out",nil)];
            
            [self setActivity:NO];
        });
    });
}

- (void)push
{}

- (NSString *)description
{
    return NSLocalizedString(@"Device Status", nil);
}

#pragma mark - private api
- (NSString *)stringFromWifiState :(int)state connectedAp :(const char *)ap
{
    switch (state) {
        case 0:
            return NSLocalizedString(@"not connected",nil);
        case 1:
            return [NSString stringWithFormat:@"%@%s",NSLocalizedString(@"connected",nil),ap];
        default:
            break;
    }
    
    return nil;
}

- (NSString *)stringFromDDNSState :(int)state url :(const char *)url
{
    switch (state) {
        case 0:
            return NSLocalizedString(@"disable", nil);
        case 1:
            return NSLocalizedString(@"update failed", nil);
        case 2:
            return [NSString stringWithFormat:@"%@ %s",NSLocalizedString(@"update success", nil),url];
        default:
            break;
    }
    
    return nil;
}

- (NSString *)stringFromNtpState :(int)state
{
    switch (state) {
        case 0:
            return NSLocalizedString(@"disable", nil);
        case 1:
            return NSLocalizedString(@"update failed", nil);
        case 2:
            return NSLocalizedString(@"update success", nil);
        default:
            break;
    }
    
    return nil;
}

- (NSString *)stringFromInfraLedState :(int)state
{
    return state? NSLocalizedString(@"on", nil) : NSLocalizedString(@"off", nil);;
}


- (NSString *)stringFromSdCardState :(int)state
{
    switch (state) {
        case 0:
            return NSLocalizedString(@"no sd card",nil);
        case 1:
            return NSLocalizedString(@"sd card",nil);
        case 2:
            return NSLocalizedString(@"sd card read only",nil);
        default:
            break;
    }
    
    return nil;
}

- (NSString *)stringFromRecordState :(int)state
{
    return state? NSLocalizedString(@"recording",nil) : NSLocalizedString(@"not recording",nil);
}

- (NSString *)stringFromMotionDetectState :(int)state
{
    switch (state) {
        case 0:
            return NSLocalizedString(@"disable",nil);
        case 1:
            return NSLocalizedString(@"no alarm",nil);
        case 2:
            return NSLocalizedString(@"detect alarm",nil);
        default:
            break;
    }
    
    return nil;
}

- (NSString *)stringFromKUnitSpace :(const char *)space
{
    NSString *str = [NSString stringWithCString:space encoding:NSASCIIStringEncoding];
    NSScanner *scanner = [NSScanner scannerWithString:str];
    NSInteger i = 0;
    
    [scanner scanInteger:&i];
    
    if (i < 1024)
        return [NSString stringWithFormat:@"%ldKB",i];
    else {
        CGFloat mbi = i * 1.0 / 1024;
        
        if (mbi < 1024.0)
            return [NSString stringWithFormat:@"%.1fMB",mbi];
        else {
            CGFloat gbi = i * 1.0 / (1024 * 1024);
            
            if (gbi < 1024.0)
                return [NSString stringWithFormat:@"%.1fGB",gbi];
            else {
                CGFloat tbi = i * 1.0 / (1024 * 1024 * 1024);
                
                return [NSString stringWithFormat:@"%.1fTB",tbi];
            }
        }
    }
    
    return str;
}

#pragma mark - setter & getter
- (void)setDeviceState:(FOS_DEVSTATE)deviceState
{
    _deviceState = deviceState;
    
    [self.motionDetectAlarm setStringValue:[self stringFromMotionDetectState:deviceState.motionDetectAlarm]];
    [self.record setStringValue:[self stringFromRecordState:deviceState.record]];
    [self.ntpState setStringValue:[self stringFromNtpState:deviceState.ntpState]];
    [self.ddnsState setStringValue:[self stringFromDDNSState:deviceState.ddnsState url:deviceState.url]];
    [self.upnpState setStringValue:[self stringFromNtpState:deviceState.upnpState]];
    [self.wifiConnectedAP setStringValue:[self stringFromWifiState :deviceState.isWiiConnected connectedAp:deviceState.wifiConnectedAP]];
    [self.infraLedState setStringValue:[self stringFromInfraLedState:deviceState.infraLedState]];
    [self.sdState setStringValue:[self stringFromSdCardState:deviceState.sdState]];
    [self.sdFreeSpace setStringValue:[self stringFromKUnitSpace:deviceState.sdFreeSpace]];
    [self.sdTotalSpace setStringValue:[self stringFromKUnitSpace:deviceState.sdTotalSpace]];
}

- (SVC_OPTION)option
{
    return SVC_REFRESH;
}
@end
