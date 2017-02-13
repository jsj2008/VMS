//
//  VideoViewController.h
//  VMS
//
//  Created by mac_dev on 15/5/21.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import "JFOpenGLView.h"
#import "DispatchCenter.h"
#import "JFButton.h"
#import "Image+Clip.h"
#import "../libplay/libplay/avplay_sdk.h"
#import "RecordCenter.h"
#import "VideoPlayer.h"
#import "AudioGrabber.h"
#import "NSImage+SaveAsJpegWithName.h"
#import "NSImage+Flip.h"
#import "NSDate + SRAdditions.h"
#import "VMSAlarmController.h"
#import "VideoViewProtocol.h"
#import "AVPLAYLayer.h"

#define VIDEO_VIEW_TOOLBAR_STATE_CHANGE_NOTIFICATION    @"videoViewToolbarButtonStateChangeNotification"
#define KEY_VIDEO_VIEW_TOOLBAR_BTN_STATE                @"videoViewToolbarButtonState"
#define KEY_VIDEO_VIEW_TOOLBAR_CMD                      @"videoViewToolbarCommand"

#define STREAM_START_PORT   0
#define FILE_START_PORT     64

typedef NS_ENUM(NSUInteger, VIDEO_STATE) {
    NO_VIDEO,
    CONNECTING,
    VIDEO_PLAYING,
    CONNECT_FAILED,
    DISCONNECTED,
};

typedef NS_ENUM(NSUInteger, VVTB_CMD) {
    VVTB_SNAP = 0,
    VVTB_SOUND,
    VVTB_RECORD,
    VVTB_CLOSE,
    VVTB_TAKL,
    VVTB_ALARM,
    VVIB_NULL
};


@interface VideoViewController : NSViewController
<
AudioGrabberProtocol,
VideoViewProtocol
>


@property (nonatomic,assign,readonly) int type;//AVPLAY_TYPE_FILE | AVPLAY_TYPE_STREAM
@property (nonatomic,assign) BOOL needDisplayToolbar;
@property (nonatomic,assign) FOSSTREAM_TYPE streamType;
@property (nonatomic,assign,getter = isInSingleWndMode) BOOL inSignleWndMode;
@property (nonatomic,strong) Group *group;
@property (nonatomic,strong) Channel *curChannel;
@property (nonatomic,strong) CDevice *device;
@property (nonatomic,assign) VIDEO_STATE videoState;
@property (nonatomic,assign) int port;
@property (nonatomic,assign,readonly) int viewId;
@property (nonatomic,assign) int viewState;

- (id)initWithNibName :(NSString *)nibNameOrNil
               bundle :(NSBundle *)nibBundleOrNil
               viewId :(int)viewId
                 type :(int)type;

- (void)setVideoState :(VIDEO_STATE)state;
- (void)showSnapResult :(bool)success;
- (void)render;
- (BOOL)snap :(int)type;
- (void)closeRecord;

@end
