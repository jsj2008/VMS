//
//  NVRScheduleRecordViewController.m
//  
//
//  Created by mac_dev on 16/6/1.
//
//

#import "NVRScheduleRecordViewController.h"

@interface NVRScheduleRecordViewController ()
@end

@implementation NVRScheduleRecordViewController

- (void)fetch
{
    [self setActivity:YES];
    __block int chn = self.chn;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FOSCAM_NVR_CONFIG config;
        char xml[OUT_BUFFER_LENGTH] = {0};
        
        config.input = &chn;
        config.output = xml;
        config.outputLen = OUT_BUFFER_LENGTH;
        
        BOOL success = NO;
        FOS_SCHEDULERECORDCONFIG scheduleRecordCfg;
        
        if ([[DispatchCenter sharedDispatchCenter] getConfig:&config
                                                     forType:FOSCAM_NVR_CONFIG_RECORD_SCHEDULE
                                                  fromDevice:self.device]) {
            //解析结果
            NSError *err = nil;
            NSString *rawString = [NSString stringWithCString:xml encoding:NSASCIIStringEncoding];
            NSLog(@"%@",rawString);
            //NSArray *values = [self parserCGIXml:rawString error:&err];
            NSDictionary *dict = [XMLHelper parserCGIXml:rawString error:&err];
            
            if (!err) {
                if ([[dict valueForKey:@"result"] intValue] == 0) {
                    success = YES;
                    scheduleRecordCfg.isEnable = [[dict valueForKey:@"isEnable"] intValue];
                    for (int i = 0; i < FOS_MAX_SCHEDULE_COUNT; i++) {
                        scheduleRecordCfg.schedules[i] = [[dict valueForKey:[NSString stringWithFormat:@"schedule%d",i]] longLongValue];
                    }
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [self setScheduleRecordConfig:scheduleRecordCfg];
            }
            else [self alert:@"获取计划录像设置失败!" info:@""];
            [self setActivity:NO];
        });
    });
}

- (void)push
{
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //收集控件信息
        
        FOS_NVR_SCHEDULERECORDCONFIG nvrScheduleRecordCfg;
        
        nvrScheduleRecordCfg.scheduleRecordCfg = [self scheduleRecordConfigFromUI];
        nvrScheduleRecordCfg.chn = self.chn;
       
        FOSCAM_NVR_CONFIG config;
        char xml[OUT_BUFFER_LENGTH] = {0};
        
        config.input = &nvrScheduleRecordCfg;
        config.output = xml;
        config.outputLen = OUT_BUFFER_LENGTH;
        
        BOOL success = NO;
        if ([[DispatchCenter sharedDispatchCenter] setConfig:&config
                                                     forType:FOSCAM_NVR_CONFIG_RECORD_SCHEDULE
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
            if (!success) [self alert:@"保存计划录像设置失败!" info:@""];
            [self setActivity:NO];
        });
    });
}
@end
