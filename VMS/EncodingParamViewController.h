//
//  EncodingParamViewController.h
//  
//
//  Created by mac_dev on 16/5/23.
//
//

#import "SettingViewController.h"


typedef struct VideoStreamListExt
{
    int lbrRatio[FOS_MAX_VIDEOSTREAM_TYPE];
}FOS_VIDEOSTREAMLISTEXT;

typedef struct VideoStreamListParamExt
{
    FOS_VIDEOSTREAMLISTPARAM streamListParam;
    FOS_VIDEOSTREAMLISTEXT streamListExt;
}FOS_VIDEOSTREAMLISTPARAM_EXT;


@interface EncodingParamViewController : SettingViewController

@property (assign,nonatomic) FOS_STREAMINFO streamInfo;
//@property (assign,nonatomic) FOS_STREAMFRAMEPARAMINFO streamFrameInfo;
@property (assign,nonatomic) FOS_VIDEOSTREAMLISTPARAM videoStreamListParam;
@property (assign,nonatomic) FOS_VIDEOSTREAMLISTPARAM videoSubStreamListParam;
@property (assign,nonatomic) FOS_VIDEOSTREAMLISTEXT videoStreamListExt;
@property (assign,nonatomic) FOS_VIDEOSTREAMLISTEXT videoSubStreamListExt;

@property (assign,nonatomic) BOOL videoStreamTypeEnable;
@property (assign,nonatomic) BOOL gopEnable;
@property (nonatomic,weak) IBOutlet NSPopUpButton *resolution1Btn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *resolution2Btn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *frameRate1Btn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *frameRate2Btn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *bitRate1Btn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *bitRate2Btn;

@property (nonatomic,assign) BOOL isLBR1;
@property (nonatomic,assign) BOOL isLBR2;

- (void)fetch;
- (void)push;
- (NSString *)description;
- (void)setControl :(NSPopUpButton *)btn withFrameRate :(int)frameRate;
- (FOS_VIDEOSTREAMPARAM)encoderArgsFromUI:(FOSSTREAM_TYPE)streamType;
//重写下面的方法
- (void)onResolutionChanged:(FOSSTREAM_TYPE)streamType;
- (void)onStreamTypeChanged:(FOSSTREAM_TYPE)streamType;
- (int)bitRate:(FOSSTREAM_TYPE)streamType withValue :(int)value;
@end
