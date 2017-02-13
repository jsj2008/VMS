//
//  WifiConfigViewController.m
//  VMS
//
//  Created by mac_dev on 16/8/29.
//  Copyright © 2016年 mac_dev. All rights reserved.
//

#import "WifiConfigViewController.h"
#define CNT_PER_PAGE    10.0
#define COL_SSID        @"ssid"
#define COL_ENCRYPTYPE  @"encrypType"
#define COL_QUALITY     @"quality"

@interface WifiConfigViewController ()

@property(nonatomic,assign) int totalPageCnt;
@property(nonatomic,assign) int curPage;
@property(nonatomic,assign) IBOutlet NSTextField *totalPageCntTF;
@property(nonatomic,assign) IBOutlet NSTextField *curPageTF;
@property(nonatomic,assign) IBOutlet NSTableView *wifiListTV;
@property(nonatomic,weak) IBOutlet NSTextField *ssidTF;
@property(nonatomic,weak) IBOutlet NSPopUpButton *encrypTypeBtn;
@property(nonatomic,weak) IBOutlet NSView *pswView;
@property(nonatomic,weak) IBOutlet NSView *wepZone;
@property(nonatomic,weak) IBOutlet NSView *wpaZone;
@property(nonatomic,weak) IBOutlet NSTextField *pskTF;
@property(nonatomic,weak) IBOutlet NSPopUpButton *authModeBtn;
@property(nonatomic,weak) IBOutlet NSPopUpButton *keyFormatBtn;
@property(nonatomic,weak) IBOutlet NSPopUpButton *defaultKeyBtn;
@property(nonatomic,weak) IBOutlet NSTextField *key1TF;
@property(nonatomic,weak) IBOutlet NSTextField *key2TF;
@property(nonatomic,weak) IBOutlet NSTextField *key3TF;
@property(nonatomic,weak) IBOutlet NSTextField *key4TF;
@property(nonatomic,weak) IBOutlet NSPopUpButton *key1LenBtn;
@property(nonatomic,weak) IBOutlet NSPopUpButton *key2LenBtn;
@property(nonatomic,weak) IBOutlet NSPopUpButton *key3LenBtn;
@property(nonatomic,weak) IBOutlet NSPopUpButton *key4LenBtn;

@end

@implementation WifiConfigViewController

#pragma mark - public api
- (void)fetch
{
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FOS_WIFICONFIG wifiConfig;
        FOSCAM_NET_CONFIG   config;
        
        config.info = &wifiConfig;
        
        BOOL success = [[DispatchCenter sharedDispatchCenter] getConfig:&config
                                                                forType:FOSCAM_NET_CONFIG_NETWORK_WIFI
                                                             fromDevice:self.device];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success)
                [self setWifiConfig:wifiConfig];
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
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FOS_WIFISETTING wifiSetting = [self wifiSettingFromUI];
        FOSCAM_NET_CONFIG config;
        
        config.info = &wifiSetting;
        BOOL success = [[DispatchCenter sharedDispatchCenter] setConfig:&config
                                                                forType:FOSCAM_NET_CONFIG_NETWORK_WIFI
                                                               toDevice:self.device];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!success)
                [self alert:NSLocalizedString(@"failed to set the settings", nil)
                       info:NSLocalizedString(@"time out", nil)];
            [self setActivity:NO];
        });
    });
}


- (NSString *)description
{
    return NSLocalizedString(@"Wireless", nil);
}

- (SVC_OPTION)option
{
    return SVC_REFRESH | SVC_SAVE;
}


#pragma mark - action
- (IBAction)scan:(id)sender
{
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FOSCAM_NET_CONFIG   config;
        BOOL success = [[DispatchCenter sharedDispatchCenter] getConfig:&config
                                                                forType:FOSCAM_NET_CONFIG_NETWORK_WIFI_REFRESH
                                                             fromDevice:self.device];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [self fetchWifiListWithStartNo:0];
            }
            else
                [self alert:NSLocalizedString(@"scan wifi failed", nil)
                       info:NSLocalizedString(@"time out", nil)];
            [self setActivity:NO];
        });
    });
}


- (void)fetchWifiListWithStartNo:(int)startNo
{
    [self setActivity:YES];
    __block int tmp = startNo;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FOS_WIFILIST wifiList;
        FOSCAM_NET_CONFIG   config;
        
        config.info = &tmp;
        config.info2 = &wifiList;
        
        BOOL success = [[DispatchCenter sharedDispatchCenter] getConfig:&config
                                                                forType:FOSCAM_NET_CONFIG_NETWORK_WIFI_LIST
                                                             fromDevice:self.device];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                self.totalPageCnt = ceil(wifiList.totalCnt / CNT_PER_PAGE);
                self.curPage = startNo/10;
                [self setWifiList:wifiList];
            }
            else
                [self alert:NSLocalizedString(@"failed to get the settings", nil)
                       info:NSLocalizedString(@"time out", nil)];
            
            [self setActivity:NO];
        });
    });
}

- (IBAction)jump:(id)sender
{
    NSInteger tag = [sender tag];
    int page = 0;
    
    
    switch (tag) {
        case 0:
            page = self.curPage -1;
            break;
        case 1:
            page = self.curPage +1;
            break;
        case 2:
            page = self.curPageTF.intValue - 1;
            break;
        default:
            break;
    }
    
    if (page >= 0 && page < self.totalPageCnt) {
        [self fetchWifiListWithStartNo:page * 10];
    }
}


-(IBAction)encrypTypeSelect:(id)sender
{
    [self updatePswViewUI];
}

#pragma mark - update
- (void)updateWifiListUI
{
    [self.wifiListTV reloadData];
}

- (void)updateWifiConfigUI
{
    self.ssidTF.stringValue = [NSString stringWithCString:self.wifiConfig.ssid encoding:NSASCIIStringEncoding];
    [self.encrypTypeBtn selectItemWithTag:self.wifiConfig.encryptType];
    self.pskTF.stringValue = [NSString stringWithCString:self.wifiConfig.psk encoding:NSASCIIStringEncoding];
    [self.authModeBtn selectItemWithTag:self.wifiConfig.authMode];
    [self.keyFormatBtn selectItemWithTag:self.wifiConfig.keyFormat];
    [self.defaultKeyBtn selectItemWithTag:self.wifiConfig.defaultKey];
    self.key1TF.stringValue = [NSString stringWithCString:self.wifiConfig.key1 encoding:NSASCIIStringEncoding];
    self.key2TF.stringValue = [NSString stringWithCString:self.wifiConfig.key2 encoding:NSASCIIStringEncoding];
    self.key3TF.stringValue = [NSString stringWithCString:self.wifiConfig.key3 encoding:NSASCIIStringEncoding];
    self.key4TF.stringValue = [NSString stringWithCString:self.wifiConfig.key4 encoding:NSASCIIStringEncoding];
    [self.key1LenBtn selectItemWithTag:self.wifiConfig.key1Len];
    [self.key2LenBtn selectItemWithTag:self.wifiConfig.key2Len];
    [self.key3LenBtn selectItemWithTag:self.wifiConfig.key3Len];
    [self.key4LenBtn selectItemWithTag:self.wifiConfig.key4Len];
    [self updatePswViewUI];
}

- (void)updatePswViewUI
{
    NSInteger tag = self.encrypTypeBtn.selectedTag;
    
    [self.wepZone removeFromSuperview];
    [self.wpaZone removeFromSuperview];
    
    switch (tag) {
        case 1:
            [self.pswView addSubview:self.wepZone];
            break;
        case 2:
        case 3:
        case 4:
            [self.pswView addSubview:self.wpaZone];
            break;
        case 0:
        default:
            break;
    }
}

- (FOS_WIFISETTING)wifiSettingFromUI
{
    FOS_WIFISETTING wifiSetting;
    memset(&wifiSetting, 0, sizeof(FOS_WIFISETTING));
    
    [self.ssidTF.stringValue getCString:wifiSetting.ssid maxLength:SSID_LEN encoding:NSASCIIStringEncoding];
    wifiSetting.encryptType = (int)[self.encrypTypeBtn selectedTag];
    [self.pskTF.stringValue getCString:wifiSetting.psk maxLength:PSK_LEN encoding:NSASCIIStringEncoding];
    wifiSetting.authMode = (int)[self.authModeBtn selectedTag];
    wifiSetting.keyFormat = (int)[self.keyFormatBtn selectedTag];
    wifiSetting.defaultKey = (int)[self.defaultKeyBtn selectedTag];
    [self.key1TF.stringValue getCString:wifiSetting.key1 maxLength:KEY_LEN encoding:NSASCIIStringEncoding];
    [self.key2TF.stringValue getCString:wifiSetting.key2 maxLength:KEY_LEN encoding:NSASCIIStringEncoding];
    [self.key3TF.stringValue getCString:wifiSetting.key3 maxLength:KEY_LEN encoding:NSASCIIStringEncoding];
    [self.key4TF.stringValue getCString:wifiSetting.key4 maxLength:KEY_LEN encoding:NSASCIIStringEncoding];
    wifiSetting.key1Len = (int)[self.key1LenBtn selectedTag];
    wifiSetting.key2Len = (int)[self.key2LenBtn selectedTag];
    wifiSetting.key3Len = (int)[self.key3LenBtn selectedTag];
    wifiSetting.key4Len = (int)[self.key4LenBtn selectedTag];
    return wifiSetting;
}

#pragma mark - table view datasource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.wifiList.curCnt;
}

#pragma mark - table view delegate
- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row
{
    NSString *identifier = tableColumn.identifier;
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:identifier owner:self];
    
    if (cellView) {
        WifiAPInfo apInfo;
        if ([self getInfo:&apInfo fromAp:self.wifiList.ap[row]]) {
            
            if ([identifier isEqualToString:COL_SSID])
                cellView.textField.stringValue = [NSString stringWithCString:apInfo.ssid encoding:NSASCIIStringEncoding];
            else if ([identifier isEqualToString:COL_ENCRYPTYPE])
                cellView.textField.stringValue = [self stringFromEncrypType:apInfo.encrypType];
            else {
                int i = apInfo.quality / 20;
                if (i > 4)
                    i = 4;
                else if (i < 0)
                    i = 0;
                cellView.imageView.image = [NSImage imageNamed:[NSString stringWithFormat:@"wifi%d",i]];
            }
        }
    }
    
    return cellView;
}

- (void)tableView:(NSTableView *)tableView didClickedRow:(NSInteger)row
{
    NSInteger selectedRow = self.wifiListTV.selectedRow;
    WifiAPInfo wifiApInfo;
    
    if ([self getInfo:&wifiApInfo fromAp:self.wifiList.ap[selectedRow]]) {
        FOS_WIFICONFIG wifiConfig = self.wifiConfig;
        
        memset(&wifiConfig, 0, sizeof(FOS_WIFICONFIG));
        strcpy(wifiConfig.ssid, wifiApInfo.ssid);
        wifiConfig.encryptType = wifiApInfo.encrypType;
        self.wifiConfig = wifiConfig;
    }
}

#pragma mark - private
- (BOOL)getInfo :(WifiAPInfo *)info fromAp :(char [AP_LEN])ap
{
    if (info) {
        //开始解析ap
        NSString *str = [NSString stringWithCString:ap encoding:NSASCIIStringEncoding];
        NSArray *components = [str componentsSeparatedByString:@"+"];
        
        if (components.count == 5) {
            [components[0] getCString:info->ssid maxLength:64 encoding:NSASCIIStringEncoding];
            [components[1] getCString:info->mac maxLength:18 encoding:NSASCIIStringEncoding];
            info->quality = [components[2] intValue];
            info->encryption = [components[3] intValue];
            info->encrypType = [components[4] intValue];
            
            return YES;
        }
    }
    
    return NO;
}

- (NSString *)stringFromEncrypType :(char)type
{
    switch (type) {
        case 1:
            return @"WEP";
        case 2:
            return @"WPA";
        case 3:
            return @"WPA2";
        case 4:
            return @"WPA/WPA2";
        case 0:
        default:
            return NSLocalizedString(@"None", nil);
    }
}

#pragma mark - setter & getter
- (void)setWifiList:(FOS_WIFILIST)wifiList
{
    _wifiList = wifiList;
    [self updateWifiListUI];
}

- (void)setTotalPageCnt:(int)totalPageCnt
{
    _totalPageCnt = totalPageCnt;
    [self.totalPageCntTF setIntValue:totalPageCnt];
}

- (void)setCurPage:(int)curPage
{
    _curPage = curPage;
    [self.curPageTF setIntValue:curPage + 1];
}

- (void)setWifiConfig :(FOS_WIFICONFIG)wifiConfig
{
    _wifiConfig = wifiConfig;
    [self updateWifiConfigUI];
}


@end
