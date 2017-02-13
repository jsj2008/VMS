//
//  NVRFtpViewController.m
//  
//
//  Created by mac_dev on 16/5/27.
//
//

#import "NVRFtpViewController.h"

@interface NVRFtpViewController ()

@end

@implementation NVRFtpViewController

- (void)fetch
{
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FOSCAM_NVR_CONFIG config;
        char xml[OUT_BUFFER_LENGTH] = {0};
        
        config.output = xml;
        config.outputLen = OUT_BUFFER_LENGTH;
        
        BOOL success = NO;
        FOS_FTPCONFIG ftpConfig;
        
        if ([[DispatchCenter sharedDispatchCenter] getConfig:&config
                                                     forType:FOSCAM_NVR_CONFIG_FTP
                                                  fromDevice:self.device]) {
            //解析结果
            NSError *err = nil;
            NSString *rawString = [NSString stringWithCString:xml encoding:NSASCIIStringEncoding];
            //NSArray *values = [self parserCGIXml:rawString error:&err];
            NSDictionary *dict = [XMLHelper parserCGIXml:rawString error:&err];
            
            if (DEBUG_CGI) {
                NSLog(@"%@",rawString);
            }
            
            if (!err/* && values.count == 7*/) {
                if ([[dict valueForKey:@"result"] intValue] == 0) {
                    success = YES;
                    ftpConfig.ftpPort = [[dict valueForKey:@"ftpPort"] intValue];
                    [[dict valueForKey:@"ftpAddr"] getCString:ftpConfig.ftpAddr maxLength:32 encoding:NSASCIIStringEncoding];
                    ftpConfig.mode = [[dict valueForKey:@"ftpMode"] intValue];
                    [[dict valueForKey:@"ftpuser"] getCString:ftpConfig.userName maxLength:32 encoding:NSASCIIStringEncoding];
                    [[dict valueForKey:@"ftppwd"] getCString:ftpConfig.password maxLength:64 encoding:NSASCIIStringEncoding];
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success)
                [self setFtpConfig:ftpConfig];
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
        //收集控件信息
        FOSCAM_NVR_CONFIG config;
        FOS_FTPCONFIG ftpConfig = [self ftpConfigFromUI];
        char xml[OUT_BUFFER_LENGTH] = {0};
        
        config.input = &ftpConfig;
        config.output = xml;
        config.outputLen = OUT_BUFFER_LENGTH;
        
        BOOL success = NO;
        if ([[DispatchCenter sharedDispatchCenter] setConfig:&config
                                                     forType:FOSCAM_NVR_CONFIG_FTP
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
                       info:NSLocalizedString(@"time out", nil)];
            [self setActivity:NO];
        });
    });
}

- (BOOL)urlNeedEncode
{
    return NO;
}

- (BOOL)performTestFtp
{
    FOSCAM_NVR_CONFIG config;
    char xml[OUT_BUFFER_LENGTH] = {0};
    
    config.output = xml;
    config.outputLen = OUT_BUFFER_LENGTH;
    
    if ([[DispatchCenter sharedDispatchCenter] getConfig:&config
                                                 forType:FOSCAM_NVR_CONFIG_FTP_TEST
                                              fromDevice:self.device]) {
        //解析结果
        NSError *err = nil;
        NSString *rawString = [NSString stringWithCString:xml encoding:NSASCIIStringEncoding];
        NSLog(@"%@",rawString);
        NSDictionary *values = [XMLHelper parserCGIXml:rawString error:&err];
        
        if (!err) {
            NSNumber *result = [values valueForKey:@"testResult"];
            return result && (result.intValue == 0);
        }
    }
    
    return NO;
}
@end
