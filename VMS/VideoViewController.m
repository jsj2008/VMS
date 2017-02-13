//
//  VideoViewController.m
//  VMS
//
//  Created by mac_dev on 15/5/21.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "VideoViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import "../SDL2-2.0.3/include/SDL.h"

#define VIEWID_WIDTH    48.0
#define TOOLBAR_HEIGHT  16.0
#define BORDER_WIDTH    1
#define debug   0



@interface VideoViewController ()

@property (nonatomic,weak) IBOutlet NSTextField *viewIdTF;
@property (nonatomic,weak) IBOutlet NSTextField *videoInfoTF;
@property (nonatomic,weak) IBOutlet NSTextField *videoStateTextField;

@property (nonatomic,weak) IBOutlet NSButton *listen;
@property (nonatomic,weak) IBOutlet NSButton *snap;
@property (nonatomic,weak) IBOutlet NSButton *record;
@property (nonatomic,weak) IBOutlet NSButton *recording;
@property (nonatomic,weak) IBOutlet NSButton *talk;
@property (nonatomic,weak) IBOutlet NSButton *close;
@property (nonatomic,weak) IBOutlet NSButton *alarm;

@property (nonatomic,assign) BOOL talkable;
@property (nonatomic,assign,getter=isAlarming) BOOL alarming;
@property (nonatomic,assign,readwrite) int type;
@property (readwrite) int viewId;



@end


@implementation VideoViewController


#pragma mark - init
- (void)awakeFromNib
{
    [self.view addObserver:self forKeyPath:@"frame" options:0 context:NULL];
}

- (void)dealloc
{
    NSLog(@"Running in %@,'%@'",self.className,NSStringFromSelector(_cmd));
    
    [self.view removeObserver:self forKeyPath:@"frame"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
               viewId:(int)viewId
                 type:(int)type
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.type = type;
        self.needDisplayToolbar = YES;
        self.curChannel = nil;
        self.viewId = viewId;
        self.videoState = NO_VIDEO;
        self.port = -1;
        
        AVPLAYLayer *glLayer = [[AVPLAYLayer alloc] init];
        if (glLayer) {
            self.view.wantsLayer = YES;
            self.view.layer = glLayer;
        }
        else {
            NSLog(@"failed to init openGLVidGridLayer");
            exit(0);
        }
    }
    return self;
}


#pragma mark - life cycle
- (void)onViewLoad
{
    //接受消息
    if (self.type == AVPLAY_TYPE_STREAM) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onDispatchCenterNotification:)
                                                     name:CONNECTION_STATE_DID_CHANGE_NOTIFICATION
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onDispatchCenterNotification:)
                                                     name:ALARM_STATE_DID_CHANGE_NOTIFICATION
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onRecordCenterNotification:)
                                                     name:RECORD_STATE_DID_CHANGE_NOTIFICATION
                                                   object:nil];
    }
}

- (void)loadView
{
    [super loadView];
    
    if (NSAppKitVersionNumber < NSAppKitVersionNumber10_10) {
        [self onViewLoad];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self onViewLoad];
}

- (void)observeValueForKeyPath :(NSString *)keyPath
                      ofObject :(id)object
                        change :(NSDictionary *)change
                       context :(void *)context
{
    if (object == self.view) {
        [self layout];
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.needDisplayToolbar = YES;
    }
    return self;
}

#pragma mark - notification
- (void)onDispatchCenterNotification :(NSNotification *)aNotific
{
    NSString        *name = aNotific.name;
    NSDictionary    *userInfo = aNotific.userInfo;
    long devId = [[userInfo valueForKey:KEY_EVENT_DEVICE_ID] longValue];
    
    if ([name isEqualToString:CONNECTION_STATE_DID_CHANGE_NOTIFICATION]) {
        //解析通知
        int  logicId = [[userInfo valueForKey:KEY_EVENT_CHANNEL_ID] intValue];
        BOOL state  = [[userInfo valueForKey:KEY_EVENT_CONNECTION_STATE] boolValue];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( self.curChannel &&
                (self.curChannel.logicId == logicId) &&
                (self.device.uniqueId == devId)) {
                [self setVideoState:state?VIDEO_PLAYING : DISCONNECTED];
                
                if (state)
                    [self setVideoState:VIDEO_PLAYING];
                else {
                    [self setVideoState:DISCONNECTED];
                    
                    //关闭音频
                    AVPLAY_Listen(self.port, false);
                    
                    //改变状态
                    [self onAudioStateChange:0];
                    [self onTalkStateChange:0];
                }
            }
        });
    }
    else if ([name isEqualToString:ALARM_STATE_DID_CHANGE_NOTIFICATION]) {
        int  logicId = [[aNotific.userInfo valueForKey:KEY_EVENT_CHANNEL_ID] intValue];
        BOOL state = [[aNotific.userInfo valueForKey:KEY_ALARM_STATE] boolValue];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.curChannel &&
                !self.group &&
                (self.curChannel.logicId == logicId) &&
                self.device.uniqueId == devId) {
                self.alarming = state;
            }
        });
    }
}

- (void)onRecordCenterNotification :(NSNotification *)aNotific
{
    NSString *name = aNotific.name;
    NSDictionary *dict = [aNotific userInfo];
    
    if ([name isEqualToString:RECORD_STATE_DID_CHANGE_NOTIFICATION]) {
        int cId = [[dict valueForKey:KEY_RECORD_CHID] intValue];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( self.curChannel &&
                (self.curChannel.uniqueId == cId)) {
                //向中心发起查询
                [self updateRecordingState];
                [self updateManualRecordState];
            }
        });
    }
}

- (void)updateRecordingState
{
    if (self.curChannel) {
        int cId   = self.curChannel.uniqueId;
        int state = [[RecordCenter sharedRecordCenter] queryStateWithChannelId:cId recordType:AllRecord];
        
        self.recording.image = [NSImage imageNamed:(state == RECORD_ON)? @"Recording On" : @"Recording Off"];
    }
}

- (void)updateManualRecordState
{
    if (self.curChannel && !self.group) {
        int cId   = self.curChannel.uniqueId;
        int state = [[RecordCenter sharedRecordCenter] queryStateWithChannelId:cId recordType:ManualRecord];
        
        self.record.enabled = !(state == RECORD_CONNECTING);
        self.record.state = (state == RECORD_ON);
    }
}

#pragma mark - public method
- (void)closeRecord
{
    if (self.type == AVPLAY_TYPE_STREAM) {
        [[RecordCenter sharedRecordCenter] switchRecordingState:NO
                                                  withChannelId:self.curChannel? self.curChannel.uniqueId : -1
                                                           type:ManualRecord];
    }
}

- (void)showSnapResult :(bool)success
{
    NSString *newTitle = success? NSLocalizedString(@"capture success", nil) : NSLocalizedString(@"capture failed", nil);
    NSString *oldTitle = self.videoInfoTF.stringValue;
    
    self.videoInfoTF.stringValue = newTitle;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSString *curTitle = self.videoInfoTF.stringValue;
        if ([curTitle isEqualToString:newTitle]) {
            self.videoInfoTF.stringValue = oldTitle;
        }
    });
}

+ (NSString *)capturePath
{
    VMSBasicSetting *basicSetting = [[VMSBasicSetting alloc] initWithPath:[VMSPathManager vmsConfPath:YES]];
    return [basicSetting.capturePathName stringByAppendingPathComponent:[[[NSBundle mainBundle] bundleIdentifier] stringByAppendingString:@".capture"]];
}

- (BOOL)snap :(int)type;
{
    AVPLAYLayer *layer = (AVPLAYLayer *)self.view.layer;
    NSImage *img = [layer snap];
    
    NSString *dir = [[VideoViewController capturePath] stringByAppendingString:@"/"];
    NSString *name = [NSString stringWithFormat:@"%d_%d_%@.bmp",
                      type,
                      self.curChannel.uniqueId,
                      [[NSDate date] stringWithFormatter:@"YYYY-MM-dd_HH-mm-ss"]];
    NSFileManager *manager = [NSFileManager defaultManager];
    
    if (![manager fileExistsAtPath:dir]) {
        NSError *error;
        [manager createDirectoryAtPath:dir
           withIntermediateDirectories:YES
                            attributes:nil
                                 error:&error];
        
        if (error) {
            NSLog(@"创建抓拍路径出错!:%@",error);
            return NO;
        }
    }
    
    return [img saveAsBmpWithName:[dir stringByAppendingString:name]];
}


- (void)setVideoState :(VIDEO_STATE)state
{
    if (state == NO_VIDEO || _videoState != state) {
        NSString *title = @"";
        _videoState = state;
        switch (state) {
            case NO_VIDEO:
                title = NSLocalizedString(@"no video", nil);
                break;
                
            case CONNECTING:
                title = NSLocalizedString(@"connecting......", nil);
                break;
                
            case VIDEO_PLAYING:
                title = @"";
                break;
                
            case DISCONNECTED:
                title = NSLocalizedString(@"lost connection", nil);
                break;
                
            case CONNECT_FAILED:
                title = NSLocalizedString(@"connect failed", nil);
                break;
                
            default:
                break;
        }
        
        [self clear];
        [self.videoStateTextField setStringValue:title];
        [self updateToolbarUI];
    }
}

- (void)setRecordState :(BOOL)state
{
    if (state) {
        if (self.videoState == VIDEO_PLAYING) {
            //向录像中心发起查询
            [self updateRecordingState];
            [self updateManualRecordState];
        }
        else {
            self.recording.image = [NSImage imageNamed:@"Recording Off"];
            self.record.enabled = NO;
        }
    }
    else {
        self.recording.image = [NSImage imageNamed:@"Recording Off"];
        self.record.enabled = NO;
    }
}

#pragma mark - video view protocol
- (void)render
{
    if (self.videoState == VIDEO_PLAYING) {
        [self.view.layer setNeedsDisplay];
    }
}

- (void)clear
{
    OpenGLVidGridLayer *layer = (OpenGLVidGridLayer *)self.view.layer;
    [layer clear];
}

- (int)curChannelId
{
    if (self.curChannel) {
        return self.curChannel.uniqueId;
    }
    
    return -1;
}

- (BOOL)isListen
{
    return self.listen.state == NSOnState;
}

- (void)onAudioStateChange:(int)state
{
    if (self.curChannel && !self.group) {
        self.listen.state = (state == 0)? NSOffState : NSOnState;
    }
}

- (void)onTalkStateChange :(int)state
{
    //改窗口有通道，并且不在轮询组中
    if (self.curChannel && !self.group) {
        self.talkable = (state == 0)? NO : YES;
        self.talk.state = self.talkable? NSOnState : NSOffState;
    }
}


#pragma mark - request center
- (void)requestSwitchTalk :(int)state
{
    //关闭
    if (state == 0) {
        [[DispatchCenter sharedDispatchCenter] switchTalking:NO device:self.device channel:self.curChannel.logicId];
        [self onTalkStateChange:0];
    }
    else {
        BOOL opened = [[DispatchCenter sharedDispatchCenter] switchTalking:YES device:self.device channel:self.curChannel.logicId];
        
        if (opened)
            [self onTalkStateChange:1];
        else {
            NSAlert *alert = [[NSAlert alloc] init];
            
            alert.messageText = NSLocalizedString(@"open intercom function failure", nil);
            [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
            [alert runModal];
            
            [self onTalkStateChange:0];
        }
    }
}

#pragma mark - layout
- (void)layout
{
    CGRect  bounds                  = self.view.bounds;
    CGFloat BW                      = bounds.size.width;
    CGFloat BH                      = bounds.size.height;
    CGFloat TFW = self.videoStateTextField.bounds.size.width;
    CGFloat TFH = self.videoStateTextField.bounds.size.height;
    
    [self.viewIdTF setFrame:CGRectMake(0, 0,VIEWID_WIDTH,TOOLBAR_HEIGHT)];
    [self.videoInfoTF setFrame:CGRectMake(VIEWID_WIDTH, 0,BW - VIEWID_WIDTH,TOOLBAR_HEIGHT)];
    [self.alarm setFrame:CGRectMake(BW - 7 * (TOOLBAR_HEIGHT + 1),1, TOOLBAR_HEIGHT ,TOOLBAR_HEIGHT)];
    [self.recording setFrame:CGRectMake(BW - 6 * (TOOLBAR_HEIGHT + 1),1, TOOLBAR_HEIGHT ,TOOLBAR_HEIGHT)];
    [self.close setFrame:CGRectMake(BW - 5 * (TOOLBAR_HEIGHT + 1),1, TOOLBAR_HEIGHT ,TOOLBAR_HEIGHT)];
    [self.record setFrame:CGRectMake(BW - 4 * (TOOLBAR_HEIGHT + 1),1, TOOLBAR_HEIGHT ,TOOLBAR_HEIGHT)];
    [self.listen setFrame:CGRectMake(BW - 3 * (TOOLBAR_HEIGHT + 1),1, TOOLBAR_HEIGHT ,TOOLBAR_HEIGHT)];
    [self.snap setFrame:CGRectMake(BW - 2 * (TOOLBAR_HEIGHT + 1),1, TOOLBAR_HEIGHT ,TOOLBAR_HEIGHT)];
    [self.talk setFrame:CGRectMake(BW - 1 * (TOOLBAR_HEIGHT + 1),1, TOOLBAR_HEIGHT ,TOOLBAR_HEIGHT)];
    [self.videoStateTextField setFrameOrigin:NSMakePoint((BW - TFW)/ 2.0, (BH - TFH)/ 2.0)];
    [self updateToolbarUI];
}

#pragma mark - Action
- (IBAction)toolbarButtonClicked:(NSButton *)sender {
    
    [sender setEnabled:NO];
    
    NSInteger   tag = sender.tag;
    VVTB_CMD    cmd = VVIB_NULL;
    int         state = (int)[sender state];
    
    switch (tag) {
        case 1://Snap
            cmd = VVTB_SNAP;
            [self showSnapResult:[self snap:MANUAL_SNAP]];
            break;
            
        case 2://Listen
            cmd = VVTB_SOUND;
            AVPLAY_Listen(self.port, state);
            break;
            
        case 3:
            cmd = VVTB_TAKL;
            [self requestSwitchTalk:state];
            break;
            
        case 4://Record
        {
            cmd = VVTB_RECORD;
            
            if (self.curChannel) {
                [sender setEnabled:!(state == NSOnState)];
                [[RecordCenter sharedRecordCenter] switchRecordingState:state
                                                          withChannelId:self.curChannel.uniqueId
                                                                   type:ManualRecord];
            }
        }
            break;
            
        case 5:
            cmd = VVTB_CLOSE;
            break;
            
        default:
            return;
    }
    
    //发送点击事件广播
    NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
                              [NSNumber numberWithInteger:(int)[sender state]],KEY_VIDEO_VIEW_TOOLBAR_BTN_STATE,
                              [NSNumber numberWithInteger:cmd],KEY_VIDEO_VIEW_TOOLBAR_CMD,nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:VIDEO_VIEW_TOOLBAR_STATE_CHANGE_NOTIFICATION
                                                        object:self
                                                      userInfo:userInfo];
    [sender setEnabled :YES];
}


#pragma mark - audio grabber protocol
- (void)audioDataArrived :(void *)bytes length :(int)length
{
    Channel *channel = self.curChannel;
    DispatchCenter *center = [DispatchCenter sharedDispatchCenter];
    
    if (channel && self.talkable) {
        //准备数据
        FOSCAM_NET_TALK_DATA talkData;
        talkData.data = bytes;
        talkData.len = length;
        
        FOSCAM_NET_CONFIG config;
        config.info = &talkData;
        
        [center sendTalkingData:talkData.data
                         length:talkData.len
                       toDevice:self.device
                        channel:channel.logicId];
    }
}

#pragma mark - setter and getter
- (void)setNeedDisplayToolbar:(BOOL)needDisplayToolbar
{
    _needDisplayToolbar = needDisplayToolbar;
    [self layout];
}

- (void)updateToolbarUI
{
    Channel         *curChn = self.curChannel;
    VIDEO_STATE     videoState = self.videoState;
    BOOL            isGroup = (self.group != nil);
    
    BOOL    isPlayback              = (self.type == AVPLAY_TYPE_FILE)? YES : NO;
    BOOL    isNeedDisplayToolbar    = self.needDisplayToolbar;
    
    //内容
    self.videoInfoTF.stringValue = curChn? curChn.name : @"";
    [self setRecordState:curChn? YES : NO];
    
    //启用
    self.snap.enabled       = curChn && (self.videoState == VIDEO_PLAYING);
    self.talk.enabled       = curChn && !isGroup && (videoState == VIDEO_PLAYING);
    self.listen.enabled     = curChn && !isGroup && (videoState == VIDEO_PLAYING);
    self.close.enabled      = curChn? YES : NO;
    self.recording.enabled  = curChn? YES : NO;
    self.record.enabled     = curChn && !isGroup && (videoState == VIDEO_PLAYING);
    
    //隐藏
    self.viewIdTF.hidden    = !isNeedDisplayToolbar;
    self.videoInfoTF.hidden = !isNeedDisplayToolbar;
    self.recording.hidden   = !isNeedDisplayToolbar || isPlayback;
    self.close.hidden       = !isNeedDisplayToolbar || isPlayback;
    self.snap.hidden        = !isNeedDisplayToolbar;
    self.talk.hidden        = !isNeedDisplayToolbar || isPlayback || isGroup;
    self.listen.hidden      = !isNeedDisplayToolbar || isGroup;
    self.record.hidden      = !isNeedDisplayToolbar || isPlayback || isGroup;
    
    
    if (!curChn || !isNeedDisplayToolbar || isPlayback )
        self.alarming = NO;

    //状态
    if (!curChn || videoState == NO_VIDEO) {
        self.talk.state = NSOffState;
        self.listen.state = NSOffState;
        self.record.state = NSOffState;
        self.talkable = NO;
    }
}

- (void)setCurChannel:(Channel *)curChannel
{

    if (!curChannel) {
        [self setVideoState:NO_VIDEO];
        //打开对讲
        [self onTalkStateChange:0];
        //关闭音频
        AVPLAY_Listen(self.port, false);
    }
    
    self.device = curChannel.device;
    _curChannel = curChannel;
    [self updateToolbarUI];
}

- (void)setViewId :(int)viewId
{
    _viewId = viewId;
    [self.viewIdTF setStringValue:[NSString stringWithFormat:@"%@%d",NSLocalizedString(@"view", nil),_viewId]];
}

- (void)setViewIdTF:(NSTextField *)viewIdTF
{
    _viewIdTF = viewIdTF;
    _viewIdTF.backgroundColor = [[NSColor blackColor] colorWithAlphaComponent:0.6];
}

- (void)setVideoInfoTF :(NSTextField *)videoInfoTF
{
    _videoInfoTF = videoInfoTF;
    _videoInfoTF.backgroundColor = [[NSColor blackColor] colorWithAlphaComponent:0.6];
}

- (void)setAlarming:(BOOL)alarming
{
    _alarming = alarming;
    self.alarm.hidden = !alarming;
}

- (void)setPort:(int)port
{
    _port = port;
    [(AVPLAYLayer *)self.view.layer setPort:port];
    
    if (self.listen.state == NSOnState) {
        AVPLAY_Listen(self.port, true);
    }
}

- (int)viewState
{
    int v = 0;
    
    if (self.listen.state == NSOnState)
        v |= (1 << VVTB_SOUND);
    
    if (self.talk.state == NSOnState)
        v |= (1 << VVTB_TAKL);
    
    if (self.isAlarming) {
        v |= (1 << VVTB_ALARM);
    }
    return v;
}

- (void)setViewState:(int)v
{
    //是否开启声音
    self.listen.state = (v & (1 << VVTB_SOUND))? NSOnState : NSOffState;
    
    [self onTalkStateChange:v & (1 << VVTB_TAKL)];
    self.alarming = (v & (1 << VVTB_ALARM));
}

@end
