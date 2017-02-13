//
//  DDNSViewController.m
//  
//
//  Created by mac_dev on 16/5/27.
//
//

#import "DDNSViewController.h"
#import "XStringFomatter.h"

@interface DDNSViewController ()

@property (nonatomic,assign) BOOL ddnsEnable;
@property (nonatomic,assign) BOOL serverEnable;
@property (nonatomic,weak) IBOutlet NSTextField *factoryDDNS;
@property (nonatomic,weak) IBOutlet NSPopUpButton *ddnsServer;
@property (nonatomic,weak) IBOutlet NSTextField *hostName;
@property (nonatomic,weak) IBOutlet NSTextField *ddnsUserName;
@property (nonatomic,weak) IBOutlet NSTextField *ddnsPassword;
@property (nonatomic,weak) IBOutlet XStringFomatter *ddnsUserNameFmt;
@property (nonatomic,weak) IBOutlet XStringFomatter *ddnsPasswordFmt;
@property (nonatomic,weak) IBOutlet NSButton *restoreToFactoryBtn;
@end

@implementation DDNSViewController

#pragma mark - public api
- (void)fetch
{
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FOSCAM_NET_CONFIG config;
        FOS_DDNSCONFIG ddnsConfig;
        
        config.info = &ddnsConfig;
        BOOL success = [[DispatchCenter sharedDispatchCenter] getConfig:&config
                                                                forType:FOSCAM_NET_CONFIG_NETWORK_DDNS
                                                             fromDevice:self.device];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success)
                [self setDdnsConfig :ddnsConfig];
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
        FOSCAM_NET_CONFIG config;
        FOS_DDNSCONFIG ddnsConfig = [self ddnsConfigFromUI];
        
        config.info = &ddnsConfig;
        BOOL success = [[DispatchCenter sharedDispatchCenter] setConfig:&config
                                                                forType:FOSCAM_NET_CONFIG_NETWORK_DDNS
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
    return NSLocalizedString(@"DDNS", nil);
}

- (SVC_OPTION)option
{
    return SVC_REFRESH | SVC_SAVE;
}

- (BOOL)urlNeedEncode
{
    return YES;
}

- (BOOL)hideRestoreToFactory
{
    return NO;
}

/*- (BOOL)performRestoreToFactory
{
    FOS_DDNSCONFIG ddnsCfg = [self ddnsConfigFromUI];
    
    ddnsCfg.isEnable = 1;
    ddnsCfg.ddnsServer = 0;
    memset(ddnsCfg.hostName, 0, HOSTNAME_LEN);
    memset(ddnsCfg.user,0,USER_LEN);
    memset(ddnsCfg.password, 0, PASSWORD_LEN);
    
    FOSCAM_NET_CONFIG config;
    config.info = &ddnsCfg;
    return [[DispatchCenter sharedDispatchCenter] setConfig:&config
                                                    forType:FOSCAM_NET_CONFIG_NETWORK_DDNS
                                                   toDevice:self.device];
}*/

#pragma mark - life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.restoreToFactoryBtn.hidden = [self hideRestoreToFactory];
}

#pragma mark - action
- (IBAction)restoreToFactory:(id)sender
{
    //恢复到出厂设置
    self.hostName.stringValue = @"";
    self.ddnsUserName.stringValue = @"";
    self.ddnsUserName.stringValue = @"";
    self.serverEnable = NO;
    
    [self.ddnsServer selectItemAtIndex:0];
    [self push];
    
    
    /*[self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL success = [self performRestoreToFactory];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) [self fetch];
            else [self alert:@"恢复出厂设置失败!"];
            [self setActivity:NO];
        });
    });*/
}

- (IBAction)ddnsServerOption:(id)sender
{
    NSPopUpButton *server = (NSPopUpButton *)sender;
    self.serverEnable = server.indexOfSelectedItem > 0;
    [self updateServerUI];
}

#pragma mark - data
- (NSArray *)ddnsServers
{
    return @[NSLocalizedString(@"None", nil),
             NSLocalizedString(@"oray", nil),
             @"3322",
             @"no-ip",
             @"DynDns"];
}

#pragma mark - private api
- (void)updateServerUI
{
    if (self.ddnsServer.indexOfSelectedItem == self.ddnsConfig.ddnsServer) {
        BOOL    isUrlNeedEncode = [self urlNeedEncode];
        NSArray *tfs = @[self.hostName,self.ddnsUserName,self.ddnsPassword];
        char    *cStrs[3] = {self.ddnsConfig.hostName,self.ddnsConfig.user,self.ddnsConfig.password};
        
        for (int i = 0; i < 3; i++) {
            NSString *ocStr = [NSString stringWithCString:cStrs[i] encoding:NSASCIIStringEncoding];
            if (isUrlNeedEncode) {
                ocStr = [ocStr stringByRemovingPercentEncoding];
            }
            
            [tfs[i] setStringValue:[self safetyText:ocStr]];
        }
    }
    else {
        [self.hostName setStringValue:@""];
        [self.ddnsUserName setStringValue:@""];
        [self.ddnsPassword setStringValue:@""];
    }
}

- (void)updateDDNSUI
{
    [self.factoryDDNS setStringValue:[self safetyText:[NSString stringWithCString:self.ddnsConfig.factoryDDNS encoding:NSASCIIStringEncoding]]];
    [self.ddnsServer selectItemAtIndex:self.ddnsConfig.ddnsServer];
    self.ddnsEnable = self.ddnsConfig.isEnable;
    self.serverEnable = self.ddnsConfig.ddnsServer > 0;
    
    BOOL isUrlNeedEncode = [self urlNeedEncode];
    //host name
    NSString *hostName = [NSString stringWithCString:self.ddnsConfig.hostName encoding:NSASCIIStringEncoding];
    if (isUrlNeedEncode) {
        hostName = [hostName stringByRemovingPercentEncoding];
    }
    [self.hostName setStringValue:[self safetyText:hostName]];
    [self updateServerUI];
}

- (FOS_DDNSCONFIG)ddnsConfigFromUI
{
    FOS_DDNSCONFIG ddnsCfg = self.ddnsConfig;
    
    [self.factoryDDNS.stringValue getCString:ddnsCfg.factoryDDNS maxLength:64 encoding:NSASCIIStringEncoding];
    ddnsCfg.ddnsServer = (int)[self.ddnsServer indexOfSelectedItem];
    ddnsCfg.isEnable = self.ddnsEnable;
    
    BOOL isUrlNeedEncode = [self urlNeedEncode];
    //host name
    NSString *hostName = self.hostName.stringValue;
    if (isUrlNeedEncode) {
        hostName = [hostName stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    }
    [hostName getCString:ddnsCfg.hostName maxLength:HOSTNAME_LEN encoding:NSASCIIStringEncoding];
    
    //ddns username
    NSString *ddnsUserName = self.ddnsUserName.stringValue;
    if (isUrlNeedEncode) {
        ddnsUserName = [ddnsUserName stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    }
    [ddnsUserName getCString:ddnsCfg.user maxLength:USER_LEN encoding:NSASCIIStringEncoding];
    
    //ddns password
    NSString *ddnsPassword = self.ddnsPassword.stringValue;
    if (isUrlNeedEncode) {
        ddnsPassword = [ddnsPassword stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    }
    [ddnsPassword getCString:ddnsCfg.password maxLength:PASSWORD_LEN encoding:NSASCIIStringEncoding];
    
    return ddnsCfg;
}
#pragma mark setter && getter
- (void)setDdnsConfig:(FOS_DDNSCONFIG)ddnsConfig
{
    _ddnsConfig = ddnsConfig;
    [self updateDDNSUI];
}

- (void)setDdnsServer:(NSPopUpButton *)ddnsServer
{
    _ddnsServer = ddnsServer;
    [self setControl:_ddnsServer withTitles:[self ddnsServers]];
}

//用户名的最大长度为20,支持数字、字母及符号@.$*-_:"|
- (void)setDdnsUserNameFmt:(XStringFomatter *)ddnsUserNameFmt
{
    _ddnsUserNameFmt = ddnsUserNameFmt;
    [_ddnsUserNameFmt setMaxLength:20];
    [_ddnsUserNameFmt setRegex:@"^[0-9a-zA-Z@.$*\\-_]*$"];
}

//密码的最大长度为12，支持数字、字母及符号~!@#$%^&*()_+{}<>?`-;'\,./
- (void)setDdnsPasswordFmt:(XStringFomatter *)ddnsPasswordFmt
{
    _ddnsPasswordFmt = ddnsPasswordFmt;
    [_ddnsPasswordFmt setMaxLength:12];
    [_ddnsPasswordFmt setRegex:@"^[0-9a-zA-Z~!@#$%^&*()_+{}<>?`;',./\\-\\\\]*$"];
}
@end
