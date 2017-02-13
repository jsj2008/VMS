//
//  NVRDDNSViewController.m
//  
//
//  Created by mac_dev on 16/5/27.
//
//

#import "NVRDDNSViewController.h"

@interface NVRDDNSViewController ()

@end

@implementation NVRDDNSViewController

- (void)fetch
{
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FOSCAM_NVR_CONFIG config;
        char xml[OUT_BUFFER_LENGTH] = {0};
        
        config.output = xml;
        config.outputLen = OUT_BUFFER_LENGTH;
        
        BOOL success = NO;
        FOS_DDNSCONFIG ddnsConfig;
        
        if ([[DispatchCenter sharedDispatchCenter] getConfig:&config
                                                     forType:FOSCAM_NVR_CONFIG_DDNS
                                                  fromDevice:self.device]) {
            //解析结果
            NSError *err = nil;
            NSString *rawString = [NSString stringWithCString:xml encoding:NSASCIIStringEncoding];
            //NSArray *values = [self parserCGIXml:rawString error:&err];
            NSDictionary *dict = [XMLHelper parserCGIXml:rawString error:&err];
            
            if (DEBUG_CGI) {
                NSLog(@"%@",rawString);
            }
            
            if (!err /*&& values.count == 8*/) {
                if ([[dict valueForKey:@"result"] intValue] == 0) {
                    success = YES;
                    ddnsConfig.isEnable = [[dict valueForKey:@"isEnable"] intValue];
                    [[dict valueForKey:@"hostName"] getCString:ddnsConfig.hostName maxLength:32 encoding:NSASCIIStringEncoding];
                    ddnsConfig.ddnsServer = [[dict valueForKey:@"server"] intValue];
                    [[dict valueForKey:@"userName"] getCString:ddnsConfig.user maxLength:32 encoding:NSASCIIStringEncoding];
                    [[dict valueForKey:@"passWord"] getCString:ddnsConfig.password maxLength:64 encoding:NSASCIIStringEncoding];
                    [[dict valueForKey:@"factoryddns"] getCString:ddnsConfig.factoryDDNS maxLength:64 encoding:NSASCIIStringEncoding];
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success)
                [self setDdnsConfig:ddnsConfig];
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
        FOS_DDNSCONFIG ftpConfig = [self ddnsConfigFromUI];
        char xml[OUT_BUFFER_LENGTH] = {0};
        
        config.input = &ftpConfig;
        config.output = xml;
        config.outputLen = OUT_BUFFER_LENGTH;
        
        BOOL success = NO;
        if ([[DispatchCenter sharedDispatchCenter] setConfig:&config
                                                     forType:FOSCAM_NVR_CONFIG_DDNS
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

- (BOOL)hideRestoreToFactory
{
    return YES;
}


@end
