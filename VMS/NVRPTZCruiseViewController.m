//
//  NVRPTZCruiseViewController.m
//  
//
//  Created by mac_dev on 16/5/30.
//
//

#import "NVRPTZCruiseViewController.h"

@interface NVRPTZCruiseViewController ()

@end

@implementation NVRPTZCruiseViewController

#pragma mark - private api
- (BOOL)getConfig :(void *)cfg
             type :(int)type
         fromDict :(NSDictionary *)dict
{
    if ([[dict valueForKey:@"result"] intValue] == 0) {
        switch (type) {
            case FOSCAM_NVR_CONFIG_PTZ_PRESET_POINT_LIST: {
                FOS_RESETPOINTLIST *presetPointList = (FOS_RESETPOINTLIST *)cfg;
                presetPointList->result = 0;
                presetPointList->pointCnt = [[dict valueForKey:@"pointNum"] intValue];
                for (int i = 0; i < FOS_MAX_PRESETPOINT_COUNT; i++) {
                    [[dict valueForKey:[NSString stringWithFormat:@"point%d",i]] getCString:(presetPointList->pointName[i])
                                                                                  maxLength:FOS_MAX_PRESETPOINT_NAME_LEN
                                                                                   encoding:NSASCIIStringEncoding];
                }
            }
                break;
            case FOSCAM_NVR_CONFIG_PTZ_CRUISE_MAP_LIST:{
                FOS_CRUISEMAPLIST *cruiseMapList = (FOS_CRUISEMAPLIST *)cfg;
                cruiseMapList->cruiseMapCnt = [[dict valueForKey:@"pointNum"] intValue];
                for (int i = 0; i < FOS_MAX_CURISEMAP_COUNT; i++) {
                    [[dict valueForKey:[NSString stringWithFormat:@"point%d",i]] getCString:(cruiseMapList->cruiseMapName[i])
                                                                                  maxLength:FOS_MAX_CURISEMAP_NAME_LEN
                                                                                   encoding:NSASCIIStringEncoding];
                }
            }
                break;
            case FOSCAM_NVR_CONFIG_PTZ_CRUISE_MAP_INFO:{
                FOSCAM_NVR_CRUISE_MAP_INFO *nvrCruiseMapInfo = (FOSCAM_NVR_CRUISE_MAP_INFO *)cfg;
                nvrCruiseMapInfo->cruiseMapInfo.getResutl = 0;
                int ptCnt = [[dict valueForKey:@"pointNum"] intValue];
                
                for (int i = 0; i < ptCnt; i++) {
                    [[dict valueForKey:[NSString stringWithFormat:@"point%d",i]] getCString:nvrCruiseMapInfo->cruiseMapInfo.pointName[i]
                                                                                  maxLength:FOS_MAX_CURISEMAP_NAME_LEN
                                                                                   encoding:NSASCIIStringEncoding];
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
        case FOSCAM_NVR_CONFIG_PTZ_PRESET_POINT_LIST: {
            FOS_RESETPOINTLIST *presetPointList = (FOS_RESETPOINTLIST *)cfg;
            if (cnt == 19) {
                presetPointList->result = 0;
                presetPointList->pointCnt = [array[2] intValue];
                for (int i = 0; i < FOS_MAX_PRESETPOINT_COUNT; i++) {
                    [array[3 + i] getCString:(presetPointList->pointName[i])
                                    maxLength:FOS_MAX_PRESETPOINT_NAME_LEN
                                     encoding:NSASCIIStringEncoding];
                }
                
                return YES;
            }
        }
            break;
        case FOSCAM_NVR_CONFIG_PTZ_CRUISE_MAP_LIST:{
            FOS_CRUISEMAPLIST *cruiseMapList = (FOS_CRUISEMAPLIST *)cfg;
            if (cnt == 19) {
                cruiseMapList->cruiseMapCnt = [array[2] intValue];
                for (int i = 0; i < FOS_MAX_CURISEMAP_COUNT; i++) {
                    [array[3 + i] getCString:(cruiseMapList->cruiseMapName[i])
                                    maxLength:FOS_MAX_CURISEMAP_NAME_LEN
                                     encoding:NSASCIIStringEncoding];
                }
                return YES;
            }
        }
            break;
        case FOSCAM_NVR_CONFIG_PTZ_CRUISE_MAP_INFO:{
            FOSCAM_NVR_CRUISE_MAP_INFO *nvrCruiseMapInfo = (FOSCAM_NVR_CRUISE_MAP_INFO *)cfg;
            if (cnt == 11) {
                nvrCruiseMapInfo->cruiseMapInfo.getResutl = 0;
                int ptCnt = [array[2] intValue];
                
                for (int i = 0; i < ptCnt; i++) {
                    [array[3 + i] getCString:nvrCruiseMapInfo->cruiseMapInfo.pointName[i]
                                    maxLength:FOS_MAX_CURISEMAP_NAME_LEN
                                     encoding:NSASCIIStringEncoding];
                }
                
                return YES;
            }
        }
            break;
        default:
            break;
    }
    
    return NO;
}

#pragma mark - public api
- (void)fetchCruiseMode
{}

- (void)fetchPresetPointAndCruiseMapList
{
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FOS_RESETPOINTLIST presetPointList;
        FOS_CRUISEMAPLIST cruiseMapList;
       
        int chn = self.chn;
        
        void *inputs[] = {
            &chn,
            &chn,
            NULL,
        };
        
        int types[] = {
            FOSCAM_NVR_CONFIG_PTZ_PRESET_POINT_LIST,
            FOSCAM_NVR_CONFIG_PTZ_CRUISE_MAP_LIST,
        };
        
        void *results[] = {
            &presetPointList,
            &cruiseMapList,
        };
        
        FOSCAM_NVR_CONFIG config;
        char xml[OUT_BUFFER_LENGTH] = {0};
        BOOL success = YES;
        for (int i = 0;;i++) {
            if (inputs[i] == NULL) {
                break;
            }
            
            memset(xml, 0, OUT_BUFFER_LENGTH);
            config.input = inputs[i];
            config.output = xml;
            config.outputLen = OUT_BUFFER_LENGTH;
            
            BOOL result = NO;
            if ([[DispatchCenter sharedDispatchCenter] getConfig:&config
                                                         forType:types[i]
                                                      fromDevice:self.device]) {
                //解析结果
                NSError *err = nil;
                NSString *rawString = [NSString stringWithCString:xml encoding:NSASCIIStringEncoding];
                NSLog(@"%@",rawString);
                NSDictionary *dict = [XMLHelper parserCGIXml:rawString error:&err];
                
                if (!err) {
                    result = [self getConfig:results[i]
                                        type:types[i]
                                    fromDict:dict];
                }
            }
            
            if (!result) {
                success = NO;
                break;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.fetchPresetPtsCompleteHandle(success,presetPointList,cruiseMapList,self);
        });
    });
}

- (void)fetchCruiseInfo :(NSString *)name;
{
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FOS_RESETPOINTLIST presetPointList;
        FOS_CRUISEMAPLIST cruiseMapList;
        FOSCAM_NVR_CRUISE_MAP_INFO nvrCruiseInfo;
        int chn = self.chn;
        
        nvrCruiseInfo.chn = chn;
        nvrCruiseInfo.cruiseMapInfo.getResutl = 2;
        [name getCString:nvrCruiseInfo.cruiseMapInfo.cruiseMapName
               maxLength:FOS_MAX_CURISEMAP_NAME_LEN
                encoding:NSASCIIStringEncoding];
        for (int i = 0; i < FOS_MAX_PRESETPOINT_COUNT_OF_MAP; i++) {
            memset(nvrCruiseInfo.cruiseMapInfo.pointName[i], 0, FOS_MAX_CURISEMAP_NAME_LEN);
        }
        
        void *inputs[] = {
            &chn,
            &chn,
            &nvrCruiseInfo,
            NULL,
        };
        
        int types[] = {
            FOSCAM_NVR_CONFIG_PTZ_PRESET_POINT_LIST,
            FOSCAM_NVR_CONFIG_PTZ_CRUISE_MAP_LIST,
            FOSCAM_NVR_CONFIG_PTZ_CRUISE_MAP_INFO,
        };
        
        void *results[] = {
            &presetPointList,
            &cruiseMapList,
            &nvrCruiseInfo,
        };
        
        FOSCAM_NVR_CONFIG config;
        char xml[OUT_BUFFER_LENGTH] = {0};
        BOOL success = YES;
        for (int i = 0;;i++) {
            if (!success || inputs[i] == NULL) {
                break;
            }
            
            memset(xml, 0, OUT_BUFFER_LENGTH);
            config.input = inputs[i];
            config.output = xml;
            config.outputLen = OUT_BUFFER_LENGTH;
            
            if ([[DispatchCenter sharedDispatchCenter] getConfig:&config
                                                         forType:types[i]
                                                      fromDevice:self.device]) {
                //解析结果
                NSError *err = nil;
                NSString *rawString = [NSString stringWithCString:xml encoding:NSASCIIStringEncoding];
                NSLog(@"%@",rawString);
                //NSArray *values = [self parserCGIXml:rawString error:&err];
                NSDictionary *dict = [XMLHelper parserCGIXml:rawString error:&err];
                
                if (!err /*&& values.count >= 2*/) {
                    success = [self getConfig:results[i]
                                         type:types[i]
                                     fromDict:dict];
//                    success = [self getConfig:results[i]
//                                         type:types[i]
//                              fromStringArray:values];
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                printf("Cruise Map Name = %s",nvrCruiseInfo.cruiseMapInfo.cruiseMapName);
                //[self setCruiseMapList:cruiseMapList];
                [self setPresetPointList:presetPointList];
                [self setCruiseMapInfo:nvrCruiseInfo.cruiseMapInfo];
            } else {
                [self alert:@"获取巡航轨迹设置失败!" info:@""];
            }
            [self setActivity:NO];
        });
    });
}

- (void)push
{}

- (NSString *)description
{
    return @"巡航轨迹设置";
}

- (BOOL)enableCruiseModeOption
{
    return NO;  
}

- (BOOL)enableCruiseMapPrepointLingerTime
{
    return NO;
}


- (void)performSaveCruiseMap:(NSString *)mapName;
{
    [self setActivity:YES];
    FOSCAM_NVR_CRUISE_MAP_INFO nvrMapInfo;
    nvrMapInfo.cruiseMapInfo = self.cruiseMapInfo;
    nvrMapInfo.chn = self.chn;
    
    [mapName getCString:nvrMapInfo.cruiseMapInfo.cruiseMapName
              maxLength:FOS_MAX_CURISEMAP_NAME_LEN
               encoding:NSASCIIStringEncoding];
    //首先移除，再添加
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        FOSCAM_NVR_CONFIG nvrCfg[2];
        FOSCAM_NVR_CONFIG_TYPE cfgType[2] = {FOSCAM_NVR_CONFIG_PTZ_DEL_CRUISE_MAP,FOSCAM_NVR_CONFIG_PTZ_CRUISE_MAP_INFO};
        BOOL success = YES;
        
        for (int i = 0;i < 2; i++) {
            char xml[OUT_BUFFER_LENGTH] = {0};
            
            nvrCfg[i].input = (void *)&nvrMapInfo;
            nvrCfg[i].output = xml;
            nvrCfg[i].outputLen = OUT_BUFFER_LENGTH;
            
            if ([[DispatchCenter sharedDispatchCenter] setConfig:&nvrCfg
                                                         forType:cfgType[i]
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
            
            if (!success) {
                break;
            }
        }
        //异步回主线程显示
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!success) [self alert:@"保存巡航路径失败!" info:@""];
            [self setActivity:NO];
        });
    });
}

- (void)performRemoveCruiseMap :(NSString *)mapName
{
    [self setActivity:YES];
    FOSCAM_NVR_CRUISE_MAP_INFO nvrMapInfo;
    nvrMapInfo.cruiseMapInfo = self.cruiseMapInfo;
    nvrMapInfo.chn = self.chn;
    
    [mapName getCString:nvrMapInfo.cruiseMapInfo.cruiseMapName
              maxLength:FOS_MAX_CURISEMAP_NAME_LEN
               encoding:NSASCIIStringEncoding];
    //首先移除，再添加
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        FOSCAM_NVR_CONFIG nvrCfg;
        char xml[OUT_BUFFER_LENGTH] = {0};
        
        nvrCfg.input = (void *)&nvrMapInfo;
        nvrCfg.output = xml;
        nvrCfg.outputLen = OUT_BUFFER_LENGTH;
        
        BOOL success = YES;
        if ([[DispatchCenter sharedDispatchCenter] setConfig:&nvrCfg
                                                     forType:FOSCAM_NVR_CONFIG_PTZ_DEL_CRUISE_MAP
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
    
        //异步回主线程显示
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!success) [self alert:@"移除巡航路径失败!" info:@""];
            [self setActivity:NO];
        });
    });
}
@end
