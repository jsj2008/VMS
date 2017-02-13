//
//  VideoMonitoringController.h
//  VMS
//
//  Created by mac_dev on 15/6/2.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "AppDelegate.h"
#import "VMSDatabase.h"
#import "DispatchCenter.h"
#import "MultyVideoViewsManager.h"
#import "JFBackground.h"
#import "PTZButton.h"
#import "DragView.h"
#import "VMSTabView.h"
#import "Image+Clip.h"
#import "DMSplitView.h"
#import "NSButton+BTSButton.h"
#import "AddDeviceSheetController.h"
#import "DeviceSettingSheetController.h"

#import "DeviceConnectionSettingSheetController.h"
#import "AddPollingGroupSheetController.h"
#import "AddDeviceGroupSheetController.h"
#import "GeneralViewController.h"


typedef struct {
    int cnt[2];
}PREVIEW_CANCEL_CNT;

@interface DeviceState : NSObject

@property(nonatomic,assign,getter = isOnline) BOOL online;
@property(nonatomic,assign,getter = isConnecting) BOOL connecting;

- (instancetype)init;
@end




@interface PreviewObjState : NSObject<NSCoding>
@property (nonatomic,assign) int viewId;//当前分配的窗口号

@property (nonatomic,assign,getter = isPlay) BOOL play;
@property (nonatomic,assign,getter = isAutoPlay) BOOL autoPlay;

- (instancetype)init;
- (instancetype)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;
@end




@interface ChannelState : PreviewObjState
@property (assign,getter = isOnline) BOOL online;
@property (nonatomic,assign) int connected;//是否已经连接
@property (nonatomic,assign) int connectings;//是否正在连接
@property (nonatomic,assign) PREVIEW_CANCEL_CNT cancelCtn;//取消次数

- (instancetype)init;
- (instancetype)initWithCoder:(NSCoder *)aDecoder;
@end




@interface PollingState : PreviewObjState

@property (nonatomic,assign) int sequenceNum;//轮巡次序
@property (nonatomic,strong) NSTimer *timer;

- (instancetype)init;
- (instancetype)initWithCoder:(NSCoder *)aDecoder;
@end




@interface VideoMonitoringController : NSViewController
<
DispatchProtocal,
DragViewDelegate,
PTZButtonDelegate,
VMSTabViewDelegate,
MVVMDelegate,
TabMVCProtocol
>

@property (strong ,nonatomic) MultyVideoViewsManager *multyVideoViewsManager;

- (void)archive;
- (void)unArchive;

@end
