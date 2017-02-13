//
//  NVREncodingParamViewController.m
//  
//
//  Created by mac_dev on 16/5/28.
//
//

#import "NVREncodingParamViewController.h"

@interface NVREncodingParamViewController ()

@end

@implementation NVREncodingParamViewController

#pragma mark - public api
- (void)fetch
{
    [self setActivity:YES];
    
    //获取当前通道与model
    int chn = self.chn;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //获取主子码流编码参数
        FOS_VIDEOSTREAMLISTPARAM videoStreamListParam;
        FOS_VIDEOSTREAMLISTPARAM videoSubStreamListParam;
        FOS_VIDEOSTREAMLISTPARAM *params[2] = {&videoStreamListParam,&videoSubStreamListParam};
        NSMutableArray *streamResolutions = [[NSMutableArray alloc] init];
        NSMutableArray *subStreamResolutions = [[NSMutableArray alloc] init];
        NSArray *resolutions = [NSArray arrayWithObjects:streamResolutions,subStreamResolutions,nil];
        BOOL success = NO;
    
        for (int streamType = 0; (streamType < 2); streamType++) {
            FOSCAM_NVR_CONFIG config;
            FOSCAM_NVR_REAL_CH realCh;
            char xml[OUT_BUFFER_LENGTH] = {0};
            
            realCh.chn = chn;
            realCh.streamType = streamType;
            config.input = &realCh;
            config.output = xml;
            config.outputLen = OUT_BUFFER_LENGTH;
            
            if ([[DispatchCenter sharedDispatchCenter] getConfig:&config
                                                         forType:FOSCAM_NVR_CONFIG_VIDEO_STREAM_PARAM
                                                      fromDevice:self.device]) {
                //解析结果
                NSError         *err        = nil;
                NSString        *rawString  = [NSString stringWithCString:xml encoding:NSASCIIStringEncoding];
                NSDictionary    *dict       = [XMLHelper parserCGIXml:rawString error:&err];
                
                if (DEBUG_CGI) {
                    NSLog(@"%@",rawString);
                }
                
                if (!err) {
                    if ([[dict valueForKey:@"result"] intValue] == 0) {
                        success = YES;
                        
                        FOS_VIDEOSTREAMLISTPARAM *curStreamParam = params[streamType];
                        curStreamParam->streamType[0] = [[dict valueForKey:@"streamType"] intValue];
                        curStreamParam->bitRate[0] = [[dict valueForKey:@"bitRate"] intValue];
                        curStreamParam->frameRate[0] = [[dict valueForKey:@"frameRate"] intValue];
                        curStreamParam->GOP[0] = [[dict valueForKey:@"gop"] intValue];
                        curStreamParam->isVBR[0] = [[dict valueForKey:@"isVbr"] intValue];
                        
                        //解析可选的分辨率
                        NSMutableArray *temp = resolutions[streamType];
                        for (int i = 0; i <10; i++) {
                            int resWidth = [[dict valueForKey:[NSString stringWithFormat:@"res%d0",i]] intValue];
                            int resHeight = [[dict valueForKey:[NSString stringWithFormat:@"res%d1",i]] intValue];
                            
                            if (resWidth * resHeight > 0) {
                                [temp addObject:[NSString stringWithFormat:@"%d*%d",resWidth,resHeight]];
                            }
                        }
                        
                        //对分辨率按照宽高进行排序
                        [temp sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                            int resWidth1,resHeight1,resWidth2,resHeight2;
                            [self getWidth:&resWidth1 height:&resHeight1 fromResolution:obj1];
                            [self getWidth:&resWidth2 height:&resHeight2 fromResolution:obj2];
                            
                            if (resWidth1 == resWidth2)
                                return resHeight1 >= resHeight2? NSOrderedAscending : NSOrderedDescending;
                            else
                                return (resWidth1 > resWidth2)? NSOrderedAscending : NSOrderedDescending;
                        }];
                        
                        //当前的分辨率
                        NSString *curResolution = [NSString stringWithFormat:@"%d*%d",[[dict valueForKey:@"resWidth"] intValue],
                                                   [[dict valueForKey:@"resHeight"] intValue]];
                        curStreamParam->resolution[0] = (int)[temp indexOfObject:curResolution];
                    }
                }
            }
            
            if (!success)
                break;
            /*FOSCAM_NVR_CONFIG tt;
            FOSCAM_NVR_REAL_CH ss;
            char aa[OUT_BUFFER_LENGTH] = {0};
            ss.chn = 1;
            ss.streamType = 0;
            
            tt.input = &ss;
            tt.output =aa;
            tt.outputLen = OUT_BUFFER_LENGTH;
            
            [[DispatchCenter sharedDispatchCenter] getConfig:&tt forType:FOSCAM_NVR_CONFIG_VIDEO_STREAM_CAPABILITIES fromDevice:self.device];
            
            printf("json = %s\n",aa);
            if (!success) {
                break;
            }*/
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                NSLog(@"streamResolutions.count = %ld",streamResolutions.count);
                NSLog(@"subStreamResolutions.count = %ld",subStreamResolutions.count);
                
                [self setControlOrderByTag:self.resolution1Btn withTitles:[NSArray arrayWithArray:streamResolutions]];
                [self setControlOrderByTag:self.resolution2Btn withTitles:[NSArray arrayWithArray:subStreamResolutions]];
                [self setVideoStreamListParam:videoStreamListParam];
                [self setVideoSubStreamListParam:videoSubStreamListParam];
            } else
                [self alert:NSLocalizedString(@"failed to get the settings",nil)
                       info:NSLocalizedString(@"time out",nil)];
            [self setActivity:NO];
        });
    });
}

- (void)push
{
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL success = NO;
        FOS_NVR_VIDEOSTREAMPARAM videoStreamParam,videoSubStreamParam;
        FOS_NVR_VIDEOSTREAMPARAM *params[2] = {&videoStreamParam,&videoSubStreamParam};
        videoStreamParam = [self nvrStreamEncoderArgs];
        videoSubStreamParam = [self nvrSubStreamEncoderArgs];
       
        if (videoStreamParam.videoStreamParam.frameRate > 0) {
            videoStreamParam.videoStreamParam.frameRate--;
        }
        
        if (videoSubStreamParam.videoStreamParam.frameRate > 0) {
            videoSubStreamParam.videoStreamParam.frameRate--;
        }
        
        for (int streamType = 0; streamType < 2; streamType++) {
            //收集控件信息
            FOSCAM_NVR_CONFIG config;
            
            char xml[OUT_BUFFER_LENGTH] = {0};
            
            config.input = params[streamType];
            config.output = xml;
            config.outputLen = OUT_BUFFER_LENGTH;
            
            if ([[DispatchCenter sharedDispatchCenter] setConfig:&config
                                                         forType:FOSCAM_NVR_CONFIG_VIDEO_STREAM_PARAM
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
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!success) [self alert:NSLocalizedString(@"failed to set the settings",nil)
                                 info:NSLocalizedString(@"time out", nil)];
            [self setActivity:NO];
        });
    });
}

- (NSString *)description
{
    return NSLocalizedString(@"Video Encode", nil);
}

- (FOS_NVR_VIDEOSTREAMPARAM)nvrStreamEncoderArgs
{
    FOS_NVR_VIDEOSTREAMPARAM result;
    memset(&result, 0, sizeof(FOS_NVR_VIDEOSTREAMPARAM));
    NSArray *resolutions = self.resolution1Btn.itemTitles;
    
    result.chn = self.chn;
    result.videoStreamParam = [self encoderArgsFromUI:FOSSTREAM_MAIN];
    
    if (result.videoStreamParam.resolution < resolutions.count) {
        [self getWidth:&result.resWidth
                height:&result.resHeight
        fromResolution:resolutions[result.videoStreamParam.resolution]];
    }
    
    result.videoStreamParam.streamType  = 0;
    result.videoStreamParam.GOP         = self.videoStreamListParam.GOP[0];
    result.videoStreamParam.isVBR       = self.videoStreamListParam.isVBR[0];
    
    return result;
}

- (FOS_NVR_VIDEOSTREAMPARAM)nvrSubStreamEncoderArgs
{
    FOS_NVR_VIDEOSTREAMPARAM result;
    memset(&result, 0, sizeof(FOS_NVR_VIDEOSTREAMPARAM));
    NSArray *resolutions = self.resolution2Btn.itemTitles;
    
    result.chn = self.chn;
    result.videoStreamParam = [self encoderArgsFromUI:FOSSTREAM_SUB];
    
    if (result.videoStreamParam.resolution < resolutions.count) {
        [self getWidth:&result.resWidth
                height:&result.resHeight
        fromResolution:resolutions[result.videoStreamParam.resolution]];
    }
    
    result.videoStreamParam.streamType = 1;
    result.videoStreamParam.GOP = self.videoSubStreamListParam.GOP[0];
    result.videoStreamParam.isVBR = self.videoSubStreamListParam.isVBR[0];
    
    return result;
}

- (void)onResolutionChanged:(FOSSTREAM_TYPE)streamType
{}

- (void)onStreamTypeChanged:(FOSSTREAM_TYPE)streamType
{}

- (int)bitRate:(FOSSTREAM_TYPE)streamType withValue :(int)value
{
    return value;
}

#pragma mark - private api
- (BOOL)getWidth :(int *)resWidth height :(int *)resHeight fromResolution :(NSString *)resolution
{
    //分辨率字符串以resWidth * resHeight形式构成
    NSArray *subStrs = [resolution componentsSeparatedByString:@"*"];
    
    if (subStrs.count == 2) {
        *resWidth = [subStrs[0] intValue];
        *resHeight = [subStrs[1] intValue];
        return YES;
    }
    
    return NO;
}
#pragma mark - life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.videoStreamTypeEnable = NO;
    self.gopEnable = NO;
    [self setControl:self.frameRate1Btn withFrameRate:30];
    [self setControl:self.frameRate2Btn withFrameRate:30];
}

- (void)dealloc
{
    NSLog(@"Running in %@,selector '%@'",self.className,NSStringFromSelector(_cmd));
}

#pragma mark - init popupbutton
- (void)defaultBRateInitialization :(NSPopUpButton *)btn
{
    int tags[9] = {
        4194304,
        2097152,
        1048576,
        524288,
        262144,
        204800,
        102400,
        51200,
        20480,
    };
    
    NSArray *titles = @[@"4M",@"2M",@"1M",@"512K",@"256K",@"200K",@"100K",@"50K",@"20K"];
    
    [btn removeAllItems];
    
    for (int i = 0; i < 9; i++) {
        [btn addItemWithTitle:titles[i]];
        [btn lastItem].tag = tags[i];
    }
}

- (void)defaultFRateInitialization :(NSPopUpButton *)btn
{
    [btn removeAllItems];
    
    for (int i = 0; i < 30; i++) {
        [btn addItemWithTitle:[NSString stringWithFormat:@"%d",i + 1]];
        [btn lastItem].tag = i + 1;
    }
}

- (void)initMainStreamBitRateBtnWithJson :(NSString *)json
{
    if (json) {
        //走json
        return;
    }
    
    [self defaultBRateInitialization:self.bitRate1Btn];
}

- (void)initSubStreamBitRateBtnWithJson :(NSString *)json
{
    if (json) {
        return;
    }
    
    [self defaultBRateInitialization:self.bitRate2Btn];
}

- (void)updateFRateBtn :(NSPopUpButton *)btn withValue :(int)val
{
    if (![btn selectItemWithTag:val]) {
        [btn addItemWithTitle:[NSString stringWithFormat:@"%d",val]];
        [btn lastItem].tag = val;
    }
}


#pragma mark - setter && getter
- (void)orderByTag :(NSPopUpButton *)control
{
    NSArray *items = control.itemArray;
    
    for (int tag = 0; tag < items.count; tag++) {
        NSMenuItem *item = items[tag];
        item.tag = tag;
    }
}

- (void)setControlOrderByTag :(NSPopUpButton *)btn
                  withTitles :(NSArray *)titles
{
    [self setControl:btn withTitles:titles];
    [self orderByTag:btn];
}

- (void)setVideoStreamListParam:(FOS_VIDEOSTREAMLISTPARAM)videoStreamListParam
{
    [super setVideoStreamListParam:videoStreamListParam];
    [self initMainStreamBitRateBtnWithJson:nil];
    [self defaultFRateInitialization:self.frameRate1Btn];
    [self.bitRate1Btn selectItemWithTag:videoStreamListParam.bitRate[0]];
    [self updateFRateBtn:self.frameRate1Btn withValue:videoStreamListParam.frameRate[0]];
}

- (void)setVideoSubStreamListParam:(FOS_VIDEOSTREAMLISTPARAM)videoSubStreamListParam
{
    [super setVideoSubStreamListParam:videoSubStreamListParam];
    [self initSubStreamBitRateBtnWithJson:nil];
    [self defaultFRateInitialization:self.frameRate2Btn];
    [self.bitRate2Btn selectItemWithTag:videoSubStreamListParam.bitRate[0]];
    [self updateFRateBtn:self.frameRate2Btn withValue:videoSubStreamListParam.frameRate[0]];
}

@end
