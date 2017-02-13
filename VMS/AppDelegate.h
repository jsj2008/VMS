//
//  AppDelegate.h
//  VMS
//
//  Created by mac_dev on 15/5/19.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "INAppStoreWindow.h"
#import "DispatchCenter.h"
#import "RecordCenter.h"
#import "JFPreferencePanelController.h"
#import "JFPreferencePanelController+StartUp.h"
#import "SystemSettingSheetController.h"
#import "NSDate + SRAdditions.h"
#import "LBProgressBar.h"
#import "VMSLoginPanelController.h"
#import "LogQuerySheetController.h"
#import "VMSBasicSetting.h"
#import "VMSRecordSetting.h"
#import "VMSPathManager.h"
#import "VMSAlarmController.h"



#define VMS_LOCKED_ALERT \
do { \
AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];\
    if (appDelegate.isAppLocked) { \
        [appDelegate.alert setMessageText:@"应用程序已经上锁"]; \
        [appDelegate.alert setInformativeText:@"请先解锁"]; \
        [appDelegate.alert beginSheetModalForWindow:appDelegate.window completionHandler:NULL];\
    return; \
    } \
}while (0)

#define NIB_ADD_DEVICE_SHEET                @"AddDeviceSheetController"

@interface CustomTitleView : NSView

- (void)drawRect:(NSRect)dirtyRect;
@end


@class VideoMonitoringController;
@class VideoPlaybackController;
@class NvrVideoPBViewController;

@protocol TabMVCProtocol <NSObject>
//当tab页面发生切换时，发送给当前tab该消息，告知即将切换
- (void)willTab :(NSNotification *)aNotific stop :(BOOL *)stop;
@end

@interface AppDelegate : NSObject <NSApplicationDelegate,NSWindowDelegate>

@property (weak,nonatomic) IBOutlet NSWindow *window;
@property (strong,nonatomic) VideoPlaybackController *playbackViewController;
@property (strong,nonatomic) NvrVideoPBViewController *nvrPBViewController;
@property (strong,nonatomic) VideoMonitoringController *monitoringViewController;
@property (strong,nonatomic) VMSAlarmController *alarmController;
@property (weak,nonatomic) IBOutlet NSButton *toolbarItemMonitoring;
@property (weak,nonatomic) IBOutlet NSButton *toolbarItemPlayback;
@property (weak,nonatomic) IBOutlet NSButton *toolbarItemLog;
@property (weak,nonatomic) IBOutlet NSButton *toolbarItemNvrPlayback;
//@property (nonatomic,strong) SystemSettingSheetController *systemSettingSheetController;
@property (strong) VMSUser *currentUser;
@property (assign,readonly,getter = isAppLocked) BOOL appLocked;
@property (nonatomic,strong) NSAlert *alert;

- (IBAction)addDevice :(id)sender;

@end

