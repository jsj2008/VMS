//
//  DeviceNameViewController.m
//  
//
//  Created by mac_dev on 16/5/23.
//
//

#import "DeviceNameViewController.h"
#import "XStringFomatter.h"

@interface DeviceNameViewController ()

@property (nonatomic,weak) IBOutlet NSTextField *deviceName;
@property (nonatomic,weak) IBOutlet XStringFomatter *deviceNameFormatter;
@end

@implementation DeviceNameViewController
@synthesize devName = _devName;

#pragma mark - public api
- (void)fetch
{
    [self setActivity:YES];
    
    __block FOSCAM_NET_CONFIG config;
    DispatchCenter *center = [DispatchCenter sharedDispatchCenter];
    CDevice *device = self.device;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        char device_name[128];
        config.info = device_name;
        
        BOOL success = [center getConfig:&config forType:FOSCAM_NET_CONFIG_DEVICE_NAME fromDevice:device];
        NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
        NSString *deviceName = [NSString stringWithCString:device_name encoding:enc];
        
        dispatch_async(dispatch_get_main_queue(), ^ {
            if (success)
                [self setDevName :deviceName];
            else
                [self alert:NSLocalizedString(@"failed to get the settings", nil)
                       info:NSLocalizedString(@"time out", nil)];
            [self setActivity:NO];
        });
    });
}

- (void)push
{
    [self setActivity:YES];
    
    __block FOSCAM_NET_CONFIG config;
    DispatchCenter *center = [DispatchCenter sharedDispatchCenter];
    CDevice *device = self.device;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        char devName[128];
        NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
        
        [self.devName getCString:devName maxLength:128 encoding:enc];
    
        //设备名
        config.info = (void *)devName;
        [center setConfig:&config forType:FOSCAM_NET_CONFIG_DEVICE_NAME toDevice:device];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setActivity:NO];
        });
    });
}

- (NSString *)description
{
    return NSLocalizedString(@"Device Name", nil);
}

- (SVC_OPTION)option
{
    return SVC_REFRESH | SVC_SAVE;
}

#pragma mark - setter & getter
- (void)setDevName:(NSString *)devName
{
    _devName = devName;
    [self.deviceName setStringValue:[self safetyText:devName]];
}

- (NSString *)devName
{
    _devName = [self.deviceName stringValue];
    return _devName;
}

- (void)setDeviceNameFormatter:(XStringFomatter *)deviceNameFormatter
{
    _deviceNameFormatter = deviceNameFormatter;
    [_deviceNameFormatter setMaxLength :20];
    [_deviceNameFormatter setRegex:@"^[a-zA-Z0-9_-]{0,20}$"];
}

@end
