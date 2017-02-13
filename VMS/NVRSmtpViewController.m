//
//  NVRSmtpViewController.m
//  
//
//  Created by mac_dev on 16/5/26.
//
//

#import "NVRSmtpViewController.h"

@interface NVRSmtpViewController ()

@end

@implementation NVRSmtpViewController

#pragma mark - public api
- (void)fetch
{
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FOSCAM_NVR_CONFIG config;
        char xml[OUT_BUFFER_LENGTH] = {0};
        
        config.output = xml;
        config.outputLen = OUT_BUFFER_LENGTH;
        
        BOOL success = NO;
        FOS_SMTPCONFIG smtpConfig;
        
        if ([[DispatchCenter sharedDispatchCenter] getConfig:&config
                                                     forType:FOSCAM_NVR_CONFIG_SMTP
                                                  fromDevice:self.device]) {
            //解析结果
            NSError *err = nil;
            NSString *rawString = [NSString stringWithCString:xml encoding:NSASCIIStringEncoding];
            NSDictionary *dict = [XMLHelper parserCGIXml:rawString error:&err];
            
            if (DEBUG_CGI) {
                NSLog(@"%@",rawString);
            }
            
            if (!err) {
                if ([[dict valueForKey:@"result"] intValue] == 0) {
                    success = YES;
                    smtpConfig.isEnable = [[dict valueForKey:@"isEnable"] intValue];
                    [[dict valueForKey:@"server"] getCString:smtpConfig.server maxLength:128 encoding:NSASCIIStringEncoding];
                    smtpConfig.port = [[dict valueForKey:@"port"] intValue];
                    smtpConfig.isNeedAuth = [[dict valueForKey:@"isNeedAuthen"] intValue];
                    smtpConfig.tls = [[dict valueForKey:@"isEnableSSL"] intValue];
                    [[dict valueForKey:@"username"] getCString:smtpConfig.user maxLength:64 encoding:NSASCIIStringEncoding];
                    [[dict valueForKey:@"password"] getCString:smtpConfig.password maxLength:64 encoding:NSASCIIStringEncoding];
                    [[dict valueForKey:@"sender"] getCString:smtpConfig.sender maxLength:128 encoding:NSASCIIStringEncoding];
                    NSString *receivers = [NSString stringWithFormat:@"%@,%@,%@,%@",
                                           [dict valueForKey:@"reciever1"],
                                           [dict valueForKey:@"reciever2"],
                                           [dict valueForKey:@"reciever3"],
                                           [dict valueForKey:@"reciever4"]];
                    [receivers getCString:smtpConfig.reciever maxLength:256 encoding:NSASCIIStringEncoding];
                }
            }
        }
        
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

- (void)push
{
    int code = [self checkSmtpFmtInvalid];
    
    if (0 == code) {
        [self setActivity:YES];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            //收集控件信息
            FOSCAM_NVR_CONFIG config;
            FOS_SMTPCONFIG smtpConfig = [self smtpConfigFromUI];
            
            NSString *reciever = [NSString stringWithCString:smtpConfig.reciever encoding:NSASCIIStringEncoding];
            NSString *redefineReciever = [self redefineReciver:reciever];
            
            [redefineReciever getCString:smtpConfig.reciever maxLength:256 encoding:NSASCIIStringEncoding];
            
            
            
            char xml[OUT_BUFFER_LENGTH] = {0};
            
            config.input = &smtpConfig;
            config.output = xml;
            config.outputLen = OUT_BUFFER_LENGTH;
            
            BOOL success = NO;
            if ([[DispatchCenter sharedDispatchCenter] setConfig:&config
                                                         forType:FOSCAM_NVR_CONFIG_SMTP
                                                        toDevice:self.device]) {
                //解析结果
                NSError *err = nil;
                NSString *rawString = [NSString stringWithCString:xml encoding:NSASCIIStringEncoding];
                NSLog(@"%@",rawString);
                NSDictionary *values = [XMLHelper parserCGIXml:rawString error:&err];
                
                if (!err) {
                    NSNumber *result = [values valueForKey:KEY_XML_RESULT];
                    success = result && (result.intValue == 0);
                }
            }
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
               info:[self errMsg :code]];
    }
}

- (BOOL)urlNeedEncode
{
    return NO;
}

- (BOOL)performTestSmtp
{
    FOSCAM_NVR_CONFIG config;
    char xml[OUT_BUFFER_LENGTH] = {0};
    
    config.output = xml;
    config.outputLen = OUT_BUFFER_LENGTH;
    
    if ([[DispatchCenter sharedDispatchCenter] getConfig:&config
                                                 forType:FOSCAM_NVR_CONFIG_SMTP_TEST
                                              fromDevice:self.device]) {
        //解析结果
        NSError *err = nil;
        NSString *rawString = [NSString stringWithCString:xml encoding:NSASCIIStringEncoding];
        NSLog(@"%@",rawString);
        NSDictionary *values = [XMLHelper parserCGIXml:rawString error:&err];
        
        if (!err) {
            NSNumber *result = [values valueForKey:@"testResult"];
            return  result && (result.intValue == 0);
        }
    }
    
    return NO;
}

#pragma mark - private
/*
 *该函数的作用是重定义接收者,目的是方便使用c标准接口strtok进行字符串分割
 *e.g src =",,ss,jj"  dst = "#,#,ss,jj",
 */
- (NSString *)redefineReciver :(NSString *)reciver
{
    NSArray *components = [reciver componentsSeparatedByString:@","];
    NSString *result = @"";
    
    for (int i = 0; i < components.count; i++) {
        result = [result stringByAppendingString:[components[i] isEqualToString:@""]?@"#" : components[i]];
        
        if (i != components.count - 1) {
            result = [result stringByAppendingString:@","];
        }
    }
    
    return result;
}

@end
