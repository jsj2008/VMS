//
//  OtherAlarmViewController.m
//  
//
//  Created by mac_dev on 16/6/1.
//
//

#import "OtherAlarmViewController.h"

@interface OtherAlarmViewController ()
@property(nonatomic,weak) IBOutlet NSPopUpButton *alarmTypesBtn;
@property(nonatomic,assign) int curAlarmType;
@property(nonatomic,assign) BOOL buzzer;
@end

@implementation OtherAlarmViewController

#pragma mark - public api
- (void)fetch
{
    [self performFetchAlarmConfigWithType:0];
}

- (void)push
{
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //收集控件信息
        FOS_NVR_OTHER_ALARM_CONFIG otherAlarmCfg = [self alarmConfigFromUI];
        FOSCAM_NVR_CONFIG config;
        char xml[OUT_BUFFER_LENGTH] = {0};
        
        config.input = &otherAlarmCfg;
        config.output = xml;
        config.outputLen = OUT_BUFFER_LENGTH;
        
        BOOL success = NO;
        if ([[DispatchCenter sharedDispatchCenter] setConfig:&config
                                                     forType:FOSCAM_NVR_CONFIG_OTHER_ALARM
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
            if (!success) [self alert:NSLocalizedString(@"failed to set the settings", nil)
                                 info:NSLocalizedString(@"time out", nil)];
            [self setActivity:NO];
        });
    });
}

- (NSString *)description
{
    return NSLocalizedString(@"Other Alarm", nil);
}

- (SVC_OPTION)option
{
    return SVC_REFRESH | SVC_SAVE;
}

- (void)performFetchAlarmConfigWithType :(int)type
{
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int alarmType = type;
        FOSCAM_NVR_CONFIG config;
        char xml[OUT_BUFFER_LENGTH] = {0};
        
        config.input = &alarmType;
        config.output = xml;
        config.outputLen = OUT_BUFFER_LENGTH;
        
        BOOL success = NO;
        FOS_NVR_OTHER_ALARM_CONFIG  otherAlarmCfg;
        if ([[DispatchCenter sharedDispatchCenter] getConfig:&config
                                                     forType:FOSCAM_NVR_CONFIG_OTHER_ALARM
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
                    otherAlarmCfg.alarmType = alarmType;
                    otherAlarmCfg.buzzer = [[dict valueForKey:@"buzzer"] intValue];
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [self setOtherAlarmConfig:otherAlarmCfg];
            }
            else
                [self alert:NSLocalizedString(@"failed to get the settings", nil)
                       info:NSLocalizedString(@"time out", nil)];
            [self setActivity:NO];
        });
    });
}

- (FOS_NVR_OTHER_ALARM_CONFIG)alarmConfigFromUI
{
    FOS_NVR_OTHER_ALARM_CONFIG alarmCfg;
    
    alarmCfg.alarmType = self.alarmType;
    alarmCfg.buzzer = self.buzzer;
    
    return alarmCfg;
}

#pragma mark - private api
- (void)updateOtherAlarmConfigUI
{
    self.alarmType = self.otherAlarmConfig.alarmType;
    self.buzzer = self.otherAlarmConfig.buzzer;
}

#pragma mark - action
- (IBAction)alarmTypeOption:(id)sender
{
    if (self.curAlarmType != self.alarmType) {
        self.curAlarmType = self.alarmType;
        [self performFetchAlarmConfigWithType:self.curAlarmType];
    }
}

#pragma mark - data
- (NSArray *)alarmTypes
{
    return @[NSLocalizedString(@"HDD Loss", nil),
             NSLocalizedString(@"HDD Full", nil),
             NSLocalizedString(@"HDD Error", nil),
             NSLocalizedString(@"Video Loss", nil),
             NSLocalizedString(@"Network Exception", nil)];
}

#pragma mark - setter & getter
- (void)setAlarmTypesBtn:(NSPopUpButton *)alarmTypesBtn
{
    _alarmTypesBtn = alarmTypesBtn;
    [self setControl:_alarmTypesBtn withTitles:[self alarmTypes]];
}

- (void)setOtherAlarmConfig:(FOS_NVR_OTHER_ALARM_CONFIG)otherAlarmConfig
{
    _otherAlarmConfig = otherAlarmConfig;
    [self updateOtherAlarmConfigUI];
}
@end
