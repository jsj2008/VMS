//
//  MotionDetectViewController.h
//  
//
//  Created by mac_dev on 16/5/25.
//
//

#import "SettingViewController.h"
#import "TimePickerView/TimePickerView.h"
#import "DetectionAreasEditWindowController.h"
#import "HsDetectionAreaEditWindowController.h"
#import "AmbaDetectionAreaEditWindowController.h"

#define KEY_LINKAGE_NAME    @"linkage_name"
#define KEY_LINKAGE_VALUE   @"linkage_value"

@interface MotionDetectViewController : SettingViewController

@property (nonatomic,assign) FOS_MOTIONDETECTCONFIG hsMotionDetectConfig;
@property (nonatomic,assign) FOS_MOTIONDETECTCONFIG1 ambaMotionDetectConfig;
@property (nonatomic,assign) BOOL isEnablePCAudioAlarm;
@property (nonatomic,assign) BOOL isEnableSnap;
@property (nonatomic,assign) BOOL isEnableRecord;
@property (nonatomic,assign) int recordTime;

//这些方法需要重写
- (void)fetch;
- (void)push;
- (void)fetchHsMotionConfig;
- (void)fetchAmbaMotionConfig;
- (void)pushHsDetectConfig;
- (void)pushAmbaDetectConfig;
- (NSString *)description;

//界面获取
- (FOS_MOTIONDETECTCONFIG1)ambaMotionDetectConfigFromUI;
- (FOS_MOTIONDETECTCONFIG)hsMotionDetectConfigFromUI;
- (int)recordTimeFromUI;

//重写下面的方法用来初始化UI
- (NSString *)audioAlarmTitle;
- (NSArray *)linkages;//联动策略


//重写该方法，用来控制使用的区域编辑窗口
- (DetectionAreasEditWindowController *)daewc;
- (void)onEditDone :(void *)cfg;

//重写该
@end
