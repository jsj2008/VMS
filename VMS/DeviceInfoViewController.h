//
//  DeviceInfoViewController.h
//  
//
//  Created by mac_dev on 16/5/23.
//
//

#import <Cocoa/Cocoa.h>
#import "SettingViewController.h"

@interface DeviceInfoViewController : SettingViewController

@property (nonatomic,weak) IBOutlet NSTextField *macL;
@property (nonatomic,weak) IBOutlet NSTextField *deviceTimeL;

@property (nonatomic,weak) IBOutlet NSTextField *devName;
@property (nonatomic,weak) IBOutlet NSTextField *productName;
@property (nonatomic,weak) IBOutlet NSTextField *firmwareVer;
@property (nonatomic,weak) IBOutlet NSTextField *hardwareVer;
@property (nonatomic,weak) IBOutlet NSTextField *mac;
@property (nonatomic,weak) IBOutlet NSTextField *deviceTime;
@property (nonatomic,weak) IBOutlet NSView *p2pZone;
@property (nonatomic,weak) IBOutlet NSTextField *uidTF;
@property (nonatomic,weak) IBOutlet NSImageView *codeImgView;

@property (assign,nonatomic) FOS_DEVINFO deviceInfo;
- (void)fetch;
- (void)push;
- (NSString *)description;
@end
