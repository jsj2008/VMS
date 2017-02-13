//
//  NetworkSettingViewController.h
//  VMS
//
//  Created by mac_dev on 15/8/28.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "SettingViewController.h"
#import "XStringFomatter.h"
#import "../RegexKit/RegexKit/RegexKitLite.h"


typedef NS_ENUM(NSUInteger, NSVC_ERR) {
    NSVC_NO_ERR,
    NSVC_IP_FOMATE_ERR,
    NSVC_MASK_FOMATE_ERR,
    NSVC_GATE_FOMATE_ERR,
    NSVC_DNS1_FOMATE_ERR,
    NSVC_DNS2_FOMATE_ERR,
    NSVC_INVALID_HTTP_PORT,
    NSVC_INVALID_HTTPS_PORT,
    NSVC_INVALID_ONVIF_PORT,
    NSVC_INVALID_P2P_PORT,
    NSVC_SAME_PORT,
};

#define VMS_MIN_PORT    1
#define VMS_MAX_PORT    65535

@interface NetworkSettingViewController : SettingViewController<NSComboBoxDataSource,NSComboBoxDelegate,NSTabViewDelegate,NSTextFieldDelegate>

- (void)refetch:(NSInteger)tag;
- (void)push:(NSInteger)tag;

@property (assign,nonatomic) FOS_IPINFO ipInfo;
@property (assign,nonatomic) FOS_PPPOECONFIG pppoeConfig;
@property (assign,nonatomic) FOS_UPNPCONFIG upnpConfig;
@property (assign,nonatomic) FOS_PORTINFO portInfo;
@property (assign,nonatomic) FOS_P2PENABLE p2pEnableInfo;
@property (assign,nonatomic) FOS_P2PINFO p2pInfo;
@property (assign,nonatomic) FOS_P2PPORT p2pPortInfo;
@property (assign,nonatomic) FOS_WIFICONFIG wifiConfig;
@property (assign,nonatomic) FOS_DDNSCONFIG ddnsConfig;
@property (assign,nonatomic) FOS_FTPCONFIG ftpConfig;
@property (assign,nonatomic) FOS_SMTPCONFIG smtpConfig;

@end
