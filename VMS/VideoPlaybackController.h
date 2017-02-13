//
//  VideoPlaybackController.h
//  VMS
//
//  Created by mac_dev on 15/6/2.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MultyVideoViewsManager.h"
#import "JFButton.h"
#import "JFBackground.h"
#import "TimeTableView.h"
#import "NSDate + SRAdditions.h"
#import "CheckboxHeaderCell.h"
#import "NSButton+BTSButton.h"
#import "TFDatePicker.h"
#import "VideoPlayer.h"
#import "AppDelegate.h"
#import "VMSTabView.h"
#import "VMSPathManager.h"

@interface ChannelPlaybackInfo : NSObject

@property (nonatomic,assign) int port;
- (id)init;
@end

@interface VideoPlaybackController : NSViewController
<
NSTableViewDataSource,
NSTableViewDelegate,
TimeTableViewDelegate,
NSSplitViewDelegate,
VideoPlayerProtocol,
NSOpenSavePanelDelegate,
VMSTabViewDelegate,
MVVMDelegate,
TabMVCProtocol
>

@property (nonatomic,strong) MultyVideoViewsManager *multyVideoViewsManager;
@property (strong,nonatomic) VideoPlayer *videoPlayer;
@property (weak,nonatomic) IBOutlet NSView *placeHolder;
@property (weak,nonatomic) IBOutlet NSTableView *tableView;
@property (weak,nonatomic) IBOutlet TimeTableView *timeTableView;
@property (weak,nonatomic) IBOutlet NSScrollView *scrollView;
@property (weak,nonatomic) IBOutlet NSButton *findVideos;
@property (weak,nonatomic) IBOutlet NSButton *seekVideos;
@property (weak,nonatomic) IBOutlet JFBackground *seekVideosZone;
@property (weak,nonatomic) IBOutlet TFDatePicker *datePicker;
@property (weak,nonatomic) IBOutlet NSDatePicker *timePicker;
@property (weak,nonatomic) IBOutlet NSButton *scheduledVideo;
@property (weak,nonatomic) IBOutlet NSButton *manualVideo;
@property (weak,nonatomic) IBOutlet NSButton *alarmVideo;
@property (weak,nonatomic) IBOutlet NSButton *motionDetectingVideo;

- (void)performFindVideos;
- (void)performSeekDate;
@end
