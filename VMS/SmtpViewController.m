//
//  SmtpViewController.m
//  
//
//  Created by mac_dev on 16/5/26.
//
//

#import "SmtpViewController.h"
#import "XStringFomatter.h"

@interface SmtpViewController ()

@property (nonatomic,assign) BOOL smtpEnable;
@property (nonatomic,assign) BOOL isNeedAuthen;//use for binding

@property (nonatomic,weak) IBOutlet NSTextField *smtpServerAddr;
@property (nonatomic,weak) IBOutlet NSTextField *smtpPort;
@property (nonatomic,weak) IBOutlet NSPopUpButton *smtpTls;
@property (nonatomic,weak) IBOutlet NSPopUpButton *smtpNeedAuth;
@property (nonatomic,weak) IBOutlet NSTextField *smtpUserName;
@property (nonatomic,weak) IBOutlet NSTextField *smtpPassword;
@property (nonatomic,weak) IBOutlet NSTextField *smtpSender;
@property (nonatomic,weak) IBOutlet NSTextField *smtpReciever1;
@property (nonatomic,weak) IBOutlet NSTextField *smtpReciever2;
@property (nonatomic,weak) IBOutlet NSTextField *smtpReciever3;
@property (nonatomic,weak) IBOutlet NSTextField *smtpReciever4;
@property (nonatomic,weak) IBOutlet NSTextField *smtpTestResult;
@property (nonatomic,weak) IBOutlet NSTextField *smptTip;
@property (nonatomic,weak) IBOutlet XStringFomatter *smtpServerAddrFomatter;
@property (nonatomic,weak) IBOutlet XStringFomatter *smtpUserNameFormatter;
@property (nonatomic,weak) IBOutlet XStringFomatter *smtpPasswordFormatter;
@property (nonatomic,weak) IBOutlet XStringFomatter *smtpReciver1Formatter;
@property (nonatomic,weak) IBOutlet XStringFomatter *smtpReciver2Formatter;
@property (nonatomic,weak) IBOutlet XStringFomatter *smtpReciver3Formatter;
@property (nonatomic,weak) IBOutlet XStringFomatter *smtpReciver4Formatter;
@end

@implementation SmtpViewController
@synthesize smtpTls = _smtpTls;
#pragma mark - public api
- (void)fetch
{
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FOSCAM_NET_CONFIG config;
        FOS_SMTPCONFIG smtpConfig;
        
        config.info = &smtpConfig;
        
        BOOL success = [[DispatchCenter sharedDispatchCenter] getConfig:&config
                                                                forType:FOSCAM_NET_CONFIG_NETWORK_SMTP
                                                             fromDevice:self.device];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success)
                [self setSmtpConfig:smtpConfig];
            else
                [self alert:NSLocalizedString(@"failed to get the settings", nil)
                       info:NSLocalizedString(@"time out",nil)];
            [self setActivity:NO];
        });
    });
}

- (int)checkSmtpFmtInvalid
{
    //检查发件人和收件人的邮箱个格式是否正确
    NSString *regex     = @"^\\w+([-+.]\\w+)*@\\w+([-.]\\w+)*\\.\\w+([-.]\\w+)*$";
    NSString *sender    =  self.smtpSender.stringValue;
    NSArray *recivers   = @[self.smtpReciever1.stringValue,
                            self.smtpReciever2.stringValue,
                            self.smtpReciever3.stringValue,
                            self.smtpReciever4.stringValue];
    
    if (![sender isEqualToString:@""] && ![sender isMatchedByRegex:regex]) {
        return SMTP_SENDER_FMT_ERR;
    }
    
    for (int i = 0; i < recivers.count; i++) {
        NSString *reciver = recivers[i];
        
        if (![reciver isEqualToString:@""] &&
            ![reciver isMatchedByRegex:regex]) {

            return SMTP_RECEIVER_FMT_ERR;
        }
    }
    
    return SMTP_NO_ERR;
}

- (void)push
{
    int code = [self checkSmtpFmtInvalid];
    
    if (0 == code) {
        [self setActivity:YES];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            FOS_SMTPCONFIG smtpConfig = [self smtpConfigFromUI];
            FOSCAM_NET_CONFIG config;
            config.info = &smtpConfig;
            
            BOOL success = [[DispatchCenter sharedDispatchCenter] setConfig:&config
                                                                    forType:FOSCAM_NET_CONFIG_NETWORK_SMTP
                                                                   toDevice:self.device];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!success)
                    [self alert:NSLocalizedString(@"failed to set the settings", nil)
                           info:NSLocalizedString(@"time out",nil)];
                [self setActivity:NO];
            });
        });
    }
    else {
        [self alert:NSLocalizedString(@"failed to set the settings", nil)
               info:[self errMsg:code]];
    }
}

- (NSString *)description
{
    return NSLocalizedString(@"SMTP", nil);
}

- (SVC_OPTION)option
{
    return SVC_REFRESH | SVC_SAVE;
}

- (BOOL)urlNeedEncode
{
    return YES;
}

- (BOOL)performTestSmtp
{
    //NSString *encodedURLString;
    FOS_SMTPCONFIG smtpConfig = [self smtpConfigFromUI];
    FOS_SMTPTEST smtpTest;
    
    //测试
    FOSCAM_NET_CONFIG config;
    FOSCAM_NET_CONFIG_TEST smtpTesInfo;
    DispatchCenter *center = [DispatchCenter sharedDispatchCenter];
    CDevice *device = self.device;
    
    smtpTesInfo.input = &smtpConfig;
    smtpTesInfo.result = &smtpTest;
    config.info = &smtpTesInfo;
    
    if ([center getConfig :&config forType:FOSCAM_NET_CONFIG_NETWORK_SMTP_TEST fromDevice:device]) {
        return smtpTest.testResult == 0;
    }

    return NO;
}
#pragma mark - action
- (IBAction)testSmtp:(id)sender
{
    //准备工作
    [sender setEnabled :NO];
    [self.smptTip setTextColor :[NSColor redColor]];
    [self.smptTip setStringValue:NSLocalizedString(@"Please wait......", nil)];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL success = [self performTestSmtp];
        //更新控件
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *testResult = success? NSLocalizedString(@"success",nil) :NSLocalizedString(@"Failed",nil);
            [self.smtpTestResult setStringValue:testResult];
            [sender setEnabled :YES];
            [self.smptTip setStringValue :@""];
        });
    });
}

#pragma mark - private api
- (void)updateSmtpConfigUI
{
    self.smtpEnable = self.smtpConfig.isEnable;
    self.isNeedAuthen = (self.smtpConfig.isNeedAuth == 1);
    //[self.smtpNeedAuth selectItemWithTag:self.smtpConfig.isNeedAuth];
    [self.smtpPort setIntValue:self.smtpConfig.port];
    [self.smtpTls selectItemWithTag:self.smtpConfig.tls];
    
    //取回的四个收件人以“，”分割
    //SDK bug :存放收件人的地址长度不足
    BOOL isUrlNeedEncode = [self urlNeedEncode];
    NSString *reciever = [NSString stringWithCString:self.smtpConfig.reciever encoding:NSASCIIStringEncoding];
    if (isUrlNeedEncode) {
        reciever = [reciever stringByRemovingPercentEncoding];
    }
    NSArray *recievers = [reciever componentsSeparatedByString:@","];
    for (int i = 0; i < recievers.count; i++) {
        NSTextField *tf = [self valueForKey:[NSString stringWithFormat:@"smtpReciever%d",i+1]];
        [tf setStringValue:[self safetyText:recievers[i]]];
    }
    
    //SDK bug:取回的发件人为空.
    //发件人
    NSString *sender = [NSString stringWithCString:self.smtpConfig.sender encoding:NSASCIIStringEncoding];
    if (isUrlNeedEncode) {
        sender = [sender stringByRemovingPercentEncoding];
    }
    [self.smtpSender setStringValue:[self safetyText:sender]];
    
    //服务器地址
    NSString *server = [NSString stringWithCString:self.smtpConfig.server encoding:NSASCIIStringEncoding];
    if (isUrlNeedEncode) {
        server = [server stringByRemovingPercentEncoding];
    }
    [self.smtpServerAddr setStringValue:[self safetyText:server]];
    
    //用户名
    NSString *user = [NSString stringWithCString:self.smtpConfig.user encoding:NSASCIIStringEncoding];
    if (isUrlNeedEncode) {
        user = [user stringByRemovingPercentEncoding];
    }
    [self.smtpUserName setStringValue:[self safetyText:user]];
    
    //密码
    NSString *psw = [NSString stringWithCString:self.smtpConfig.password encoding:NSASCIIStringEncoding];
    if (isUrlNeedEncode) {
        psw = [psw stringByRemovingPercentEncoding];
    }
    [self.smtpPassword setStringValue:[self safetyText:psw]];
}

- (FOS_SMTPCONFIG)smtpConfigFromUI
{
    //对于服务器地址、发件人、收件人、用户名这些URL，统一需要编码
    FOS_SMTPCONFIG smtpConfig;
    BOOL isUrlNeedEncode = [self urlNeedEncode];
    
    smtpConfig.isEnable = self.smtpEnable;
    smtpConfig.isNeedAuth = (int)[self.smtpNeedAuth indexOfSelectedItem];
    smtpConfig.port = [self.smtpPort intValue];
    smtpConfig.tls = (int)[self.smtpTls indexOfSelectedItem];

    //收件人
    NSString *reciever = [NSString stringWithFormat:@"%@,%@,%@,%@",
                          [self.smtpReciever1 stringValue],
                          [self.smtpReciever2 stringValue],
                          [self.smtpReciever3 stringValue],
                          [self.smtpReciever4 stringValue]];
    
    
    if (isUrlNeedEncode) {
        reciever = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,(CFStringRef)reciever,NULL,
                                                                             CFSTR("!*'();:@&=+$,/?%#[]"),kCFStringEncodingUTF8));
    }
    
    [reciever getCString:smtpConfig.reciever maxLength:256 encoding:NSASCIIStringEncoding];
    
    //发件人
    NSString *sender = self.smtpSender.stringValue;
    if (isUrlNeedEncode) {
        sender = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,(CFStringRef)sender,NULL,CFSTR("!*'();:@&=+$,/?%#[]"),kCFStringEncodingUTF8));
    }
    [sender getCString:smtpConfig.sender maxLength:128 encoding:NSASCIIStringEncoding];
    
    //服务器地址
    NSString *server = self.smtpServerAddr.stringValue;
    if (isUrlNeedEncode) {
        server = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,(CFStringRef)server,NULL,CFSTR("!*'();:@&=+$,/?%#[]"),kCFStringEncodingUTF8));
    }
    [server getCString:smtpConfig.server maxLength:128 encoding:NSASCIIStringEncoding];
   
    //用户名
    NSString *user = self.smtpUserName.stringValue;
    if (isUrlNeedEncode) {
        user = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,(CFStringRef)user,NULL,CFSTR("!*'();:@&=+$,/?%#[]"),kCFStringEncodingUTF8));
    }
    [user getCString:smtpConfig.user maxLength:64 encoding:NSASCIIStringEncoding];
    
    //密码
    NSString *psw = self.smtpPassword.stringValue;
    if (isUrlNeedEncode) {
        psw = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,(CFStringRef)psw,NULL,CFSTR("!*'();:@&=+$,/?%#[]"),kCFStringEncodingUTF8));
    }
    [psw getCString:smtpConfig.password maxLength:64 encoding:NSASCIIStringEncoding];
    return smtpConfig;
}

- (SMTP_ERR)parserSmptConfig
{
    return SMTP_NO_ERR;
}

- (NSString *)errMsg :(SMTP_ERR)code
{
    switch (code) {
        case SMTP_NO_ERR:
            return NSLocalizedString(@"success", nil);
            
        case SMTP_SERVER_FMT_ERR:
            return NSLocalizedString(@"server format error", nil);

        case SMTP_PORT_ERR:
            return NSLocalizedString(@"invalid port", nil);
            
        case SMTP_USER_NAME_FMT_ERR:
            return NSLocalizedString(@"usrename format error", nil);
            
        case SMTP_USER_PSW_FMT_ERR:
            return NSLocalizedString(@"password format error", nil);
            
        case SMTP_SENDER_FMT_ERR:
            return NSLocalizedString(@"sender format error", nil);
            
        case SMTP_RECEIVER_FMT_ERR:
            return NSLocalizedString(@"receiver format error", nil);
            
        default:
            return NSLocalizedString(@"unknow error", nil);
    }
}
#pragma mark - setter & getter
- (void)setSmtpConfig:(FOS_SMTPCONFIG)smtpConfig
{
    _smtpConfig = smtpConfig;
    [self updateSmtpConfigUI];
}

- (void)setSmtpServerAddrFomatter:(XStringFomatter *)smtpServerAddrFomatter
{
    _smtpServerAddrFomatter = smtpServerAddrFomatter;
    [_smtpServerAddrFomatter setMaxLength :63];
    [_smtpServerAddrFomatter setRegex:@"^[a-z0-9A-Z@_.\\-]*$"];
}

//示例:someone@sample.com
//用户名的最大长度为63，支持数字、字母及字符@_.$*-
- (void)setSmtpFmt :(XStringFomatter *)fmt
{
    [fmt setMaxLength :63];
    [fmt setRegex:@"^[0-9a-zA-Z@_.$*\\-]*$"];
}

- (void)setSmtpUserNameFormatter:(XStringFomatter *)smtpUserNameFormatter
{
    _smtpUserNameFormatter = smtpUserNameFormatter;
    [self setSmtpFmt:_smtpUserNameFormatter];
}

- (void)setSmtpReciver1Formatter:(XStringFomatter *)fmt
{
    _smtpReciver1Formatter = fmt;
    [self setSmtpFmt:_smtpReciver1Formatter];
}

- (void)setSmtpReciver2Formatter:(XStringFomatter *)fmt
{
    _smtpReciver2Formatter = fmt;
    [self setSmtpFmt:_smtpReciver2Formatter];
}

- (void)setSmtpReciver3Formatter:(XStringFomatter *)fmt
{
    _smtpReciver3Formatter = fmt;
    [self setSmtpFmt:_smtpReciver3Formatter];
}

- (void)setSmtpReciver4Formatter:(XStringFomatter *)fmt
{
    _smtpReciver4Formatter = fmt;
    [self setSmtpFmt:_smtpReciver4Formatter];
}

//密码的最大长度为16，支持数字、字母及符号~!@#*()_{}:"|<>?`-;'\,./
- (void)setSmtpPasswordFormatter:(XStringFomatter *)smtpPasswordFormatter
{
    _smtpPasswordFormatter = smtpPasswordFormatter;
    [_smtpPasswordFormatter setMaxLength :16];
    [_smtpPasswordFormatter setRegex:@"^[0-9a-zA-Z!-#'-*,-/:-<>-@~{-}`_\\\\]*$"];
}
@end
