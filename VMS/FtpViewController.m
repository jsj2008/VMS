//
//  FtpViewController.m
//  
//
//  Created by mac_dev on 16/5/26.
//
//

#import "FtpViewController.h"
#import "XStringFomatter.h"

@interface FtpViewController ()

@property (nonatomic,weak) IBOutlet NSTextField *ftpAddr;
@property (nonatomic,weak) IBOutlet NSTextField *ftpPort;
@property (nonatomic,weak) IBOutlet NSPopUpButton *ftpMode;
@property (nonatomic,weak) IBOutlet NSTextField *ftpUserName;
@property (nonatomic,weak) IBOutlet NSTextField *ftpPassword;
@property (nonatomic,weak) IBOutlet NSTextField *ftpTip;
@property (nonatomic,weak) IBOutlet NSTextField *ftpTestResult;
@property (nonatomic,weak) IBOutlet XStringFomatter *ftpAddrFmt;
@property (nonatomic,weak) IBOutlet XStringFomatter *ftpUserFmt;
@property (nonatomic,weak) IBOutlet XStringFomatter *ftpPswFmt;
@property (nonatomic,weak) IBOutlet XStringFomatter *ftpPortFmt;

@end

@implementation FtpViewController

#pragma mark - public api
- (void)fetch
{
    [self setActivity:YES];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FOSCAM_NET_CONFIG config;
        FOS_FTPCONFIG ftpConfig;
        config.info = &ftpConfig;
        BOOL success = [[DispatchCenter sharedDispatchCenter] getConfig:&config
                                                                forType:FOSCAM_NET_CONFIG_NETWORK_FTP
                                                             fromDevice:self.device];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success)
                [self setFtpConfig :ftpConfig];
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
        FOS_FTPCONFIG ftpConfig = [self ftpConfigFromUI];
        config.info = &ftpConfig;
        BOOL success = [[DispatchCenter sharedDispatchCenter] setConfig:&config
                                                                forType:FOSCAM_NET_CONFIG_NETWORK_FTP
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
    return NSLocalizedString(@"FTP", nil);
}

- (SVC_OPTION)option
{
    return SVC_REFRESH | SVC_SAVE;
}

- (BOOL)urlNeedEncode
{
    return YES;
}

- (BOOL)performTestFtp
{
    FOS_FTPCONFIG ftpConfig = [self ftpConfigFromUI];//self.ftpConfig;
    FOS_TESTFTPSERVER ftpTest;
    FOSCAM_NET_CONFIG_TEST testInfo;
    FOSCAM_NET_CONFIG config;
    
    testInfo.input = &ftpConfig;
    testInfo.result = &ftpTest;
    config.info = &testInfo;
    
    
    if ([[DispatchCenter sharedDispatchCenter] getConfig:&config
                                                 forType:FOSCAM_NET_CONFIG_NETWORK_FTP_TEST
                                              fromDevice:self.device]) {
        return (ftpTest.testResult == 0);
    }
    
    return NO;
}

#pragma mark - action
- (IBAction)testFtp:(id)sender
{
    //准备工作
    [sender setEnabled :NO];
    [self.ftpTip setTextColor :[NSColor redColor]];
    [self.ftpTip setStringValue:NSLocalizedString(@"Please wait......", nil)];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL success = [self performTestFtp];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *testResult = success? NSLocalizedString(@"success", nil) :NSLocalizedString(@"Failed", nil);
            [self.ftpTestResult setStringValue:testResult];
            [sender setEnabled :YES];
            [self.ftpTip setStringValue :@""];
        });
    });
}

#pragma mark - private api
- (void)updateFtpUI
{
    [self.ftpPort setStringValue:[NSString stringWithFormat:@"%u",self.ftpConfig.ftpPort]];
    [self.ftpMode selectItemAtIndex:self.ftpConfig.mode];
    
    BOOL isUrlNeedEncode = [self urlNeedEncode];
    //FtpAddr
    NSString *ftpAddr = [NSString stringWithCString:self.ftpConfig.ftpAddr encoding:NSASCIIStringEncoding];
    
    if (isUrlNeedEncode) {
        ftpAddr = [ftpAddr stringByRemovingPercentEncoding];
    }
   
    [self.ftpAddr setStringValue:[self safetyText:ftpAddr]];
    
    //UserName
    NSString *ftpUser = [NSString stringWithCString:self.ftpConfig.userName encoding:NSASCIIStringEncoding];
    if (isUrlNeedEncode) {
        ftpUser = [ftpUser stringByRemovingPercentEncoding];
    }
    [self.ftpUserName setStringValue:[self safetyText:ftpUser]];
    
    //Password
    NSString *ftpPsw = [NSString stringWithCString:self.ftpConfig.password encoding:NSASCIIStringEncoding];
    if (isUrlNeedEncode) {
        ftpPsw = [ftpPsw stringByRemovingPercentEncoding];
    }
    [self.ftpPassword setStringValue:[self safetyText:ftpPsw]];
}

- (FOS_FTPCONFIG)ftpConfigFromUI
{
    FOS_FTPCONFIG ftpCfg;
    ftpCfg.ftpPort = [self.ftpPort intValue];
    ftpCfg.mode = (int)[self.ftpMode indexOfSelectedItem];
    
    BOOL isUrlNeedEncode = [self urlNeedEncode];
    //ftp Addr
    NSString *ftpAddr = self.ftpAddr.stringValue;
    if (isUrlNeedEncode) {
        ftpAddr = [ftpAddr stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    }
    [ftpAddr getCString:ftpCfg.ftpAddr maxLength:FTPADDR_LEN encoding:NSASCIIStringEncoding];
   
    //ftp user
    NSString *ftpUser = self.ftpUserName.stringValue;
    if (isUrlNeedEncode) {
        ftpUser = [ftpUser stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    }
    [ftpUser getCString:ftpCfg.userName maxLength:32 encoding:NSASCIIStringEncoding];
    
    //ftp password
    NSString *ftpPsw = self.ftpPassword.stringValue;
    if (isUrlNeedEncode) {
        ftpPsw = [ftpPsw stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    }
    [ftpPsw getCString:ftpCfg.password maxLength:64 encoding:NSASCIIStringEncoding];
    
    return ftpCfg;
}
#pragma mark - data
- (NSArray *)ftpModes
{
    return @[NSLocalizedString(@"PASV", nil),
             NSLocalizedString(@"PORT", nil)];
}

#pragma mark setter && getter
- (void)setFtpConfig:(FOS_FTPCONFIG)ftpConfig
{
    _ftpConfig = ftpConfig;
    [self updateFtpUI];
}

- (void)setFtpMode:(NSPopUpButton *)ftpMode
{
    _ftpMode = ftpMode;
    [self setControl:_ftpMode withTitles:[self ftpModes]];
}

//用户名的最大长度位63,支持数字、字母及符号_@$*-,.#!
- (void)setFtpUserFmt:(XStringFomatter *)ftpUserFmt
{
    _ftpUserFmt = ftpUserFmt;
    [_ftpUserFmt setMaxLength :63];
    [_ftpUserFmt setRegex:@"^[0-9a-zA-Z_@$*\\-,.#!]*$"];
}

//密码的最大长度为63，支持数字及符号 ～！@＃$%^*()_+{}:"|<>?`-;'\,./
- (void)setFtpPswFmt:(XStringFomatter *)ftpPswFmt
{
    _ftpPswFmt = ftpPswFmt;
    [_ftpPswFmt setMaxLength :63];
    [_ftpPswFmt setRegex:@"^[0-9a-zA-Z!-%'-/:-<>-@{-~^-`\\\\]*$"];
}

//ftp地址的最大长度为127，不支持&=
- (void)setFtpAddrFmt:(XStringFomatter *)ftpAddrFmt
{
    _ftpAddrFmt = ftpAddrFmt;
    [_ftpAddrFmt setMaxLength :127];
    [_ftpAddrFmt setCharSet:[NSCharacterSet characterSetWithCharactersInString:@"&="]];
    [_ftpAddrFmt setNegate:YES];
}

//ftp端口的最大长度5，支持数字
- (void)setFtpPortFmt:(XStringFomatter *)ftpPortFmt
{
    _ftpPortFmt = ftpPortFmt;
    [_ftpPortFmt setMaxLength :5];
    [_ftpPortFmt setRegex:@"^[0-9]*$"];
}
@end
