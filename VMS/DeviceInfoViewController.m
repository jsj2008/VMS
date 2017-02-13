//
//  DeviceInfoViewController.m
//  
//
//  Created by mac_dev on 16/5/23.
//
//

#import "DeviceInfoViewController.h"

@interface DeviceInfoViewController ()
@end


@implementation DeviceInfoViewController

#pragma mark - public api

- (void)fetch
{
    [self setActivity:YES];
    
    __block FOSCAM_NET_CONFIG config;
    DispatchCenter *center = [DispatchCenter sharedDispatchCenter];
    CDevice *device = self.device;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FOS_DEVINFO devInfo;
        memset(&devInfo, 0, sizeof(FOS_DEVINFO));
        config.info = &devInfo;
        
        BOOL success = [center getConfig:&config forType:FOSCAM_NET_CONFIG_DEVICE_INFO fromDevice:device];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [self setDeviceInfo :devInfo];
            }
            else
                [self alert:NSLocalizedString(@"failed to get the settings", nil)
                       info:NSLocalizedString(@"time out", nil)];
            
            [self setActivity:NO];
            
            
        });
    });
}

- (void)push
{
    //do nothing
}

- (NSString *)description
{
    return NSLocalizedString(@"Device Information",nil);
}


#pragma mark - life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.p2pZone setHidden:YES];
}

- (void)dealloc
{
    NSLog(@"Running in %@,'%@'",self.className,NSStringFromSelector(_cmd));
}

#pragma mark - setter & getter
- (void)setDeviceInfo:(FOS_DEVINFO)deviceInfo
{
    _deviceInfo = deviceInfo;
    //国标
    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);

    [self.productName setStringValue:[self safetyText:[NSString stringWithCString:deviceInfo.productName encoding:enc]]];
    [self.devName setStringValue:[self safetyText:[NSString stringWithCString:deviceInfo.devName encoding:enc]]];
    [self.mac setStringValue:[self safetyText:[NSString stringWithCString:deviceInfo.mac encoding:enc]]];
    [self.deviceTime setStringValue:[self safetyText:[NSString stringWithFormat:@"%04d/%02d/%02d %02d:%02d:%02d",deviceInfo.year,deviceInfo.mon,deviceInfo.day,deviceInfo.hour,deviceInfo.min,deviceInfo.sec]]];
    [self.firmwareVer setStringValue:[self safetyText:[NSString stringWithCString:deviceInfo.firmwareVer encoding:enc]]];
    [self.hardwareVer setStringValue:[self safetyText:[NSString stringWithCString:deviceInfo.hardwareVer encoding:enc]]];
}

- (SVC_OPTION)option
{
    return SVC_REFRESH;
}

@end
