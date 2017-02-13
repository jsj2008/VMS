//
//  EncodingParamViewController.m
//  
//
//  Created by mac_dev on 16/5/23.
//
//

#import "EncodingParamViewController.h"
#import "../TBXML/TBXML-Headers/TBXML.h"

@interface EncodingParamViewController()

@property (nonatomic,assign) int curChn;

@property (nonatomic,weak) IBOutlet NSPopUpButton *gop1Btn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *gop2Btn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *isVBR1Btn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *isVBR2Btn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *videoStreamType1Btn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *videoStreamType2Btn;
@property (nonatomic,weak) IBOutlet NSTextField *vbrTF1;
@property (nonatomic,weak) IBOutlet NSTextField *vbrTF2;
@property (nonatomic,assign) int lbr1;
@property (nonatomic,assign) int lbr2;

@end

@implementation EncodingParamViewController

#pragma mark - public api
- (void)fetch
{
    [self setActivity:YES];
    
    DispatchCenter *center = [DispatchCenter sharedDispatchCenter];
    CDevice *device = self.device;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^ {
        BOOL success = NO;
        FOSCAM_NET_CONFIG               config;
        FOS_STREAMFRAMEPARAMINFO        streamFrameInfo;
        FOS_STREAMINFO                  streamInfo;
        FOS_VIDEOSTREAMLISTPARAM_EXT    streamListParam;
        FOS_VIDEOSTREAMLISTPARAM_EXT    subStreamListParam;
        
        config.info = &streamFrameInfo;
        config.info2 = &streamInfo;
        success = [center getConfig:&config forType:FOSCAM_NET_CONFIG_STREAM_ENCODE_INFO fromDevice:device];
        
        if (success) {
            char    xml[OUT_BUFFER_LENGTH] = {0};
            int     len = OUT_BUFFER_LENGTH;
            
            FOSCAM_NET_CONFIG_TYPE cfgTypes[2] =
            {
                FOSCAM_NET_CONFIG_VIDEO_ENCODE_MAIN,
                FOSCAM_NET_CONFIG_VIDEO_ENCODE_SUB,
            };
            
            FOS_VIDEOSTREAMLISTPARAM_EXT *streamListParams[2] =
            {
                &streamListParam,
                &subStreamListParam
            };
            
            for (int i = 0; (i < 2) && success; i++) {
                memset(xml, 0, len);
                memset(streamListParams[i], 0, sizeof(FOS_VIDEOSTREAMLISTPARAM_EXT));
                
                config.info = xml;
                config.info2 = &len;
                
                success = [center getConfig:&config forType:cfgTypes[i] fromDevice:device]?
                
                [self getStreamListParamExt:streamListParams[i] fromXml:xml withStreamType:i] : NO;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [self setStreamInfo:streamInfo];
                [self setVideoStreamListParam:streamListParam.streamListParam];
                [self setVideoSubStreamListParam :subStreamListParam.streamListParam];
                [self setVideoStreamListExt:streamListParam.streamListExt];
                [self setVideoSubStreamListExt:subStreamListParam.streamListExt];
            } else
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
        FOSCAM_NET_CONFIG config;
        FOS_VIDEOSTREAMPARAM videoStreamParam = [self encoderArgsFromUI:FOSSTREAM_MAIN];
        FOS_VIDEOSTREAMPARAM videoSubStreamParam = [self encoderArgsFromUI:FOSSTREAM_SUB];
        
        FOSCAM_NET_CONFIG_TYPE cfgTypes[2] =
        {
            FOSCAM_NET_CONFIG_VIDEO_ENCODE_MAIN,
            FOSCAM_NET_CONFIG_VIDEO_ENCODE_SUB
        };
        
        void *infos[] = {&videoStreamParam,&videoSubStreamParam};
        int lbrRatio[2] = {self.lbr1,self.lbr2};
        
        BOOL success = YES;
        for (int i = 0; (i < 2) && success; i++) {
            char xml[OUT_BUFFER_LENGTH] = {0};
            int len = OUT_BUFFER_LENGTH;
            
            config.info = infos[i];
            config.info2 = lbrRatio + i;
            config.info3 = xml;
            config.info4 = &len;
            
            success = [[DispatchCenter sharedDispatchCenter] setConfig:&config
                                                               forType:cfgTypes[i]
                                                              toDevice:self.device]? [self resultFromXml:xml] : NO;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success)
                [self fetch];
            else
                [self alert:NSLocalizedString(@"failed to set the settings", nil)
                       info:NSLocalizedString(@"time out", nil)];
            
            [self setActivity:NO];
        });
    });
}


- (NSString *)description
{
    return NSLocalizedString(@"Video Encode", nil);
}

- (SVC_OPTION)option
{
    return SVC_REFRESH | SVC_SAVE;
}

//分辨率发生改变,会引起帧率(直接)发生改变
- (void)onResolutionChanged:(FOSSTREAM_TYPE)streamType
{
    [self initFrameRate:streamType];

    FOS_VIDEOSTREAMLISTPARAM lists[2] = {
        self.videoStreamListParam,
        self.videoSubStreamListParam
    };
    
    int stream = (int)[[self valueForKey:[NSString stringWithFormat:@"videoStreamType%dBtn",streamType + 1]] selectedTag];
    if (stream < FOS_MAX_VIDEOSTREAM_TYPE) {
        NSPopUpButton *btn = [self valueForKey:[NSString stringWithFormat:@"frameRate%dBtn",streamType + 1]];
        BOOL success = [btn selectItemWithTag:lists[streamType].frameRate[stream]];
        
        if (!success) {
            [btn selectItem:[btn lastItem]];
        }
    }
}


- (void)onStreamTypeChanged:(FOSSTREAM_TYPE)streamType
{
    [self updateStreamEncoderExtArgsUI:streamType];
    
    //获取当前选中的视频流类型
    int stream = (int)[[self valueForKey:[NSString stringWithFormat:@"videoStreamType%dBtn",streamType + 1]] selectedTag];
    if (stream < FOS_MAX_VIDEOSTREAM_TYPE) {
        
        if (self.streamInfo.model >= 6000 && self.streamInfo.model < 7000) {
            BOOL enable = (stream == 3);
            
            [[self valueForKey:[NSString stringWithFormat:@"resolution%dBtn",streamType+1]] setEnabled:enable];
            [[self valueForKey:[NSString stringWithFormat:@"bitRate%dBtn",streamType+1]] setEnabled:enable];
            [[self valueForKey:[NSString stringWithFormat:@"frameRate%dBtn",streamType+1]] setEnabled:enable];
            
            if (streamType == FOSSTREAM_MAIN) {
                [[self valueForKey:[NSString stringWithFormat:@"isVBR%dBtn",streamType+1]] setEnabled:enable];
            }
        }
    }
}

//VBR发生改变，会引起码率发生改变
- (void)onVbrChange :(FOSSTREAM_TYPE)streamType
{
    int resolution = (int)[[self valueForKey:[NSString stringWithFormat:@"resolution%dBtn",streamType + 1]] selectedTag];
    int bitRate = -1;

    switch (streamType) {
        case FOSSTREAM_MAIN: {
            if (self.isLBR1) {
                switch (resolution) {
                    case RESOLUTION_3M:
                    case RESOLUTION_QHD2560_1440:
                        bitRate = 6291456;
                        break;
                        
                    case RESOLUTION_1080P:
                        bitRate = 4194304;
                        break;
                        
                    case RESOLUTION_720P:
                        bitRate = 2097152;
                        break;
                        
                    case RESOLUTION_VGA640_480:
                    case RESOLUTION_VGA640_360:
                        bitRate = 1048576;
                        break;
                        
                    case RESOLUTION_QVGA320_240:
                    case RESOLUTION_QVGA320_180:
                        bitRate = 524288;
                        break;
                        
                    default:
                        break;
                }
            }
        }
            break;
            
        case FOSSTREAM_SUB: {
            if (self.isLBR2) {
                switch (resolution) {
                    case RESOLUTION_720P:
                    case RESOLUTION_VGA640_480:
                    case RESOLUTION_VGA640_360:
                        bitRate = 1048576;
                        break;
                        
                    case RESOLUTION_QVGA320_240:
                        bitRate = 524288;
                        break;
                        
                    default:
                        break;
                }
            }
        }
            break;
        default:
            break;
    }
    
    [[self valueForKey:[NSString stringWithFormat:@"bitRate%dBtn",streamType + 1]] selectItemWithTag:bitRate];
}

//根据输入的值，对码率进行调整
- (int)bitRate:(FOSSTREAM_TYPE)streamType withValue :(int)value;
{
    int bRate = value;
    
    if (streamType == FOSSTREAM_SUB) {
        if (value > 1572864)
            value = 2097152;
    }
    
    if (value > 4194304)
        bRate = 6291456;
    else if (value > 3145728 && value <= 4194304)
        bRate = 4194304;
    else if (value > 1572864 && value <= 3145728)
        bRate = 2097152;
    else if (value > 786432 && value <= 1572864)
        bRate = 1048576;
    else if (value > 393216 && value <= 786432)
        bRate = 524288;
    else if (value > 233472 && value <= 393216)
        bRate = [self isNvrIpc:self.streamInfo.model]? 204800 : 262144;
    else if (value > 167936 && value <= 233472)
        bRate = 204800;
    else if (value > 116736 && value <= 167936)
        bRate = 131072;
    else if (value > 76800 && value <= 116736)
        bRate = 102400;
    else if (value > 35840 && value <= 76800)
        bRate = 51200;
    else if (value > 0 && value <= 35840)
        bRate = 20480;
    
    return bRate;
}
#pragma mark - parser 
- (BOOL)resultFromXml :(const char *)xml
{
    NSError *err;
    NSDictionary *dict = [XMLHelper parserCGIXml:[NSString stringWithCString:xml encoding:NSASCIIStringEncoding] error:&err];
    
    if (!err) {
        NSNumber *result = [dict valueForKey:@"result"];
        
        return result? result.intValue == 0 : NO;
    }
    
    return NO;
}


- (BOOL)getStreamListParamExt :(FOS_VIDEOSTREAMLISTPARAM_EXT *)param fromXml :(const char*)xml withStreamType :(int)type
{
    NSError *err;
    NSDictionary *dict = [XMLHelper parserCGIXml:[NSString stringWithCString:xml encoding:NSASCIIStringEncoding] error:&err];
    
    if (!err) {
        int result = [[dict valueForKey:@"result"] intValue];
        
        if (0 == result) {
            
            NSLog(@"xml = %s",xml);
            for (int i = 0; i < FOS_MAX_VIDEOSTREAM_TYPE; i++) {
                param->streamListParam.streamType[i] = type;
                param->streamListParam.resolution[i] = [[dict valueForKey:[NSString stringWithFormat:@"resolution%d",i]] intValue];
                param->streamListParam.bitRate[i] = [[dict valueForKey:[NSString stringWithFormat:@"bitRate%d",i]] intValue];
                param->streamListParam.frameRate[i] = [[dict valueForKey:[NSString stringWithFormat:@"frameRate%d",i]] intValue];
                param->streamListParam.GOP[i] = [[dict valueForKey:[NSString stringWithFormat:@"GOP%d",i]] intValue];
                param->streamListParam.isVBR[i] = [[dict valueForKey:[NSString stringWithFormat:@"isVBR%d",i]] intValue];
                param->streamListExt.lbrRatio[i] = [[dict valueForKey:[NSString stringWithFormat:@"lbrRatio%d",i]] intValue];
            }
            
            return YES;
        }
    }
    
    return  NO;
}

#pragma mark - action
//用户选择视频流类型
- (IBAction)selectVideoStreamType:(id)sender
{
    FOSSTREAM_TYPE streamType = (FOSSTREAM_TYPE)[sender tag];
    [self updateStreamEncoderArgsUI:streamType];
    [self onStreamTypeChanged:streamType];
}

//切换VBR
- (IBAction)vbrChanged:(id)sender
{
    [self updateStreamEncoderExtArgsUI:(FOSSTREAM_TYPE)[sender tag]];
}

//切换分辨率
- (IBAction)resolutionChanged:(id)sender
{
    FOSSTREAM_TYPE streamType = (FOSSTREAM_TYPE)[sender tag];
    [self onResolutionChanged:streamType];
}

#pragma mark - life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
  
    self.videoStreamTypeEnable = YES;
    self.gopEnable = YES;
}

- (void)viewWillAppear
{
    [super viewWillAppear];
    
    [self addObserver:self forKeyPath:@"isLBR1" options:NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:self forKeyPath:@"isLBR2" options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)viewWillDisappear
{
    [super viewWillDisappear];
    
    [self removeObserver:self forKeyPath:@"isLBR1"];
    [self removeObserver:self forKeyPath:@"isLBR2"];
}

#pragma mark - resolution format
- (NSUInteger)bitRateWithByteFromString :(NSString *)str
{
    NSUInteger  bitRate = 0;
    NSUInteger  len     = str.length;
    
    if (len > 0) {
        NSString            *numberPart = [str substringWithRange:NSMakeRange(0,len - 1)];
        NSString            *unitPart   = [str substringWithRange:NSMakeRange(len - 1, 1)];
        NSNumberFormatter   *formatter  = [[NSNumberFormatter alloc] init];
        
        formatter.numberStyle = NSNumberFormatterDecimalStyle;
        NSUInteger          number      = [[formatter numberFromString:numberPart] unsignedIntegerValue];
        //解析
        if ([unitPart isEqualToString:@"M"]) {
            bitRate = number * 1024 * 1024;
        } else if ([str hasSuffix:@"K"]) {
            bitRate = number * 1024;
        }
    }
    
    return bitRate;
}

- (NSString *)stringFromBitRateWithByte :(NSUInteger)resolution
{
    CGFloat bitRateWithK = resolution / 1024.0;
    CGFloat bitRateWithM = bitRateWithK / 1024.0;
    
    if (bitRateWithM < 1.0) {
        return [NSString stringWithFormat:@"%dK",(int)bitRateWithK];
    }
    
    return [NSString stringWithFormat:@"%dM",(int)bitRateWithM];
}

#pragma mark - collect from UI
- (FOS_VIDEOSTREAMPARAM)encoderArgsFromUI:(FOSSTREAM_TYPE)streamType
{
    FOS_VIDEOSTREAMPARAM streamParam;
    memset(&streamParam, 0, sizeof(FOS_VIDEOSTREAMPARAM));
    
    int stream = (int)[[self valueForKey:[NSString stringWithFormat:@"videoStreamType%dBtn",streamType+1]] selectedTag];
    if (stream < FOS_MAX_VIDEOSTREAM_TYPE) {
        streamParam.streamType  = stream;
        
        streamParam.resolution  = (int)[[self valueForKey:[NSString stringWithFormat:@"resolution%dBtn",streamType+1]] selectedTag];
        streamParam.bitRate     = (int)[[self valueForKey:[NSString stringWithFormat:@"bitRate%dBtn",streamType+1]] selectedTag];
        streamParam.frameRate   = (int)[[self valueForKey:[NSString stringWithFormat:@"frameRate%dBtn",streamType+1]] selectedTag];
        streamParam.GOP         = (int)[[self valueForKey:[NSString stringWithFormat:@"gop%dBtn",streamType+1]] selectedTag];
        streamParam.isVBR       = (int)[[self valueForKey:[NSString stringWithFormat:@"isVBR%dBtn",streamType+1]] selectedTag];
    }
    return streamParam;
}



#pragma mark - kvo
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:@"isLBR1"]) {
        [self onVbrChange:FOSSTREAM_MAIN];
    }
    else if ([keyPath isEqualToString:@"isLBR2"]) {
        [self onVbrChange:FOSSTREAM_SUB];
    }
}


#pragma mark - resolution
- (NSString *)nameOfResolution :(FOS_MODESTREAMINFO)info
{
    switch (info) {
        case RESOLUTION_1080P:
            return @"1080P";
            
        case RESOLUTION_960P:
            return @"960P";
            
        case RESOLUTION_720P:
            return @"720P";
            
        case RESOLUTION_VGA640_480:
            return @"VGA(640*480)";
            
        case RESOLUTION_VGA640_360:
            return @"VGA(640*360)";
            
        case RESOLUTION_QVGA320_240:
            return @"QVGA(320*240)";
            
        case RESOLUTION_QVGA320_180:
            return @"QVGA(320*180)";
            
        case RESOLUTION_3M:
            return @"3M";
            
        case RESOLUTION_QHD2560_1440:
            return @"2K";
            
        default:
            break;
    }
    
    return NSLocalizedString(@"Unknow Resolution type", nil);
}

#pragma mark - is nvr ipc
- (BOOL)isNvrIpc :(int)model
{
    return (model==3024 || model==3057 || model==3500 || model==3058);
}

#pragma mark - init frame rate ui with resolution
- (void)initSubFrameRateBtnWithStreamInfo :(FOS_STREAMINFO)streamInfo
{
    int maxFrameRate = 30;
    int tag = (int)[self.resolution2Btn selectedTag];//对应该模式下分辨率类型
    
    if (streamInfo.model > 5000 && streamInfo.model < 6000) {
        maxFrameRate = (tag == RESOLUTION_720P)? 11 : 20;
    }
    else if (streamInfo.model > 3000 && streamInfo.model < 4000) {
        maxFrameRate = (tag == RESOLUTION_720P)? 10 : 15;
    }
    else if (streamInfo.model > 5000 && streamInfo.model < 6000) {
        maxFrameRate = (tag == RESOLUTION_720P)? 11 : 20;
    }
    else if (streamInfo.model >= 6000 && streamInfo.model < 7000) {
        maxFrameRate = (tag == RESOLUTION_720P)? 15 : 30;
    }
    
    [self.frameRate2Btn removeAllItems];
    
    for (int i = 1; i <= maxFrameRate; i++) {
        [self.frameRate2Btn addItemWithTitle:[NSString stringWithFormat:@"%d",i]];
        [self.frameRate2Btn lastItem].tag = i;
    }
}

- (void)initFrameRate:(FOSSTREAM_TYPE)type
{
    int maxFrameRate = 30;
    NSPopUpButton *btn = nil;
    FOS_STREAMINFO info = self.streamInfo;
    
    switch (type) {
        case FOSSTREAM_MAIN: {
            btn = self.frameRate1Btn;
            FOS_MODESTREAMINFO resolution = (FOS_MODESTREAMINFO)[self.resolution1Btn selectedTag];
            
            if (info.model > 5000 && info.model < 6000) {
                switch (resolution) {
                    case RESOLUTION_QHD2560_1440:
                        maxFrameRate = 15;
                        break;
                        
                    case RESOLUTION_1080P:
                    case RESOLUTION_3M:
                        maxFrameRate = 25;
                        break;
                        
                    default:
                        maxFrameRate = 30;
                }
            }
            else if (info.model >3000 && info.model < 4000) {
                if (![self isNvrIpc:info.model]) {
                    maxFrameRate = (resolution == RESOLUTION_720P)? 23 : 25;
                }
                else {
                    maxFrameRate = 19;
                }
            }
            else if (info.model >= 6000 && info.model < 7000) {
                maxFrameRate = 30;
            }
        }
            break;
            
        case FOSSTREAM_SUB: {
            btn = self.frameRate2Btn;
            FOS_MODESTREAMINFO resolution = (FOS_MODESTREAMINFO)[self.resolution2Btn selectedTag];
            
            if (info.model > 5000 && info.model < 6000) {
                maxFrameRate = (resolution == RESOLUTION_720P)? 11 : 20;
            }
            else if (info.model > 3000 && info.model < 4000) {
                maxFrameRate = (resolution == RESOLUTION_720P)? 10 : 15;
            }
            else if (info.model > 5000 && info.model < 6000) {
                maxFrameRate = (resolution == RESOLUTION_720P)? 11 : 20;
            }
            else if (info.model >= 6000 && info.model < 7000) {
                maxFrameRate = (resolution == RESOLUTION_720P)? 15 : 30;
            }
        }
            break;
        default:
            break;
    }
    
    [btn removeAllItems];
    
    for (int i = 1; i <= maxFrameRate; i++) {
        [btn addItemWithTitle:[NSString stringWithFormat:@"%d",i]];
        [btn lastItem].tag = i;
    }
}

#pragma mark - init stream ui with streamInfo
- (void)initStreamUI
{
    [self initBitRate];
    [self initResolution];
    [self initVBR];
}

- (void)initResolution :(FOSSTREAM_TYPE)streamType
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Resolutions" ofType:@"plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
    NSArray *keys = @[@"MainStream",@"SubStream"];
    NSMutableArray *resolutions = [dict valueForKey:keys[streamType]];
    
    if (resolutions) {
        //根据sensor
        NSArray *sensortype_1080p = @[@8,@9,@10,@11,@12,@15,@16,@17];
        NSArray *sensortype_960p  = @[@6,@8,@9];
        NSArray *sensortype_3M_2K = @[@11];
        NSNumber *sensortype = [NSNumber numberWithInt:self.streamInfo.sensorType];
        
        if (![sensortype_1080p containsObject:sensortype]) {
            [resolutions removeObject:[NSNumber numberWithInt:RESOLUTION_1080P]];
        }
        
        if (![sensortype_960p containsObject:sensortype]) {
            [resolutions removeObject:[NSNumber numberWithInt:RESOLUTION_960P]];
            
            if (self.streamInfo.model > 5000 && self.streamInfo.model < 6000) {
                [resolutions removeObject:[NSNumber numberWithInt:RESOLUTION_QVGA320_180]];
            }
        }
        
        if (![sensortype_3M_2K containsObject:sensortype]) {
            [resolutions removeObject:[NSNumber numberWithInt:RESOLUTION_3M]];
            [resolutions removeObject:[NSNumber numberWithInt:RESOLUTION_QHD2560_1440]];
        }
        
        //根据model
        if (FOSSTREAM_SUB == streamType) {
            if (self.streamInfo.model >= 6000 && self.streamInfo.model < 7000) {
                [resolutions removeObject:[NSNumber numberWithInt:RESOLUTION_720P]];
            }
            
            if (self.streamInfo.model >= 2001 && self.streamInfo.model < 3000) {
                [resolutions removeObject:[NSNumber numberWithInt:RESOLUTION_720P]];
                [resolutions removeObject:[NSNumber numberWithInt:RESOLUTION_VGA640_480]];
                [resolutions removeObject:[NSNumber numberWithInt:RESOLUTION_VGA640_360]];
            }
            
            if (self.streamInfo.model > 1000 && self.streamInfo.model < 2000) {
                [resolutions removeObject:[NSNumber numberWithInt:RESOLUTION_720P]];
            }
            
            if (self.streamInfo.model > 3000 && self.streamInfo.model < 4000) {
                if (![self isNvrIpc:self.streamInfo.model]) {
                    [resolutions removeObject:[NSNumber numberWithInt:RESOLUTION_VGA640_480]];
                    [resolutions removeObject:[NSNumber numberWithInt:RESOLUTION_VGA640_360]];
                }
                
                [resolutions removeObject:[NSNumber numberWithInt:RESOLUTION_720P]];
            }
            
            [resolutions removeObject:[NSNumber numberWithInt:RESOLUTION_960P]];
            [resolutions removeObject:[NSNumber numberWithInt:RESOLUTION_1080P]];
        }
        
        NSPopUpButton *btn = [self valueForKey:[NSString stringWithFormat:@"resolution%dBtn",streamType + 1]];
        [btn removeAllItems];
        for (int i = 0; i < resolutions.count; i++) {
            FOS_MODESTREAMINFO si = [[resolutions objectAtIndex:i] intValue];
            [btn addItemWithTitle:[self nameOfResolution:si]];
            [btn lastItem].tag = si;
        }
    }
}

- (void)initBitRate
{
    NSMutableArray *bitrateName  = [@[@"6M",@"4M",@"2M"  ,@"1M"  ,@"512K",@"256K",@"200K",@"128K",@"100K",@"50K",@"20K"] mutableCopy];
    NSMutableArray *bitrateName1 = [@[@"2M",@"1M",@"512K",@"256K",@"200K",@"128K",@"100K",@"50K" ,@"20K"] mutableCopy];
    int sensortype_3M_2K[]={11,-1};
    
    //根据model进行过滤
    if(self.streamInfo.model >= 6000 && self.streamInfo.model < 7000) {
        [bitrateName1 removeObject:@"2M"];
        [bitrateName1 removeObject:@"1M"];
    }
    else if (self.streamInfo.model > 5000 && self.streamInfo.model < 6000) {
        [bitrateName removeObject:@"50K"];
        [bitrateName removeObject:@"20K"];
    }
    else if (self.streamInfo.model > 3000 && self.streamInfo.model < 4000) {
        if(![self isNvrIpc:self.streamInfo.model]){
            [bitrateName1 removeObject:@"512K"];
            [bitrateName1 removeObject:@"1M"];
        }
        [bitrateName removeObject:@"4M"];
        [bitrateName removeObject:@"256K"];
        [bitrateName removeObject:@"128K"];
        [bitrateName1 removeObject:@"256K"];
        [bitrateName1 removeObject:@"128K"];
        [bitrateName1 removeObject:@"2M"];
    }
    else if (self.streamInfo.model >= 2001 && self.streamInfo.model < 3000) {
        [bitrateName removeObject:@"256K"];
        [bitrateName removeObject:@"128K"];
        [bitrateName1 removeObject:@"128K"];
        [bitrateName1 removeObject:@"256K"];
        [bitrateName1 removeObject:@"512K"];
    }
    else if (self.streamInfo.model > 1000 && self.streamInfo.model < 2000) {
        [bitrateName1 removeObject:@"2M"];
        [bitrateName1 removeObject:@"1M"];
        
        if (self.streamInfo.model == 1111 || self.streamInfo.model == 1112) {
            [bitrateName removeObject:@"50K"];
            [bitrateName removeObject:@"20K"];
        }
    }
    
    //根据sensor进行过滤
    BOOL flag = YES;
    for (int i = 0;; i++) {
        if (sensortype_3M_2K[i] == -1) {
            break;
        }
        
        if (self.streamInfo.sensorType == sensortype_3M_2K[i]) {
            flag = false;
            break;
        }
    }
    
    if(flag) {
        [bitrateName removeObject:@"6M"];
    }
    
    [self.bitRate1Btn removeAllItems];
    [self.bitRate2Btn removeAllItems];
    
    for (int i = 0; i < bitrateName.count;i++) {
        NSString *title = bitrateName[i];
        
        [self.bitRate1Btn addItemWithTitle:title];
        [self.bitRate1Btn lastItem].tag = [self bitRateWithByteFromString :title];
    }
    
    for (int i = 0; i < bitrateName1.count; i++) {
        NSString *title = bitrateName1[i];
        
        [self.bitRate2Btn addItemWithTitle:title];
        [self.bitRate2Btn lastItem].tag = [self bitRateWithByteFromString:title];
    }
}

- (void)initResolution
{
    [self initResolution:FOSSTREAM_MAIN];
    [self initResolution:FOSSTREAM_SUB];
}

- (void)initVBR
{
    NSArray *contents = nil;
    NSString *label = nil;
    
    if (self.streamInfo.model > 5000 && self.streamInfo.model < 6000) {
        label = [NSLocalizedString(@"Rate Control Mode", nil) stringByAppendingString:@":"];
        contents = @[@"CBR",@"VBR",@"LBR"];
        
        self.vbrTF1.hidden = NO;
        self.vbrTF2.hidden = NO;
        self.isVBR1Btn.hidden = NO;
        self.isVBR2Btn.hidden = NO;
    }
    else {
        label = [NSLocalizedString(@"Variable bitrate", nil) stringByAppendingString:@":"];
        contents = @[NSLocalizedString(@"No", nil),
                     NSLocalizedString(@"Yes", nil)];
        
        self.vbrTF1.hidden = NO;
        self.vbrTF2.hidden = YES;
        self.isVBR1Btn.hidden = NO;
        self.isVBR2Btn.hidden = YES;
    }
    
    self.vbrTF1.stringValue = label;
    self.vbrTF2.stringValue = label;
    
    [self.isVBR1Btn removeAllItems];
    [self.isVBR2Btn removeAllItems];
    for (int i = 0; i < contents.count; i++) {
        [self.isVBR1Btn addItemWithTitle:contents[i]];
        [self.isVBR2Btn addItemWithTitle:contents[i]];
        [self.isVBR1Btn.lastItem setTag:i];
        [self.isVBR2Btn.lastItem setTag:i];
    }
}

#pragma mark - update stream ui with param list
- (void)updateStreamEncoderArgsUI :(FOSSTREAM_TYPE)streamType
{
    FOS_VIDEOSTREAMLISTPARAM lists[2] = {
        self.videoStreamListParam,
        self.videoSubStreamListParam
    };
    
    
    int stream = (int)[[self valueForKey:[NSString stringWithFormat:@"videoStreamType%dBtn",streamType + 1]] selectedTag];
  
    if (stream < FOS_MAX_VIDEOSTREAM_TYPE) {
        int bitRate = [self bitRate:streamType withValue:lists[streamType].bitRate[stream]];
        
        [[self valueForKey:[NSString stringWithFormat:@"bitRate%dBtn",streamType + 1]] selectItemWithTag:bitRate];
        [[self valueForKey:[NSString stringWithFormat:@"frameRate%dBtn",streamType + 1]] selectItemWithTag:lists[streamType].frameRate[stream]];
        [[self valueForKey:[NSString stringWithFormat:@"isVBR%dBtn",streamType + 1]] selectItemWithTag:lists[streamType].isVBR[stream]];
        [[self valueForKey:[NSString stringWithFormat:@"gop%dBtn",streamType + 1]] selectItemWithTag:lists[streamType].GOP[stream]];
        [[self valueForKey:[NSString stringWithFormat:@"resolution%dBtn",streamType + 1]] selectItemWithTag:lists[streamType].resolution[stream]];
        [self onResolutionChanged:streamType];
    }
}

- (void)updateStreamEncoderExtArgsUI :(FOSSTREAM_TYPE)streamType
{
    FOS_VIDEOSTREAMLISTEXT lists[2] = {
        self.videoStreamListExt,
        self.videoSubStreamListExt
    };
    
    BOOL    isAnba  = (self.streamInfo.model > 5000 && self.streamInfo.model < 6000);
    int     stream  = (int)[[self valueForKey:[NSString stringWithFormat:@"videoStreamType%dBtn",streamType + 1]] selectedTag];
    BOOL    isLBR   = ([[self valueForKey:[NSString stringWithFormat:@"isVBR%dBtn",streamType + 1]] selectedTag] == 2) && isAnba;
    
    if (stream < FOS_MAX_VIDEOSTREAM_TYPE) {
        [self setValue:[NSNumber numberWithBool:isLBR] forKey:[NSString stringWithFormat:@"isLBR%d",streamType + 1]];
        [self setValue:[NSNumber numberWithInt:lists[streamType].lbrRatio[stream]] forKey:[NSString stringWithFormat:@"lbr%d",streamType + 1]];
    }
}

#pragma mark - setter & getter
- (void)setControl :(NSPopUpButton *)btn withRange :(NSRange)range
{
    [btn removeAllItems];
    for (int i = 0; i < range.length; i++) {
        NSString *title = [NSString stringWithFormat:@"%2d",(int)range.location + i];
        [btn addItemWithTitle:title];
        [btn lastItem].tag = range.location + i;
    }
}

- (void)setStreamInfo:(FOS_STREAMINFO)streamInfo
{
    _streamInfo = streamInfo;
    [self initStreamUI];
}

- (void)setVideoStreamListParam:(FOS_VIDEOSTREAMLISTPARAM)videoStreamListParam
{
    _videoStreamListParam = videoStreamListParam;
    [self updateStreamEncoderArgsUI:FOSSTREAM_MAIN];
}

- (void)setVideoStreamListExt:(FOS_VIDEOSTREAMLISTEXT)videoStreamListExt
{
    _videoStreamListExt = videoStreamListExt;
    [self updateStreamEncoderExtArgsUI:FOSSTREAM_MAIN];
}

- (void)setVideoSubStreamListParam:(FOS_VIDEOSTREAMLISTPARAM)videoSubStreamListParam
{
    _videoSubStreamListParam = videoSubStreamListParam;
    
    [self initSubFrameRateBtnWithStreamInfo:self.streamInfo];
    [self updateStreamEncoderArgsUI:FOSSTREAM_SUB];
}

- (void)setVideoSubStreamListExt:(FOS_VIDEOSTREAMLISTEXT)videoSubStreamListExt
{
    _videoSubStreamListExt = videoSubStreamListExt;
    [self updateStreamEncoderExtArgsUI:FOSSTREAM_SUB];
}

- (void)setGop1Btn:(NSPopUpButton *)gop1Btn
{
    _gop1Btn = gop1Btn;
    [self setControl:_gop1Btn withRange:[self gopRange]];
}

- (void)setGop2Btn:(NSPopUpButton *)gop2Btn
{
    _gop2Btn = gop2Btn;
    [self setControl:_gop2Btn withRange:[self gopRange]];
}

- (void)setControl :(NSPopUpButton *)btn withFrameRate :(int)frameRate
{
    [btn removeAllItems];
    for (int i = 1; i <= frameRate;i++)
    {
        NSString *title = [NSString stringWithFormat:@"%d",i];
        [btn addItemWithTitle:title];
    }
}

#pragma mark - NSPopupButton Data
- (NSRange)gopRange
{
    return NSMakeRange(10, 90);
}

@end
