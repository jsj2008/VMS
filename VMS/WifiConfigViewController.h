//
//  WifiConfigViewController.h
//  VMS
//
//  Created by mac_dev on 16/8/29.
//  Copyright © 2016年 mac_dev. All rights reserved.
//

#import "SettingViewController.h"
#import "VMSTableView.h"

typedef struct tagWifiAPInfo
{
    char ssid[64];
    char mac[18];
    int quality; // 0 ~ 100
    char encryption; // 0=OFF 1=ON
    char encrypType; // WIFI_ENCRYPTED_TYPE 0=None 1=WEP 2=WPA 3=WPA2 4=WPA/WPA2
} WifiAPInfo;


@interface WifiConfigViewController : SettingViewController<NSTableViewDataSource,NSTableViewDelegate,
ExtendedTableViewDelegate>

@property(nonatomic,assign) FOS_WIFILIST wifiList;
@property(nonatomic,assign) FOS_WIFICONFIG wifiConfig;

- (void)fetch;
- (void)push;
- (NSString *)description;
- (SVC_OPTION)option;

@end
