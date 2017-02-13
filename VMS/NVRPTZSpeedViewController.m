//
//  NVRPTZSpeedViewController.m
//  
//
//  Created by mac_dev on 16/5/30.
//
//

#import "NVRPTZSpeedViewController.h"

@interface NVRPTZSpeedViewController ()

@end

@implementation NVRPTZSpeedViewController

#pragma mark - public api
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
        int speed;
        
        if ([[DispatchCenter sharedDispatchCenter] getConfig:&config
                                                     forType:FOSCAM_NVR_CONFIG_PTZ_SPEED
                                                  fromDevice:self.device]) {
            //解析结果
            NSError *err = nil;
            NSString *rawString = [NSString stringWithCString:xml encoding:NSASCIIStringEncoding];
            NSLog(@"%@",rawString);
            //NSArray *values = [self parserCGIXml:rawString error:&err];
            NSDictionary *dict = [XMLHelper parserCGIXml:rawString error:&err];
            
            if (!err) {
                if ([[dict valueForKey:@""] intValue] == 0) {
                    success = YES;
                    speed = [[dict valueForKey:@"ptzSpeed"] intValue];
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [self setSpeed:speed];
            }
            else [self alert:@"获取PTZ速度失败!" info:@""];
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
        FOS_NVR_PTZ_SPEED nvrPtzSpeed = [self nvrSpeedFromUI];
        char xml[OUT_BUFFER_LENGTH] = {0};
        
        config.input = &nvrPtzSpeed;
        config.output = xml;
        config.outputLen = OUT_BUFFER_LENGTH;
        
        BOOL success = NO;
        if ([[DispatchCenter sharedDispatchCenter] setConfig:&config
                                                     forType:FOSCAM_NVR_CONFIG_PTZ_SPEED
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
            if (!success) [self alert:@"保存PTZ速度失败!" info:@""];
            [self setActivity:NO];
        });
    });
}

- (FOS_NVR_PTZ_SPEED)nvrSpeedFromUI
{
    FOS_NVR_PTZ_SPEED ptzSpeed;
    ptzSpeed.chn = self.chn;
    ptzSpeed.speed = [self ptzSpeedFromUI];
    return ptzSpeed;
}

- (NSString *)description
{
    return NSLocalizedString(@"Pan & Tilt Speed", nil);
}
@end
