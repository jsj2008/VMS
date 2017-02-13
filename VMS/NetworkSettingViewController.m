//
//  NetworkSettingViewController.m
//  VMS
//
//  Created by mac_dev on 15/8/28.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "NetworkSettingViewController.h"

#define ID_WIFI_AUTH_MODE                       @"Wifi Auth Mode"
#define ID_DDNS_SERVER                          @"DDNS Server"
#define ID_FTP_MODE                             @"Ftp Mode"
#define ID_SMTP_TLS                             @"Smtp Tls"
#define ID_SMTP_NEED_AUTH                       @"Need Auth"

@interface NetworkSettingViewController ()

//@property (weak) IBOutlet NSButton *isDHCP;
@property (assign) BOOL isDHCP;
@property (weak) IBOutlet NSTextField *ip;
@property (weak) IBOutlet NSTextField *mask;
@property (weak) IBOutlet NSTextField *gate;
@property (weak) IBOutlet NSTextField *dns1;
@property (weak) IBOutlet NSTextField *dns2;
//Output-PPPOE
@property (assign) BOOL pppoeEnable;
@property (weak) IBOutlet NSTextField *pppoeUserName;
@property (weak) IBOutlet NSTextField *pppoePassword;
//Output-UPNP
@property (weak) IBOutlet NSComboBox *upnpEnable;
//Output-Port
@property (weak) IBOutlet NSTextField *webPort;
@property (weak) IBOutlet NSTextField *httpsPort;
@property (weak) IBOutlet NSTextField *onvifPort;
//Output-p2p
@property (weak) IBOutlet NSTextField *uid;
@property (assign) BOOL p2pEnable;
@property (weak) IBOutlet NSTextField *p2pPort;
//Output-wifi
@property (weak) IBOutlet NSComboBox *wifiAuthMode;
@property (weak) IBOutlet NSTextField *ssId;
@property (weak) IBOutlet NSTextField *psk;
//Output-ddns
@property (assign) BOOL ddnsEnable;
@property (weak) IBOutlet NSTextField *factoryDDNS;
@property (weak) IBOutlet NSComboBox *ddnsServer;
@property (weak) IBOutlet NSTextField *hostName;
//Output-ftp
@property (weak) IBOutlet NSTextField *ftpAddr;
@property (weak) IBOutlet NSTextField *ftpPort;
@property (weak) IBOutlet NSComboBox *ftpMode;
@property (weak) IBOutlet NSTextField *ftpUserName;
@property (weak) IBOutlet NSTextField *ftpPassword;
@property (weak) IBOutlet NSTextField *ftpTip;
@property (weak) IBOutlet NSTextField *ftpTestResult;
//Output-smtp
@property (assign) BOOL smtpEnable;
@property (weak) IBOutlet NSTextField *smtpServerAddr;
@property (weak) IBOutlet NSTextField *smtpPort;
@property (weak) IBOutlet NSComboBox *smtpTls;
@property (weak) IBOutlet NSComboBox *smtpNeedAuth;
@property (weak) IBOutlet NSTextField *smtpUserName;
@property (weak) IBOutlet NSTextField *smtpPassword;
@property (weak) IBOutlet NSTextField *smtpSender;
@property (weak) IBOutlet NSTextField *smtpReciever1;
@property (weak) IBOutlet NSTextField *smtpReciever2;
@property (weak) IBOutlet NSTextField *smtpReciever3;
@property (weak) IBOutlet NSTextField *smtpReciever4;
@property (weak) IBOutlet NSTextField *smtpTestResult;
@property (weak) IBOutlet NSTextField *smptTip;

//custom fomatter
@property (nonatomic,weak) IBOutlet XStringFomatter *pskFomatter;
@property (nonatomic,weak) IBOutlet XStringFomatter *smtpAddrFomatter;
@property (nonatomic,weak) IBOutlet XStringFomatter *smtpPortFomatter;
@property (nonatomic,weak) IBOutlet XStringFomatter *smtpUserNameFormatter;
@property (nonatomic,weak) IBOutlet XStringFomatter *smtpPasswordFormatter;
@end

@implementation NetworkSettingViewController

@synthesize ipInfo = _ipInfo;
@synthesize pppoeConfig = _pppoeConfig;
@synthesize upnpConfig = _upnpConfig;
@synthesize portInfo = _portInfo;
@synthesize p2pEnableInfo = _p2pEnableInfo;
@synthesize p2pInfo = _p2pInfo;
@synthesize p2pPortInfo = _p2pPortInfo;
@synthesize wifiConfig = _wifiConfig;
@synthesize ddnsConfig = _ddnsConfig;
@synthesize ftpConfig = _ftpConfig;
@synthesize smtpConfig = _smtpConfig;

#pragma mark - public api
- (void)refetch:(NSInteger)tag
{
    [self setActivity:YES];
    
    DispatchCenter *center = [DispatchCenter sharedDispatchCenter];
    __block FOSCAM_NET_CONFIG config;
    CDevice *device = self.device;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        switch (tag) {
            case 0: {
                //设置IP信息
                FOS_IPINFO ipInfo;
                config.info = &ipInfo;
                BOOL success = [center getConfig:&config forType:FOSCAM_NET_CONFIG_NETWORK_IP fromDevice:device];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (success) [self setIpInfo :ipInfo];
                    else [self alert:@"超时"];
                    [self setActivity:NO];
                });
            }
                break;
//            case 1: {
//                FOS_WIFICONFIG wifiConfig;
//                config.info = &wifiConfig;
//                BOOL success = [center getConfig:&config forType:FOSCAM_NET_CONFIG_NETWORK_WIFI fromChannel:channel];
//                
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    if (success) {
//                        [self setWifiConfig:wifiConfig];
//                    } else [self alert:@"超时"];
//                    [self setActivity:NO];
//                });
//            }
//                break;
                //        case 2: {
                //            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
                //                           {
                //                               self.activity = YES;
                //                               //设置PPPOE配置
                //                               FOS_PPPOECONFIG pppoeConfig;
                //                               config.info = &pppoeConfig;
                //                               if ([center getConfig:&config forType:FOSCAM_NET_CONFIG_NETWORK_PPPOE fromChannel:channel])
                //                                   [self setPppoeConfig:pppoeConfig];
                //                               self.activity = NO;
                //                           });
                //        }
                //            break;
//            case 2: {
//                FOS_DDNSCONFIG ddnsConfig;
//                config.info = &ddnsConfig;
//                BOOL success = [center getConfig:&config forType:FOSCAM_NET_CONFIG_NETWORK_DDNS fromChannel:channel];
//                
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    if (success) {
//                        [self setDdnsConfig :ddnsConfig];
//                    } else [self alert:@"超时"];
//                    
//                    [self setActivity:NO];
//                });
//            }
//                break;
//            case 3: {
//                //设置UPNP配置
//                FOS_UPNPCONFIG upnpConfig;
//                config.info = &upnpConfig;
//                BOOL success = [center getConfig:&config forType:FOSCAM_NET_CONFIG_NETWORK_UPNP fromChannel:channel];
//                
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    if (success) {
//                        [self setUpnpConfig:upnpConfig];
//                    } else [self alert:@"超时"];
//                    [self setActivity:NO];
//                });
//            }
//                break;
            case 1: {
                //设置Port信息
                FOS_PORTINFO portInfo;
                config.info = &portInfo;
                BOOL success = [center getConfig:&config forType:FOSCAM_NET_CONFIG_NETWORK_PORT fromDevice:device];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (success) {
                        [self setPortInfo:portInfo];
                    } else [self alert:@"超时"];
                    [self setActivity:NO];
                });
            }
                break;
//            case 5: {
//                //SMTP
//                FOS_SMTPCONFIG smtpConfig;
//                config.info = &smtpConfig;;
//                BOOL success = [center getConfig:&config forType:FOSCAM_NET_CONFIG_NETWORK_SMTP fromChannel:channel];
//                
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    if (success) {
//                        [self setSmtpConfig:smtpConfig];
//                    } else [self alert:@"超时"];
//                    [self setActivity:NO];
//                });
//            }
//                break;
//            case 6: {
//                //FTP
//                FOS_FTPCONFIG ftpConfig;
//                config.info = &ftpConfig;
//                BOOL success = [center getConfig:&config forType:FOSCAM_NET_CONFIG_NETWORK_FTP fromChannel:channel];
//                
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    if (success) {
//                        [self setFtpConfig :ftpConfig];
//                    } else [self alert:@"超时"];
//                    [self setActivity:NO];
//                });
//            }
//                break;
            case 2: {
                //设置p2p信息
                FOS_P2PINFO p2pInfo;
                config.info = &p2pInfo;
                
                __block BOOL success = [center getConfig:&config forType:FOSCAM_NET_CONFIG_NETWORK_P2P_INFO fromDevice:device];
                
                //设置p2p可用
                FOS_P2PENABLE p2pEnable;
                config.info = &p2pEnable;
                success = [center getConfig:&config forType:FOSCAM_NET_CONFIG_NETWORK_P2P_ENABLE fromDevice:device];
                
                //设置p2p端口
                FOS_P2PPORT p2pPort;
                config.info = &p2pPort;
                success = [center getConfig:&config forType:FOSCAM_NET_CONFIG_NETWORK_P2P_PORT fromDevice:device];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (success) {
                        [self setP2pInfo:p2pInfo];
                        [self setP2pEnableInfo:p2pEnable];
                        [self setP2pPortInfo :p2pPort];
                        [self setActivity:NO];
                    } else [self alert:@"超时"];
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


- (void)push :(NSInteger)tag
{
    [self setActivity:YES];
    
    DispatchCenter *center = [DispatchCenter sharedDispatchCenter];
    __block FOSCAM_NET_CONFIG config;
    CDevice *device = self.device;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        switch (tag) {
            case 0: {
                FOS_IPINFO ipInfo = self.ipInfo;
                config.info = &ipInfo;
                [center setConfig:&config forType:FOSCAM_NET_CONFIG_NETWORK_IP toDevice:device];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setActivity:NO];
                });
            }
                break;
//            case 1: {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [self setActivity:NO];
//                });
//            }
//                break;
                //        case 2: {
                //            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
                //            {
                //                self.activity = YES;
                //                //设置PPPOE配置
                //                FOS_PPPOECONFIG pppoeConfig = self.pppoeConfig;
                //                config.info = &pppoeConfig;
                //                [center setConfig:&config forType:FOSCAM_NET_CONFIG_NETWORK_PPPOE channel:channel];
                //                self.activity = NO;
                //            });
                //        }
                //            break;
//            case 2: {
//                FOS_DDNSCONFIG ddnsConfig = self.ddnsConfig;
//                config.info = &ddnsConfig;
//                [center setConfig:&config forType:FOSCAM_NET_CONFIG_NETWORK_DDNS channel:channel];
//                
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [self setActivity:NO];
//                });
//            }
//                break;
//            case 3: {
//                //设置UPNP配置
//                FOS_UPNPCONFIG upnpConfig = self.upnpConfig;
//                config.info = &upnpConfig;
//                [center setConfig:&config forType:FOSCAM_NET_CONFIG_NETWORK_UPNP channel:channel];
//                
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [self setActivity:NO];
//                });
//            }
//                break;
            case 1: {
                //设置Port信息
                FOS_PORTINFO portInfo = self.portInfo;
                config.info = &portInfo;
                [center setConfig:&config forType:FOSCAM_NET_CONFIG_NETWORK_PORT toDevice:device];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setActivity:NO];
                });
            }
                break;
//            case 5: {
//                //SMTP
//                //收集控件信息
//                FOS_SMTPCONFIG smtpConfig = self.smtpConfig;
//                config.info = &smtpConfig;
//                [center setConfig:&config forType:FOSCAM_NET_CONFIG_NETWORK_SMTP channel:channel];
//                
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [self setActivity:NO];
//                });
//            }
//                break;
//            case 6: {
//                //FTP
//                FOS_FTPCONFIG ftpConfig = self.ftpConfig;
//                config.info = &ftpConfig;
//                [center setConfig:&config forType:FOSCAM_NET_CONFIG_NETWORK_FTP channel:channel];
//                
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [self setActivity:NO];
//                });
//            }
//                break;
            case 2: {
                FOS_P2PENABLE p2pEnable = self.p2pEnableInfo;
                config.info = &p2pEnable;
                [center setConfig:&config forType:FOSCAM_NET_CONFIG_NETWORK_P2P_ENABLE toDevice:device];
                
                FOS_P2PINFO p2pInfo = self.p2pInfo;
                config.info = &p2pInfo;
                [center setConfig:&config forType:FOSCAM_NET_CONFIG_NETWORK_P2P_INFO toDevice:device];
                
                FOS_P2PPORT p2pPort = self.p2pPortInfo;
                config.info = &p2pPort;
                [center setConfig:&config forType:FOSCAM_NET_CONFIG_NETWORK_P2P_PORT toDevice:device];
                
                dispatch_async(dispatch_get_main_queue(), ^{
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


#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    //[self refetch :0];
}

#pragma mark - action
- (IBAction)save:(id)sender
{
    NSTabViewItem *item = [self.tabView selectedTabViewItem];
    NSInteger tag = [self.tabView indexOfTabViewItem:item];
    NSVC_ERR code = NSVC_NO_ERR;
    switch (tag) {
        case 0:
            code = [self parserIP];
            break;
        case 1:
            code = [self parserPort];
            break;
        case 2:
            code = [self parserUID];
            break;
        default:
            break;
    }
    
    if (code == NSVC_NO_ERR)
        [super save:sender];
    else {
        NSString *msg = [self errMsg:code];
        [[NSAlert alertWithMessageText:msg
                         defaultButton:@"确定"
                       alternateButton:nil
                           otherButton:nil
             informativeTextWithFormat:@""] runModal];
    }
}

- (IBAction)scanWifi:(id)sender
{
    DispatchCenter *center = [DispatchCenter sharedDispatchCenter];
    CDevice *device = self.device;
    FOSCAM_NET_CONFIG config;
    FOS_WIFILIST wifiList;
    config.info = &wifiList;
    
    if ([center getConfig:&config forType:FOSCAM_NET_CONFIG_NETWORK_WIFI_LIST fromDevice:device]) {
        int count = wifiList.curCnt;
        for (int i = 0; i < count; i++) {
            //NSString *ap = [[NSString stringWithUTF8String:wifiList.ap[i]] stringByRemovingPercentEncoding];
            //NSLog(@"");
        }
    }
}

- (IBAction)testFtp:(id)sender
{
    //准备工作
    [sender setEnabled :NO];
    [self.ftpTip setTextColor :[NSColor redColor]];
    [self.ftpTip setStringValue:@"请等待.........."];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
    {
        FOS_FTPCONFIG ftpConfig = self.ftpConfig;
        FOS_TESTFTPSERVER ftpTest;
        FOSCAM_NET_CONFIG_TEST testInfo;
        FOSCAM_NET_CONFIG config;
        DispatchCenter *center = [DispatchCenter sharedDispatchCenter];
        
        testInfo.input = &ftpConfig;
        testInfo.result = &ftpTest;
        config.info = &testInfo;
        [center getConfig :&config forType:FOSCAM_NET_CONFIG_NETWORK_FTP_TEST fromDevice:self.device];
        dispatch_async(dispatch_get_main_queue(), ^
        {
            NSString *testResult = (ftpTest.testResult == 0)? @"成功" :@"失败";
            [self.ftpTestResult setStringValue:testResult];
         
            [sender setEnabled :YES];
            [self.ftpTip setStringValue :@""];
        });
    });
}

- (IBAction)testSmtp:(id)sender
{
    //准备工作
    [sender setEnabled :NO];
    [self.smptTip setTextColor :[NSColor redColor]];
    [self.smptTip setStringValue:@"请等待.........."];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
    {
        //NSString *encodedURLString;
        FOS_SMTPCONFIG smtpConfig = self.smtpConfig;
        FOS_SMTPTEST smtpTest;
        //收集控件内容
//        smtpConfig.isEnable = self.smtpEnable;
//        smtpConfig.isNeedAuth = (int)[self.smtpNeedAuth indexOfSelectedItem];
//        strcpy(smtpConfig.password, [[self.smtpPassword stringValue] UTF8String]);
//        smtpConfig.port = [self.smtpPort intValue];
//        NSString *reciever = [NSString stringWithFormat:@"%@,,,",[self.smtpReciever1 stringValue]];
//        
//        encodedURLString = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,(CFStringRef)reciever,NULL,
//                                                                                     CFSTR("!*'();:@&=+$,/?%#[]"),kCFStringEncodingUTF8));
//        strcpy(smtpConfig.reciever, [encodedURLString UTF8String]);
//        encodedURLString = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,(CFStringRef)[self.smtpSender stringValue],NULL,CFSTR("!*'();:@&=+$,/?%#[]"),kCFStringEncodingUTF8));
//        strcpy(smtpConfig.sender, [encodedURLString UTF8String]);
//        encodedURLString = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,(CFStringRef)[self.smtpServerAddr stringValue],NULL,CFSTR("!*'();:@&=+$,/?%#[]"),kCFStringEncodingUTF8));
//        strcpy(smtpConfig.server, [encodedURLString UTF8String]);
//        smtpConfig.tls = (int)[self.smtpTls indexOfSelectedItem];
//        encodedURLString = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,(CFStringRef)[self.smtpUserName stringValue],NULL,CFSTR("!*'();:@&=+$,/?%#[]"),kCFStringEncodingUTF8));
//        strcpy(smtpConfig.user, [encodedURLString UTF8String]);
        
        //测试
        FOSCAM_NET_CONFIG config;
        FOSCAM_NET_CONFIG_TEST smtpTesInfo;
        DispatchCenter *center = [DispatchCenter sharedDispatchCenter];
        CDevice *device = self.device;
        smtpTesInfo.input = &smtpConfig;
        smtpTesInfo.result = &smtpTest;
        config.info = &smtpTesInfo;
        [center getConfig :&config forType:FOSCAM_NET_CONFIG_NETWORK_SMTP_TEST fromDevice:device];

        //更新控件
        dispatch_async(dispatch_get_main_queue(), ^
        {
            NSString *testResult = (smtpTest.testResult == 0)? @"成功" :@"失败";
            [self.smtpTestResult setStringValue:testResult];
            
            [sender setEnabled :YES];
            [self.smptTip setStringValue :@""];
        });
    });
}

#pragma mark - combobox datasource
- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
    NSString *identifier = [aComboBox identifier];
    NSInteger count = 0;
    
    if ([identifier isEqualToString:ID_WIFI_AUTH_MODE])
        count = [self availableWifiAuthMode].count;
    else if ([identifier isEqualToString:ID_DDNS_SERVER])
        count = [self availableDDNSServer].count;
    else if ([identifier isEqualToString:ID_FTP_MODE])
        count = [self availableFtpMode].count;
    else if ([identifier isEqualToString:ID_SMTP_TLS])
        count = [self availableSmtpTls].count;
    return count;
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{
    NSString *identifier = [aComboBox identifier];
    NSString *item = @"";
    
    
    if ([identifier isEqualToString:ID_WIFI_AUTH_MODE])
        item = [self availableWifiAuthMode][index];
    else if ([identifier isEqualToString:ID_DDNS_SERVER])
        item = [self availableDDNSServer][index];
    else if ([identifier isEqualToString:ID_FTP_MODE])
        item = [self availableFtpMode][index];
    else if ([identifier isEqualToString:ID_SMTP_TLS])
        item = [self availableSmtpTls][index];
    
    return item;
}

- (NSUInteger)comboBox:(NSComboBox *)aComboBox indexOfItemWithStringValue:(NSString *)string
{
    NSString *identifier = [aComboBox identifier];
    NSUInteger index = 0;
    if ([identifier isEqualToString:ID_WIFI_AUTH_MODE])
        index = [[self availableWifiAuthMode] indexOfObject:string];
    else if ([identifier isEqualToString:ID_DDNS_SERVER])
        index = [[self availableDDNSServer] indexOfObject:string];
    else if ([identifier isEqualToString:ID_FTP_MODE])
        index = [[self availableFtpMode] indexOfObject:string];
    else if ([identifier isEqualToString:ID_SMTP_TLS])
        index = [[self availableSmtpTls] indexOfObject:string];
    
    return index;
}


#pragma mark - private method

- (NSArray *)availableSmtpTls
{
    return [NSArray arrayWithObjects:@"无",@"TLS",@"STARTTLS", nil];
}
- (NSArray *)availableFtpMode
{
    return [NSArray arrayWithObjects:@"被动",@"主动", nil];
}

- (NSArray *)availableDDNSServer
{
    return [NSArray arrayWithObjects:@"无", @"花生壳",@"3322",@"no-ip",@"DynDns", nil];
}
- (NSArray *)availableWifiAuthMode
{
    return [NSArray arrayWithObjects:@"无",@"WEP",@"WAP",@"WAP2",@"WAP/WAP2",nil];
}



- (NSString *)errMsg :(NSVC_ERR)code
{
    switch (code) {
        case NSVC_NO_ERR:
            return @"成功";
            
        case NSVC_IP_FOMATE_ERR:
            return @"IP格式错误";
        
        case NSVC_MASK_FOMATE_ERR:
            return @"子网掩码格式错误";
            
        case NSVC_GATE_FOMATE_ERR:
            return @"网关格式错误";
            
        case NSVC_DNS1_FOMATE_ERR:
            return @"DNS1 格式错误";
            
        case NSVC_DNS2_FOMATE_ERR:
            return @"DNS2 格式错误";
            
        case NSVC_INVALID_HTTP_PORT:
            return @"非法的Http端口号";
            
        case NSVC_INVALID_HTTPS_PORT:
            return @"非法的Https端口号";
            
        case NSVC_INVALID_ONVIF_PORT:
            return @"非法的ONVIF端口号";
            
        case NSVC_INVALID_P2P_PORT:
            return @"非法的p2p端口号";
            
        case NSVC_SAME_PORT:
            return @"相同的端口号";
        default:
            return @"未知错误";
    }
}

- (NSVC_ERR)parserIP
{
    NSString *regex = @"\\b(?:\\d{1,3}\\.){3}\\d{1,3}\\b";
    
    if (![self.ip.stringValue isMatchedByRegex:regex]) return NSVC_IP_FOMATE_ERR;
    if (![self.mask.stringValue isMatchedByRegex:regex]) return NSVC_MASK_FOMATE_ERR;
    if (![self.gate.stringValue isMatchedByRegex:regex]) return NSVC_GATE_FOMATE_ERR;
    if (![self.dns1.stringValue isMatchedByRegex:regex]) return NSVC_DNS1_FOMATE_ERR;
    if (![self.dns2.stringValue isMatchedByRegex:regex]) return NSVC_DNS2_FOMATE_ERR;
    
    return NSVC_NO_ERR;
}

- (NSVC_ERR)parserPort
{
    NSInteger webPort = self.webPort.integerValue;
    NSInteger httpsPort = self.httpsPort.integerValue;
    NSInteger onvifPort = self.onvifPort.integerValue;
    
    
    if (webPort <VMS_MIN_PORT || webPort > VMS_MAX_PORT)
        return NSVC_INVALID_HTTP_PORT;
    if (httpsPort <VMS_MIN_PORT || httpsPort > VMS_MAX_PORT)
        return NSVC_INVALID_HTTPS_PORT;
    if (onvifPort <VMS_MIN_PORT || onvifPort > VMS_MAX_PORT)
        return NSVC_INVALID_ONVIF_PORT;
    if ((webPort == httpsPort) || (webPort == onvifPort) || (httpsPort == onvifPort))
        return NSVC_SAME_PORT;
    
    return NSVC_NO_ERR;
}

- (NSVC_ERR)parserUID
{
    if (self.p2pPort.integerValue < VMS_MIN_PORT || self.p2pPort.integerValue > VMS_MAX_PORT)
        return NSVC_INVALID_P2P_PORT;
    
    return NSVC_NO_ERR;
}
#pragma mark setter && getter
- (void)setIpInfo:(FOS_IPINFO)ipInfo
{
    _ipInfo = ipInfo;
    self.isDHCP = ipInfo.isDHCP;
    [self.ip setStringValue:[NSString stringWithUTF8String:ipInfo.ip]];
    [self.mask setStringValue:[NSString stringWithUTF8String:ipInfo.mask]];
    [self.gate setStringValue:[NSString stringWithUTF8String:ipInfo.gate]];
    [self.dns1 setStringValue:[NSString stringWithUTF8String:ipInfo.dns1]];
    [self.dns2 setStringValue:[NSString stringWithUTF8String:ipInfo.dns2]];
}

- (FOS_IPINFO)ipInfo
{
    _ipInfo.isDHCP = self.isDHCP;
    strcpy(_ipInfo.ip, [[self.ip stringValue] UTF8String]);
    strcpy(_ipInfo.mask, [[self.mask stringValue] UTF8String]);
    strcpy(_ipInfo.gate, [[self.gate stringValue] UTF8String]);
    strcpy(_ipInfo.dns1, [[self.dns1 stringValue] UTF8String]);
    strcpy(_ipInfo.dns1, [[self.dns2 stringValue] UTF8String]);
    return _ipInfo;
}

- (void)setPppoeConfig:(FOS_PPPOECONFIG)pppoeConfig
{
    _pppoeConfig = pppoeConfig;
    self.pppoeEnable = pppoeConfig.isEnable;
    [self.pppoeUserName setStringValue:[self safetyText:[NSString stringWithUTF8String:pppoeConfig.userName]]];
    [self.pppoePassword setStringValue:[self safetyText:[NSString stringWithUTF8String:pppoeConfig.password]]];
}

- (FOS_PPPOECONFIG)pppoeConfig
{
    _pppoeConfig.isEnable = self.pppoeEnable;
    strcpy(_pppoeConfig.userName, [[self.pppoeUserName stringValue] UTF8String]);
    strcpy(_pppoeConfig.password, [[self.pppoePassword stringValue] UTF8String]);
    return _pppoeConfig;
}

- (void)setUpnpConfig:(FOS_UPNPCONFIG)upnpConfig
{
    _upnpConfig = upnpConfig;
    int index = upnpConfig.isEnable;
    if (index < 2) {
        [self.upnpEnable selectItemAtIndex:index];
    }
}

- (FOS_UPNPCONFIG)upnpConfig
{
    _upnpConfig.isEnable = (int)[self.upnpEnable indexOfSelectedItem];
    return _upnpConfig;
}

- (void)setPortInfo:(FOS_PORTINFO)portInfo
{
    _portInfo = portInfo;
    [self.webPort setStringValue:[NSString stringWithFormat:@"%u",portInfo.webPort]];
    [self.httpsPort setStringValue:[NSString stringWithFormat:@"%u",portInfo.httpsPort]];
    [self.onvifPort setStringValue:[NSString stringWithFormat:@"%u",portInfo.onvifPort]];
}

- (FOS_PORTINFO)portInfo
{
    _portInfo.httpsPort = [self.httpsPort intValue];
    _portInfo.webPort = [self.webPort intValue];
    _portInfo.onvifPort = [self.onvifPort intValue];
    return _portInfo;
}


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
    [self.uid setStringValue:[self safetyText:[NSString stringWithUTF8String:p2pInfo.uid]]];
}

- (FOS_P2PINFO)p2pInfo
{
    strcpy(_p2pInfo.uid, [[self.uid stringValue] UTF8String]);
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

- (void)setWifiConfig:(FOS_WIFICONFIG)wifiConfig
{
    _wifiConfig = wifiConfig;
    [self.ssId setStringValue:[self safetyText:[NSString stringWithUTF8String:wifiConfig.ssid]]];
    [self.psk setStringValue:[self safetyText:[NSString stringWithUTF8String:wifiConfig.psk]]];
    [self.wifiAuthMode selectItemAtIndex:wifiConfig.authMode];
}

- (FOS_WIFICONFIG)wifiConfig
{
    _wifiConfig.authMode = (int)[self.wifiAuthMode indexOfSelectedItem];
    strcpy(_wifiConfig.ssid, [[self.ssId stringValue] UTF8String]);
    strcpy(_wifiConfig.psk, [[self.psk stringValue] UTF8String]);
    return _wifiConfig;
}

- (void)setDdnsConfig:(FOS_DDNSCONFIG)ddnsConfig
{
    _ddnsConfig = ddnsConfig;
    [self.factoryDDNS setStringValue:[self safetyText:[NSString stringWithUTF8String:ddnsConfig.factoryDDNS]]];
    [self.hostName setStringValue:[self safetyText:[NSString stringWithUTF8String:ddnsConfig.hostName]]];
    [self.ddnsServer selectItemAtIndex:ddnsConfig.ddnsServer];
}

- (FOS_DDNSCONFIG)ddnsConfig
{
    strcpy(_ddnsConfig.factoryDDNS, [[self.factoryDDNS stringValue] UTF8String]);
    strcpy(_ddnsConfig.hostName, [[self.hostName stringValue] UTF8String]);
    _ddnsConfig.ddnsServer = (int)[self.ddnsServer indexOfSelectedItem];
    return _ddnsConfig;
}

- (void)setFtpConfig:(FOS_FTPCONFIG)ftpConfig
{
    _ftpConfig = ftpConfig;
    [self.ftpAddr setStringValue:[self safetyText:[[NSString stringWithUTF8String:ftpConfig.ftpAddr] stringByRemovingPercentEncoding]]];
    [self.ftpPort setIntValue:ftpConfig.ftpPort];
    [self.ftpUserName setStringValue:[self safetyText:[[NSString stringWithUTF8String:ftpConfig.userName] stringByRemovingPercentEncoding]]];
    [self.ftpPassword setStringValue:[self safetyText:[[NSString stringWithUTF8String:ftpConfig.password] stringByRemovingPercentEncoding]]];
    [self.ftpMode selectItemAtIndex:ftpConfig.mode];
}

- (FOS_FTPCONFIG)ftpConfig
{
    NSString *encodedURLString;
    encodedURLString = [[self.ftpAddr stringValue] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    strcpy(_ftpConfig.ftpAddr, [encodedURLString UTF8String]);
    _ftpConfig.ftpPort = [self.ftpPort intValue];
    encodedURLString = [[self.ftpUserName stringValue] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    strcpy(_ftpConfig.userName, [encodedURLString UTF8String]);
    encodedURLString = [[self.ftpPassword stringValue] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    strcpy(_ftpConfig.password, [encodedURLString UTF8String]);
    _ftpConfig.mode = (int)[self.ftpMode indexOfSelectedItem];
    return _ftpConfig;
}

- (void)setSmtpConfig:(FOS_SMTPCONFIG)smtpConfig
{
    _smtpConfig = smtpConfig;
    self.smtpEnable = smtpConfig.isEnable;
    [self.smtpNeedAuth selectItemAtIndex:smtpConfig.isNeedAuth];
    [self.smtpPassword setStringValue:[self safetyText:[[NSString stringWithUTF8String:smtpConfig.password] stringByRemovingPercentEncoding]]];
    [self.smtpPort setIntValue:smtpConfig.port];
    //取回的四个收件人以“，”分割
    //SDK bug :存放收件人的地址长度不足
    NSArray *recievers = [[[NSString stringWithUTF8String:smtpConfig.reciever] stringByRemovingPercentEncoding] componentsSeparatedByString:@","];
    [self.smtpReciever1 setStringValue:[self safetyText:recievers[0]]];
//    [self.smtpReciever2 setStringValue:[self safetyText:recievers[1]]];
//    [self.smtpReciever3 setStringValue:[self safetyText:recievers[2]]];
//    [self.smtpReciever4 setStringValue:[self safetyText:recievers[3]]];
    
    //SDK bug:取回的发件人为空.
    [self.smtpSender setStringValue:[self safetyText:[[NSString stringWithUTF8String:smtpConfig.sender] stringByRemovingPercentEncoding]]];
    [self.smtpServerAddr setStringValue:[self safetyText:[[NSString stringWithUTF8String:smtpConfig.server] stringByRemovingPercentEncoding]]];
    [self.smtpTls selectItemAtIndex:smtpConfig.tls];
    [self.smtpUserName setStringValue:[[NSString stringWithUTF8String:smtpConfig.user] stringByRemovingPercentEncoding]];
    NSLog(@"stop");
}

- (FOS_SMTPCONFIG)smtpConfigFromUI
{
    FOS_SMTPCONFIG smtpConfig;
    NSString *encodedURLString;
    smtpConfig.isEnable = self.smtpEnable;
    smtpConfig.isNeedAuth = (int)[self.smtpNeedAuth indexOfSelectedItem];
    strcpy(smtpConfig.password, [[self.smtpPassword stringValue] UTF8String]);
    smtpConfig.port = [self.smtpPort intValue];
    NSString *reciever = [NSString stringWithFormat:@"%@,,,",[self.smtpReciever1 stringValue]];
    
    encodedURLString = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,(CFStringRef)reciever,NULL,
                                                                                 CFSTR("!*'();:@&=+$,/?%#[]"),kCFStringEncodingUTF8));
    strcpy(smtpConfig.reciever, [encodedURLString UTF8String]);
    encodedURLString = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,(CFStringRef)[self.smtpSender stringValue],NULL,CFSTR("!*'();:@&=+$,/?%#[]"),kCFStringEncodingUTF8));
    strcpy(smtpConfig.sender, [encodedURLString UTF8String]);
    encodedURLString = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,(CFStringRef)[self.smtpServerAddr stringValue],NULL,CFSTR("!*'();:@&=+$,/?%#[]"),kCFStringEncodingUTF8));
    strcpy(smtpConfig.server, [encodedURLString UTF8String]);
    smtpConfig.tls = (int)[self.smtpTls indexOfSelectedItem];
    encodedURLString = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,(CFStringRef)[self.smtpUserName stringValue],NULL,CFSTR("!*'();:@&=+$,/?%#[]"),kCFStringEncodingUTF8));
    strcpy(smtpConfig.user, [encodedURLString UTF8String]);
    return smtpConfig;
}

- (FOS_SMTPCONFIG)smtpConfig
{
    NSString *encodedURLString;
    _smtpConfig.isEnable = self.smtpEnable;
    _smtpConfig.isNeedAuth = (int)[self.smtpNeedAuth indexOfSelectedItem];
    encodedURLString = [[self.smtpPassword stringValue] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    strcpy(_smtpConfig.password, [encodedURLString UTF8String]);
    _smtpConfig.port = [self.smtpPort intValue];
    NSString *reciever = [NSString stringWithFormat:@"%@,,,",[self.smtpReciever1 stringValue]];
    
    encodedURLString = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,(CFStringRef)reciever,NULL,
                                                                                 CFSTR("!*'();:@&=+$,/?%#[]"),kCFStringEncodingUTF8));
    strcpy(_smtpConfig.reciever, [encodedURLString UTF8String]);
    encodedURLString = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,(CFStringRef)[self.smtpSender stringValue],NULL,CFSTR("!*'();:@&=+$,/?%#[]"),kCFStringEncodingUTF8));
    strcpy(_smtpConfig.sender, [encodedURLString UTF8String]);
    encodedURLString = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,(CFStringRef)[self.smtpServerAddr stringValue],NULL,CFSTR("!*'();:@&=+$,/?%#[]"),kCFStringEncodingUTF8));
    strcpy(_smtpConfig.server, [encodedURLString UTF8String]);
    _smtpConfig.tls = (int)[self.smtpTls indexOfSelectedItem];
    encodedURLString = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,(CFStringRef)[self.smtpUserName stringValue],NULL,CFSTR("!*'();:@&=+$,/?%#[]"),kCFStringEncodingUTF8));
    strcpy(_smtpConfig.user, [encodedURLString UTF8String]);
    
    return _smtpConfig;
}

- (void)setPskFomatter:(XStringFomatter *)pskFomatter
{
    _pskFomatter = pskFomatter;
    [_pskFomatter setMaxLength :63];
    [_pskFomatter setRegex:@"^[a-z0-9A-Z]*$"];
}

- (void)setSmtpAddrFomatter:(XStringFomatter *)smtpAddrFomatter
{
    _smtpAddrFomatter = smtpAddrFomatter;
    [_smtpAddrFomatter setMaxLength :63];
    [_smtpAddrFomatter setRegex:@"^[a-z0-9A-Z@_.-]*$"];
}

- (void)setSmtpPortFomatter:(XStringFomatter *)smtpPortFomatter
{
    _smtpPortFomatter = smtpPortFomatter;
    [_smtpPortFomatter setRegex:@"^[0-9]*$"];
}


- (void)setSmtpUserNameFormatter:(XStringFomatter *)smtpUserNameFormatter
{
    //示例:someone@sample.com
    //用户名的最大长度为63，支持数字、字母及字符@_.$*-
    _smtpUserNameFormatter = smtpUserNameFormatter;
    [_smtpUserNameFormatter setMaxLength :63];
    [_smtpUserNameFormatter setRegex:@"^[0-9a-zA-Z@_.$*-]*$"];
}

//密码的最大长度为16，支持数字、字母及符号~!@#*()_{}:"|<>?`-;'\,./
- (void)setSmtpPasswordFormatter:(XStringFomatter *)smtpPasswordFormatter
{
    _smtpPasswordFormatter = smtpPasswordFormatter;
    [_smtpPasswordFormatter setMaxLength :16];
    //[_smtpPasswordFormatter setValidCharacters:@"0-9a-zA-Z~!@#*()_{}:\"|<>?`-;'\\,./"];
    [_smtpPasswordFormatter setRegex:@"^[0-9a-zA-Z~!@#*()_{}:\",]*$"];
}

@end
