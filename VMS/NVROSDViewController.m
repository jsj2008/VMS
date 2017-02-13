//
//  NVROSDViewController.m
//  
//
//  Created by mac_dev on 16/5/30.
//
//

#import "NVROSDViewController.h"

@interface NVROSDViewController ()

@end

@implementation NVROSDViewController

#pragma mark - public api
- (void)fetch
{
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int chn = self.chn;
        BOOL emptyChannel = YES;
        BOOL success[2] = {NO,NO};
        FOS_OSDConfigMsg osdConfigMsg;
        FOS_NVR_OSDMASKAREA_CONFIG osdMaskAreaConfig;
        
        
        FosAbility *ability = [[DispatchCenter sharedDispatchCenter] abilityOfDevice:self.device channel:chn];
        if (ability.model > 0) {
            void *results[] = {&osdConfigMsg,&osdMaskAreaConfig,NULL};
            int types[] = {FOSCAM_NVR_CONFIG_OSD,FOSCAM_NVR_CONFIG_OSD_MASK_AREA};
            
            char xml[OUT_BUFFER_LENGTH] = {0};
            FOSCAM_NVR_CONFIG config;
            config.input = &chn;
            config.output = xml;
            config.outputLen = OUT_BUFFER_LENGTH;
            
            
            emptyChannel = NO;
            
            for (int i = 0; i < 2; i++) {
                memset(xml, 0, OUT_BUFFER_LENGTH);
                if ([[DispatchCenter sharedDispatchCenter] getConfig:&config forType:types[i] fromDevice:self.device]) {
                    //解析结果
                    NSError *err = nil;
                    NSString *rawString = [NSString stringWithCString:xml encoding:NSASCIIStringEncoding];
                    NSLog(@"%@",rawString);
                    
                    NSDictionary *dict = [XMLHelper parserCGIXml:rawString error:&err];
                    success[i] = !err && [self getConfig:results[i] type:types[i] fromDict:dict];
                }
            }
        }
        
        
        BOOL isOSDConfig = success[0];
        BOOL isOSDMask = success[1];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (emptyChannel) {
                [self alert:NSLocalizedString(@"failed to get the settings", nil)
                       info:NSLocalizedString(@"the channel did not add ipc or does not support privacy masking",nil)];
            }
            else if (!isOSDConfig) {
                [self alert:NSLocalizedString(@"failed to get the settings", nil)
                       info:NSLocalizedString(@"time out",nil)];
            }
            else {
                [self setOsdConfigMsg:osdConfigMsg];
                
                if (isOSDMask) {
                    [self setOsdMaskEnable:osdMaskAreaConfig.isEnableOsdMask];
                    [self setOsdMaskArea:osdMaskAreaConfig.osdMaskArea];
                }
                else {
                    [self.osdMaskEnableBtn setEnabled:NO];
                    [self.privacyCoverEditBtn setHidden:YES];
                }
            }
            
            [self setActivity:NO];
        });
    });
}


- (void)push
{
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FOSCAM_NVR_CONFIG config;
        char xml[OUT_BUFFER_LENGTH] = {0};
        
        //收集控件信息
        BOOL osdMaskEnable =  self.osdMaskEnableBtn.enabled;
        FOS_NVR_OSDConfigMsg nvrOsdConfigMsg;
        FOS_NVR_OSDMASKAREA_CONFIG nvrOsdMaskAreaConfig;
        
        nvrOsdConfigMsg.chn = self.chn;
        nvrOsdConfigMsg.osdConfigMsg = [self osdConfigMsgFromUI];
        nvrOsdMaskAreaConfig.chn = self.chn;
        nvrOsdMaskAreaConfig.isEnableOsdMask = [self osdMaskEnableFromUI];
        nvrOsdMaskAreaConfig.osdMaskArea = self.osdMaskArea;
    
        memset(xml, 0, OUT_BUFFER_LENGTH);
        config.input = &nvrOsdConfigMsg;
        config.output = xml;
        config.outputLen = OUT_BUFFER_LENGTH;
        
        BOOL isOSDConfig = NO;
        BOOL isOSDMask = NO;
        if ([[DispatchCenter sharedDispatchCenter] setConfig:&config
                                                     forType:FOSCAM_NVR_CONFIG_OSD
                                                    toDevice:self.device]) {
            //解析结果
            NSError     *err = nil;
            NSString    *rawString = [NSString stringWithCString:xml encoding:NSASCIIStringEncoding];
            NSNumber    *result = [[XMLHelper parserCGIXml:rawString error:&err] valueForKey:@"result"];
            NSLog(@"%@",rawString);
            
            if (!err && result && (result.intValue == 0)) {
                isOSDConfig = YES;
                
                if (osdMaskEnable) {
                    memset(xml, 0, OUT_BUFFER_LENGTH);
                    config.input = &nvrOsdMaskAreaConfig;
                    config.output = xml;
                    config.outputLen = OUT_BUFFER_LENGTH;
                    
                    if ([[DispatchCenter sharedDispatchCenter] setConfig:&config
                                                                 forType:FOSCAM_NVR_CONFIG_OSD_MASK_AREA
                                                                toDevice:self.device]) {
                        NSLog(@"%@",rawString);
                        //解析结果
                        err         = nil;
                        rawString   = [NSString stringWithCString:xml encoding:NSASCIIStringEncoding];
                        result      = [[XMLHelper parserCGIXml:rawString error:&err] valueForKey:@"result"];
                        
                        isOSDMask = !err && result && (result.intValue == 0);
                    }
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!isOSDConfig)
                [self alert:NSLocalizedString(@"failed to set the settings", nil) info:@""];
            else if (osdMaskEnable && !isOSDMask) {
                [self alert:NSLocalizedString(@"failed to set the settings", nil) info:@""];
            }
            
            [self setActivity:NO];
        });
    });
}

- (NSString *)description
{
    return NSLocalizedString(@"OSD", nil);
}

- (BOOL)enableOSD
{
    return YES;
}

- (BOOL)enablePrivacyCover
{
    return YES;
}

#pragma mark - private api
- (BOOL)getConfig :(void *)cfg
             type :(int)type
         fromDict :(NSDictionary *)dict
{
    if ([[dict valueForKey:@"result"] intValue] == 0) {
        switch (type) {
            case FOSCAM_NVR_CONFIG_OSD: {
                FOS_OSDConfigMsg *osdConfigMsg = (FOS_OSDConfigMsg *)cfg;
                [[dict valueForKey:@"name"] getCString:osdConfigMsg->devName maxLength:64 encoding:NSASCIIStringEncoding];
                osdConfigMsg->isEnableDevName = [[dict valueForKey:@"isEnableChName"] intValue];
                osdConfigMsg->isEnableTimeStamp = [[dict valueForKey:@"isEnableTimeDisplay"]intValue];
            }
                break;
            case FOSCAM_NVR_CONFIG_OSD_MASK_AREA:{
                FOS_NVR_OSDMASKAREA_CONFIG *nvrOsdMaskAreaConfig = (FOS_NVR_OSDMASKAREA_CONFIG *)cfg;
                nvrOsdMaskAreaConfig->isEnableOsdMask = [[dict valueForKey:@"isEnableOsdMask"] intValue];
                for (int i = 0; i < FOS_MAX_OSDMASKAREA_COUNT; i++) {
                    nvrOsdMaskAreaConfig->osdMaskArea.x1[i] = [[dict valueForKey:[NSString stringWithFormat:@"x1_%d",i]] intValue];
                    nvrOsdMaskAreaConfig->osdMaskArea.y1[i] = [[dict valueForKey:[NSString stringWithFormat:@"y1_%d",i]] intValue];
                    nvrOsdMaskAreaConfig->osdMaskArea.x2[i] = [[dict valueForKey:[NSString stringWithFormat:@"x2_%d",i]] intValue];
                    nvrOsdMaskAreaConfig->osdMaskArea.y2[i] = [[dict valueForKey:[NSString stringWithFormat:@"y2_%d",i]] intValue];
                }
            }
                break;
            default:
                break;
        }
        
        return YES;
    }
    
    
    return NO;
}


- (BOOL)getConfig :(void *)cfg
             type :(int)type
  fromStringArray :(NSArray *)array
{
    NSUInteger cnt = array.count;
    switch (type) {
        case FOSCAM_NVR_CONFIG_OSD: {
            FOS_OSDConfigMsg *osdConfigMsg = (FOS_OSDConfigMsg *)cfg;
            if (cnt == 5) {
                if ([array[1] isEqualToString:@"0"]) {
                    [array[2] getCString:osdConfigMsg->devName maxLength:64 encoding:NSASCIIStringEncoding];
                    osdConfigMsg->isEnableDevName = [array[3] intValue];
                    osdConfigMsg->isEnableTimeStamp = [array[4] intValue];
                    return YES;
                }
            }
        }
            break;
        case FOSCAM_NVR_CONFIG_OSD_MASK_AREA:{
            FOS_NVR_OSDMASKAREA_CONFIG *nvrOsdMaskAreaConfig = (FOS_NVR_OSDMASKAREA_CONFIG *)cfg;
            if (cnt == 19) {
                if ([array[1] isEqualToString:@"0"]) {
                    nvrOsdMaskAreaConfig->isEnableOsdMask = [array[2] intValue];
                    for (int i = 0; i < FOS_MAX_OSDMASKAREA_COUNT; i++) {
                        nvrOsdMaskAreaConfig->osdMaskArea.x1[i] = [array[3 + 4*i + 0] intValue];
                        nvrOsdMaskAreaConfig->osdMaskArea.y1[i] = [array[3 + 4*i + 1] intValue];
                        nvrOsdMaskAreaConfig->osdMaskArea.x2[i] = [array[3 + 4*i + 2] intValue];
                        nvrOsdMaskAreaConfig->osdMaskArea.y2[i] = [array[3 + 4*i + 3] intValue];
                    }
                    return YES;
                }
            }
        }
            break;
        default:
            break;
    }
    
    return NO;
}
@end
