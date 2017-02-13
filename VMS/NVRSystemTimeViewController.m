//
//  NVRSystemTimeViewController.m
//  
//
//  Created by mac_dev on 16/5/25.
//
//

#import "NVRSystemTimeViewController.h"

@interface NVRSystemTimeViewController ()

@end

@implementation NVRSystemTimeViewController

#pragma mark - life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
}

#pragma mark - public api
- (BOOL)gmt
{
    return YES;
}

- (void)fetch
{
    [self setActivity:YES];
    
    DispatchCenter *center = [DispatchCenter sharedDispatchCenter];
    CDevice *device = self.device;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        char xml[OUT_BUFFER_LENGTH] = {0};
        FOSCAM_NVR_CONFIG config;
        BOOL syncIPCTime = NO;
        config.output = xml;
        config.outputLen = OUT_BUFFER_LENGTH;
        
        BOOL success = NO;
        FOS_DEVSYSTEMTIME devSystemTime;
        if ([center getConfig:&config forType:FOSCAM_NVR_CONFIG_DEVICE_SYSTEM_TIME fromDevice:device]) {
            //解析结果
            NSError *err = nil;
            NSString *rawString = [NSString stringWithCString:xml encoding:NSASCIIStringEncoding];
            NSDictionary *dict = [XMLHelper parserCGIXml:rawString error:&err];
            
            if (DEBUG_CGI) {
                NSLog(@"%@",rawString);
            }
            
            if (!err) {
                if (0 == [[dict valueForKey:@"result"] intValue]) {
                    devSystemTime.timeSource = ![[dict valueForKey:@"timeSource"] intValue];
                    [[dict valueForKey:@"ntpServer"] getCString:devSystemTime.ntpServer maxLength:FOS_NTPSERVER_LEN encoding:NSASCIIStringEncoding];
                    devSystemTime.dateFormat = [[dict valueForKey:@"dateFormat"] intValue];
                    //这里的时间格式与ipc参数正好相反
                    int tmp = [[dict valueForKey:@"timeFormat"] intValue];
                    devSystemTime.timeFormat = (tmp == 0)? 1 : 0;
                    devSystemTime.timeZone = [[dict valueForKey:@"timeZone"] intValue];
                    devSystemTime.year = [[dict valueForKey:@"year"] intValue];
                    devSystemTime.mon = [[dict valueForKey:@"month"] intValue];
                    devSystemTime.day = [[dict valueForKey:@"day"] intValue];
                    devSystemTime.hour = [[dict valueForKey:@"hour"] intValue];
                    devSystemTime.minute = [[dict valueForKey:@"min"] intValue];
                    devSystemTime.sec = [[dict valueForKey:@"sec"] intValue];
                    devSystemTime.isDst = [[dict valueForKey:@"isDst"] intValue];
                    devSystemTime.dst = [[dict valueForKey:@"dst"] intValue];
                    syncIPCTime = ([[dict valueForKey:@"syncIPCTime"] intValue] == 1);
                    success = YES;
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [self setDeviceSystemTime:devSystemTime];
                [self.syncIPCTimeBtn setState:syncIPCTime];
                [self.timeUpdate fire];
            } else
                [self alert:@"获取设备时间失败!" info:@""];
            
            [self setActivity:NO];
        });
    });
}

- (void)push
{
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FOSCAM_NVR_CONFIG nvrCfg;
        //FOS_DEVSYSTEMTIME sysTime = [self devSysTimeFromUI];
        FOS_NVR_DEVSYSTEMTIME nvrSysTime;
        
        char xml[OUT_BUFFER_LENGTH] = {0};
        
        nvrSysTime.devSystemTime = [self devSysTimeFromUI];
        nvrSysTime.syncIPCTime = (self.syncIPCTimeBtn.state == NSOnState);
        nvrCfg.input = &nvrSysTime;
        nvrCfg.output = xml;
        nvrCfg.outputLen = OUT_BUFFER_LENGTH;
        
        BOOL success = NO;
        if ([[DispatchCenter sharedDispatchCenter] setConfig:&nvrCfg
                                                     forType:FOSCAM_NVR_CONFIG_DEVICE_SYSTEM_TIME
                                                    toDevice:self.device]) {
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
            if (success)
                [self fetch];
            else
                [self alert:@"保存设备时间失败!" info:@"超时"];
            
            [self setActivity:NO];
        });
    });
}

- (FOS_DEVSYSTEMTIME)devSysTimeFromUI
{
    FOS_DEVSYSTEMTIME sysTime = [super devSysTimeFromUI];
   
    sysTime.timeFormat = 1 - sysTime.timeFormat;
    return sysTime;
}

@end
