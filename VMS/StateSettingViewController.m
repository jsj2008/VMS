//
//  StateSettingViewController.m
//  VMS
//
//  Created by mac_dev on 15/8/28.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "StateSettingViewController.h"

@interface StateSettingViewController ()

//info
@property (weak) IBOutlet NSTextField *productName;
@property (weak) IBOutlet NSTextField *devName;
@property (weak) IBOutlet NSTextField *mac;
@property (weak) IBOutlet NSTextField *deviceTime;
@property (weak) IBOutlet NSTextField *firmwareVer;
@property (weak) IBOutlet NSTextField *hardwareVer;
//state
@property (weak) IBOutlet NSTextField *motionDetectAlarm;

@property (weak) IBOutlet NSTextField *record;
@property (weak) IBOutlet NSTextField *sdState;
@property (weak) IBOutlet NSTextField *sdFreeSpace;
@property (weak) IBOutlet NSTextField *sdTotalSpace;
@property (weak) IBOutlet NSTextField *ntpState;
@property (weak) IBOutlet NSTextField *ddnsState;
@property (weak) IBOutlet NSTextField *upnpState;
@property (weak) IBOutlet NSTextField *wifiConnectedAP;
@property (weak) IBOutlet NSTextField *infraLedState;

@end

@implementation StateSettingViewController

#pragma mark - public api
- (void)refetch :(NSInteger)tag
{
    [self setActivity:YES];
    
    __block FOSCAM_NET_CONFIG config;
    DispatchCenter *center = [DispatchCenter sharedDispatchCenter];
    CDevice *device = self.device;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
    {
        switch (tag) {
            case 0: {
                FOS_DEVINFO devInfo;
                config.info = &devInfo;
                
                BOOL success = [center getConfig:&config forType:FOSCAM_NET_CONFIG_DEVICE_INFO fromDevice:device];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (success) [self setDeviceInfo :devInfo];
                    else [self alert:@"超时"];
                    [self setActivity:NO];
                });
            }
                break;
            case 1: {
                FOS_DEVSTATE devState;
                config.info = &devState;
                BOOL success = [center getConfig:&config forType:FOSCAM_NET_CONFIG_DEVICE_STATE fromDevice:device];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (success) [self setDeviceState :devState];
                    else [self alert:@"超时"];
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

#pragma mark - tabview delegate
- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    NSInteger index = [tabView indexOfTabViewItem:tabViewItem];
    [self refetch :index];
}

#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    //[self refetch :0];
}

#pragma mark - private method
- (NSString *)stringFromState :(int)state
{
    return state? @"开启" : @"关闭";
}

#pragma mark - setter && getter
- (void)setDeviceState:(FOS_DEVSTATE)deviceState
{
    _deviceState = deviceState;
    [self.motionDetectAlarm setStringValue:[self stringFromState:deviceState.motionDetectAlarm]];
    [self.record setStringValue:[self stringFromState:deviceState.record]];
    [self.ntpState setStringValue:[self stringFromState:deviceState.ntpState]];
    [self.ddnsState setStringValue:[self stringFromState:deviceState.ddnsState]];
    [self.upnpState setStringValue:[self stringFromState:deviceState.upnpState]];
    [self.wifiConnectedAP setStringValue:[self safetyText:[NSString stringWithUTF8String:deviceState.wifiConnectedAP]]];
    [self.infraLedState setStringValue:[self stringFromState:deviceState.infraLedState]];
    [self.sdState setStringValue:[self stringFromState:deviceState.sdState]];
    [self.sdFreeSpace setStringValue:[self safetyText:[NSString stringWithUTF8String:deviceState.sdFreeSpace]]];
    [self.sdTotalSpace setStringValue:[self safetyText:[NSString stringWithUTF8String:deviceState.sdTotalSpace]]];
}

- (void)setDeviceInfo:(FOS_DEVINFO)deviceInfo
{
    _deviceInfo = deviceInfo;
    [self.productName setStringValue:[self safetyText:[NSString stringWithUTF8String:deviceInfo.productName]]];
    [self.devName setStringValue:[self safetyText:[NSString stringWithUTF8String:deviceInfo.devName]]];
    [self.mac setStringValue:[self safetyText:[NSString stringWithUTF8String:deviceInfo.mac]]];
    [self.deviceTime setStringValue:[self safetyText:[NSString stringWithFormat:@"%4d/%2d/%2d %2d:%2d:%2d",deviceInfo.year,deviceInfo.mon,deviceInfo.day,deviceInfo.hour,deviceInfo.min,deviceInfo.sec]]];
    [self.firmwareVer setStringValue:[self safetyText:[NSString stringWithUTF8String:deviceInfo.firmwareVer]]];
    [self.hardwareVer setStringValue:[self safetyText:[NSString stringWithUTF8String:deviceInfo.hardwareVer]]];
}
@end
