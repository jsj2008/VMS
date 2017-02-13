//
//  JFSplitViewController.m
//  VMS
//
//  Created by JefChou on 15/5/20.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "MultyVideoViewsManager.h"

#define MVVC_Debug  0
@interface LayoutConfig : NSObject<NSCoding>

@property (nonatomic,strong) NSNumber *pageSize;
@property (nonatomic,strong) NSNumber *startViewId;
@property (nonatomic,strong) NSNumber *selectedViewId;
@property (nonatomic,strong) NSNumber *hideToolbar;

- (instancetype)initWithPageSize :(int)pageSize
                       startViewId :(int)startViewId
                    selectedViewId :(int)selectedViewId
                     hideToolbar :(int)hideToolbar;
- (instancetype)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;

@end

@implementation LayoutConfig

static  NSString *codingKeyPageSize = @"pageSize";
static  NSString *codingKeystartViewId = @"startViewId";
static  NSString *codingKeyselectedViewId = @"selectedViewId";
static  NSString *codingKeyHideToolbar = @"hideToolbar";

- (instancetype)initWithPageSize:(int)pageSize
                       startViewId:(int)startViewId
                    selectedViewId:(int)selectedViewId
                     hideToolbar:(int)hideToolbar
{
    if (self = [super init]) {
        self.pageSize = [NSNumber numberWithInt:pageSize];
        self.startViewId = [NSNumber numberWithInt:startViewId];
        self.selectedViewId = [NSNumber numberWithInt:selectedViewId];
        self.hideToolbar = [NSNumber numberWithInt:hideToolbar];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        self.pageSize = [aDecoder decodeObjectForKey:codingKeyPageSize];
        self.startViewId = [aDecoder decodeObjectForKey:codingKeystartViewId];
        self.selectedViewId = [aDecoder decodeObjectForKey:codingKeyselectedViewId];
        self.hideToolbar = [aDecoder decodeObjectForKey:codingKeyHideToolbar];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.pageSize forKey:codingKeyPageSize];
    [aCoder encodeObject:self.startViewId forKey:codingKeystartViewId];
    [aCoder encodeObject:self.selectedViewId forKey:codingKeyselectedViewId];
    [aCoder encodeObject:self.hideToolbar forKey:codingKeyHideToolbar];
}
@end



@interface PlayInfoNode : NSObject

- (instancetype)initWithChannelId :(NSInteger)chnId
                       streamType :(FOSSTREAM_TYPE)type
                             port :(int)port;


@property (nonatomic,assign) NSInteger chnId;
@property (nonatomic,assign) FOSSTREAM_TYPE streamType;
//一路视频对应的端口号
@property (nonatomic,assign) int port;
//存放了一路视频所对应的显示View 列表
@property (nonatomic,strong) NSMutableSet *viewList;

@end

@implementation PlayInfoNode

- (instancetype)initWithChannelId :(NSInteger)chnId
                       streamType :(FOSSTREAM_TYPE)type
                             port :(int)port
{
    if (self = [super init]) {
        self.chnId = chnId;
        self.streamType = type;
        self.port = port;
        self.viewList = [[NSMutableSet alloc] init];
    }
    
    return self;
}

@end


@interface MultyVideoViewsManager()
{
    NSInteger _enteredVideoNumber;
    int _pageSizeRecord;
    int _startViewIdRecord;
}

@property (strong,nonatomic) NSMutableArray *videoViewControllers;
@property (readwrite) int startViewId;
@property (readwrite) int selectedViewId;
@property (assign,readwrite) int type;
@property (nonatomic,strong) NSMutableDictionary *playInfos;
@property (nonatomic,strong) NSMutableDictionary *viewState;//记录窗口通道状态

@end


static void decodeComplete(int port,void *userData)
{
    @autoreleasepool {
        dispatch_async(dispatch_get_main_queue(), ^{
            MultyVideoViewsManager *manager = (__bridge MultyVideoViewsManager *)userData;
            NSArray *nodes = manager.playInfos.allValues;
            
            [nodes enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                PlayInfoNode *node = obj;
                if ( node.port == port) {
                    [node.viewList enumerateObjectsUsingBlock:^(id<VideoViewProtocol>  _Nonnull obj, BOOL * _Nonnull stop) {
                        [obj render];
                    }];
                    *stop = YES;
                }
            }];
        });
    }
}

static void audioStateChange(int port,int state,void *userData)
{
    @autoreleasepool {
        MultyVideoViewsManager *manager = (__bridge MultyVideoViewsManager *)userData;
        NSArray *nodes = manager.playInfos.allValues;
        
        [nodes enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            PlayInfoNode *node = obj;
            if ( node.port == port) {
                [node.viewList enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
                    [(VideoViewController *)obj onAudioStateChange:state];
                }];
                *stop = YES;
            }
        }];
    }
}


@implementation MultyVideoViewsManager
@synthesize pageSize = _pageSize;
#pragma mark - init

static NSString *cfgKeyLayout = @"layout";

- (void)awakeFromNib
{
    [(JFSplitView *)self.view setDelegate1:self];
    
    //收听广播
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleToobarNotification:)
                                                 name:VIDEO_VIEW_TOOLBAR_STATE_CHANGE_NOTIFICATION
                                               object:nil];
    
    //接受消息
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleAlarmSnapNotificate:)
                                                 name:VMS_ALARM_SNAP_NOTIFICATION
                                               object:nil];
        
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleRegisteredRenderNotification:)
                                                 name:REGISTERED_RENDER_NOTIFICATION
                                               object:nil];
    
    [self.view addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:NULL];
    
}

- (void)dealloc
{
    NSLog(@"Running in %@,'%@'",self.className,NSStringFromSelector(_cmd));
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.view removeObserver:self forKeyPath:@"frame"];
    
}

//解档
- (void)unArchive
{
    NSData *data  = [[NSUserDefaults standardUserDefaults] valueForKey:cfgKeyLayout];
    LayoutConfig *layout = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    self.pageSize = layout.pageSize.intValue;
    self.startViewId = layout.startViewId.intValue;
    self.selectedViewId = layout.selectedViewId.intValue;
    self.hideToolbar = layout.hideToolbar.intValue;
}

//归档
- (void)archive
{
    LayoutConfig *layout = [[LayoutConfig alloc] initWithPageSize:self.pageSize
                                                        startViewId:self.startViewId
                                                     selectedViewId:self.selectedViewId
                                                      hideToolbar:self.hideToolbar];
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:layout];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:cfgKeyLayout];
}

#pragma mark - life cycle
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *,id> *)change
                       context:(void *)context
{
    [self layout];
}

#pragma mark - layout
+ (NSArray *)validPageSize
{
    return [NSArray arrayWithObjects:@1,@4,@6,@8,@9,@16,@25,@36,@49,@64,nil];
}

- (NSInteger)clipWithPageSize :(NSInteger)size
{
    NSInteger temp = (NSInteger)sqrt(size);
    return size == temp * temp? temp : size/2;
}

- (void)repickVideoViewController
{
    ///remove all the subview
    NSView *super_view = self.view;
    NSArray *sub_views = super_view.subviews;
    //[sub_views makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [sub_views enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSView *subView = obj;
        //subView.hidden = YES;
        [subView setFrame:NSZeroRect];
        [subView.layer setNeedsDisplay];
    }];
    ///repick video view into split view
    [self.view setNeedsDisplay:YES];
    [self layout];
}

- (NSRect)convertRectToScreen :(NSRect)rc
{
    NSView *view = self.view;
    NSRect rcInWindow = [view convertRect:rc toView:nil];
    NSRect rcInScreen = [view.window convertRectToScreen:rcInWindow];
    return rcInScreen;
}

- (void)layout
{
    NSInteger   startViewId = self.startViewId;
    NSInteger   pageSize = self.pageSize;
    NSInteger   clip = [self clipWithPageSize:pageSize];
    NSRect      bounds = NSInsetRect(self.view.bounds, 1, 1);
    CGFloat     BW = bounds.size.width;
    CGFloat     BH = bounds.size.height;
    CGFloat     CW = BW / clip - 2;
    CGFloat     CH = BH / clip - 2;
    NSInteger   cellIndex = 0;
    
    for (NSInteger idx = 0; idx < clip * clip; idx++) {
        NSRect frame = NSZeroRect;
        NSInteger port = -1;
        NSInteger row = (clip - 1) - idx / clip;
        NSInteger col = idx % clip;
        
        if (0 == idx && pageSize < clip * clip) {
            //第一个单元进行特殊处理
            port = startViewId + cellIndex++;
            frame = CGRectMake(bounds.origin.x + 1,
                               bounds.origin.y + BH * 1 / clip + 1,
                               BW * (clip - 1) / clip - 2,
                               BH * (clip - 1) / clip - 2);
        } else if ((pageSize < clip * clip) && row >0 && (col < clip - 1)) {
            continue;
        } else {
            port = startViewId + cellIndex++;
            frame = CGRectMake(bounds.origin.x + col * BW / clip + 1,
                                   bounds.origin.y + row * BH / clip + 1,
                                   CW ,CH);
        }
        
        VideoViewController *vc = self.videoViewControllers[port];
        [vc.view setFrame:frame];
    }
}

#pragma mark - public API
- (void)clearPort :(int)port
{
    NSArray *videoControllers = self.videoViewControllers;
    if (port >= 0 && port < videoControllers.count) {
        VideoViewController *videoViewController = videoControllers[port];
        [videoViewController clear];
    }
}

//当该窗口没有引用通道 或者 轮巡组时，该窗口成为空闲窗口
- (BOOL)isFreeView :(int)viewId;
{
    NSArray *videoControllers = self.videoViewControllers;
    if (viewId >= 0 && viewId < videoControllers.count) {
        VideoViewController *vvc = videoControllers[viewId];
    
        return ((nil == vvc.group) && (nil == vvc.curChannel));
    }
    
    return NO;
}

- (int)viewIdForPoint :(NSPoint)screenPoint
{
    int viewId = -1;
    NSView *view = self.view;
    NSWindow *window = view.window;
    NSRect rcInScreen = NSMakeRect(screenPoint.x, screenPoint.y, 0, 0);
    NSRect rcInWindow = [window convertRectFromScreen:rcInScreen];
    NSPoint pointInWindow = rcInWindow.origin;
    NSPoint pointInView = [view convertPoint :pointInWindow fromView :nil];
    
    for (int i = self.startViewId; i < self.startViewId + self.pageSize; i++) {
        VideoViewController *controller = self.videoViewControllers[i];
        NSView *videoView = controller.view;
        NSRect frame = videoView.frame;
        if (NSPointInRect(pointInView, NSInsetRect(frame, -1, -1))) {
            viewId = i;
            break;
        }
    }
    
    return viewId;
}

- (FOSSTREAM_TYPE)streamTypeOfViewId :(int)viewId;
{
    FOSSTREAM_TYPE streamType = FOSSTREAM_SUB;
    NSArray *controllers = self.videoViewControllers;
    if (viewId >= 0 && viewId < controllers.count)
        streamType = [controllers[viewId] streamType];
    
    return streamType;
}

- (void)toggleFullScreenMode
{
    NSView *view = self.view;
    if (self.isFullScreenMode) {
        [view exitFullScreenModeWithOptions:nil];
        self.fullScreenMode = NO;
        
        if ([self.delegate respondsToSelector:@selector(didExitFullScreenMode:)]) {
            [self.delegate didExitFullScreenMode:nil];
        }
    }
    else {
        NSDictionary *options = [NSDictionary dictionaryWithObject:@YES forKey:NSFullScreenModeAllScreens];
        BOOL result = [view enterFullScreenMode:[NSScreen mainScreen] withOptions:options];
        if (result)
            self.fullScreenMode = YES;
        else {
            //进入全屏失败，打印日志，并对出应用
            NSLog(@"failed to enter full screen mode! exit(0)");
            exit(0);
        }
    }
}

//切换单窗口模式
- (void)toggleSignleWndMode
{
    //默认情况下，调用SetPageSize会自动切出单窗口模式，并且会自适应窗口码流
    //这里并不想出现这个情况，所有这里不是用访问器，直接访问变量.
    int                 port        = self.selectedViewId;
    VideoViewController *controller = self.videoViewControllers[port];
    id<MVVMDelegate>    delegate    = self.delegate;
    
    if (controller.isInSingleWndMode) {
        //切换成正常状态
        [controller setInSignleWndMode :NO];
        [self setSignleWndMode:NO];
        _startViewId = _startViewIdRecord;
        _pageSize = _pageSizeRecord;
    } else if (!self.signleWndMode) {
        //当前不再单窗口模式
        //切换为单窗口模式
        //询问委托，是否可以进入单窗口模式
        BOOL shouldEnter = NO;
        if ([delegate respondsToSelector:@selector(shouldEnterSingleWnd)]) {
            shouldEnter = [self.delegate shouldEnterSingleWnd];
        }
        
        if (shouldEnter) {
            _startViewIdRecord = self.startViewId;
            _pageSizeRecord = self.pageSize;
            _startViewId = port;
            _pageSize = 1;
            [controller setInSignleWndMode :YES];
            [self setSignleWndMode:YES];
        } else
            return;
    }
    
    //切换该窗口的码流
    FOSSTREAM_TYPE newStreamType = [self adaptStreamTypeForPort:port];
    
    if (newStreamType != controller.streamType) {
        controller.streamType = newStreamType;
        
        if ([delegate respondsToSelector:@selector(wndStreamTypeDidChange:)]) {
            NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
            NSNotification      *aNotific = [NSNotification notificationWithName:MVVM_WND_STREAM_TYPE_DID_CHANGE
                                                                          object:self
                                                                        userInfo:userInfo];
            [userInfo setValue:[NSNumber numberWithInt:newStreamType] forKey:KEY_WND_STREAM_TYPE];
            [userInfo setValue:[NSNumber numberWithInt:controller.viewId] forKey:KEY_PORT];
            [delegate wndStreamTypeDidChange:aNotific];
        }
    }
    [self repickVideoViewController];
}

- (int)freeViewId
{
    int freeViewId = -1;
    int startViewId = self.startViewId;
    int count = (int)self.videoViewControllers.count;
    
    
    for (int idx = 0; idx < count; idx++) {
        int viewId = (idx + startViewId) % count;
        if ([self isFreeView:viewId]) {
            freeViewId = viewId;
            break;
        }
    }
    
    return freeViewId;
}

- (void)updatePlayInfos
{
    @synchronized(self) {
        //从窗口到列表
        for (int vId = 0; vId < self.videoViewControllers.count; vId++) {
            VideoViewController *vvc = self.videoViewControllers[vId];
            
            if (vvc.curChannel) {
                NSString *key = [NSString stringWithFormat:@"%d_%d",vvc.curChannel.uniqueId,vvc.streamType];
                PlayInfoNode *node = [self.playInfos valueForKey:key];
                
                if (!node) {
                    int port = AVPLAY_FreePort();
                    
                    if (port >= 0) {
                        node = [[PlayInfoNode alloc] initWithChannelId:vvc.curChannel.uniqueId
                                                            streamType:vvc.streamType
                                                                  port:port];
                        [self.playInfos setValue:node forKey:key];
                        AVPLAY_SetPlayType(port, AVPLAY_TYPE_STREAM);
                        AVPLAY_Play(port, NULL,audioStateChange,decodeComplete, (__bridge void *)(self));
                    }
                }
                
                if (node) {
                    vvc.port = node.port;
                    [node.viewList addObject:vvc];
                }
            }
        }
        
        //从列表到窗口
        for (NSString *key in self.playInfos.allKeys) {
            PlayInfoNode *node = [self.playInfos valueForKey:key];
            NSMutableSet *viewList = node.viewList;
            int port = node.port;
            
            [viewList enumerateObjectsUsingBlock:^(id<VideoViewProtocol>  _Nonnull obj,
                                                   BOOL * _Nonnull stop) {
                if ([obj port] != port) {
                    [viewList removeObject:obj];
                }
            }];
            
            if (viewList.count == 0) {
                //查看是否有轮询窗口正在引用这一路
                if (![self existGroupRetainStream:key]) {
                    AVPLAY_Stop(port);
                    [self.playInfos setValue:nil forKey:key];
                }
            }
        }
        
        [self tracePlayInfo];
    }
}

- (BOOL)existGroupRetainStream :(NSString *)key
{
    for (int i = 0; i < self.videoViewControllers.count; i++) {
        VideoViewController *vvc = self.videoViewControllers[i];
        Group *g = vvc.group;
        
        if (g) {
            for (Poll *poll in g.children) {
                NSString *stream = [NSString stringWithFormat:@"%d_%d",poll.channelId,vvc.streamType];
                
                if ([key isEqualToString:stream]) {
                    return YES;
                }
            }
        }
    }
    
    return NO;
}

- (int)queryPortWithChannelId :(int)cId streamType :(FOSSTREAM_TYPE)streamType
{
    int port = -1;
    
    @synchronized (self) {
        NSString *key = [NSString stringWithFormat:@"%d_%u",cId,streamType];
        PlayInfoNode *node = [self.playInfos valueForKey:key];
        
        port = node? node.port : -1;
    }
    
    return port;
}

- (VideoViewController *)vvcWithObj :(id)obj
{
    
    if (obj) {
        __block VideoViewController *target = nil;
        
        if ([obj isKindOfClass:[Group class]]) {
            Group *g = obj;
            [self.videoViewControllers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                VideoViewController *vvc = obj;
                
                if (vvc.group && vvc.group.uniqueId == g.uniqueId) {
                    target = vvc;
                    *stop = YES;
                }
            }];
        }
        else if ([obj isKindOfClass:[Channel class]]) {
            Channel *c = obj;
            [self.videoViewControllers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                VideoViewController *vvc = obj;
                
                if (!vvc.group && vvc.curChannel && vvc.curChannel.uniqueId == c.uniqueId) {
                    target = vvc;
                    *stop = YES;
                }
            }];
        }
        
        return target;
    }
    
    return nil;
}

- (void)saveViewState :(int)vId
{
    if (vId >= 0 && vId < self.videoViewControllers.count) {
        VideoViewController *vvc = self.videoViewControllers[vId];
        NSString *key = nil;
        
        if (!vvc.group && vvc.curChannel) {
            key = [NSString stringWithFormat:@"C%d",vvc.curChannel.uniqueId];
            [self.viewState setValue:[NSNumber numberWithInt:vvc.viewState] forKey:key];
        }
    }
}

- (void)restoreViewState :(int)vId
{
    if (vId >= 0 && vId < self.videoViewControllers.count) {
        VideoViewController *vvc = self.videoViewControllers[vId];
    
        if (vvc.group) {
            [vvc setViewState:0];
        }
        else if (vvc.curChannel) {
            NSString *key = [NSString stringWithFormat:@"C%d",vvc.curChannel.uniqueId];
            NSNumber *state = [self.viewState valueForKey:key];
            
            [vvc setViewState:state.intValue];
        }
    }
}

- (void)setView :(int)vId group :(Group *)g channel :(Channel *)c
{
    if (vId >= 0 && vId < self.videoViewControllers.count) {
        VideoViewController *vvc = self.videoViewControllers[vId];
        
        if (g == nil && c == nil) {
            [vvc closeRecord];
    
            vvc.group = nil;
            vvc.curChannel = nil;
            vvc.port = -1;
            
            [self saveViewState:vvc.viewId];
        }
        else if (g && c) {
            if (vvc.group && vvc.group.uniqueId == g.uniqueId) {
                vvc.curChannel = c;
                vvc.port = [self queryPortWithChannelId:c.uniqueId streamType:vvc.streamType];
            }
        }
        else {
            VideoViewController *src = [self vvcWithObj:g? g :c];
            
            [self saveViewState:src.viewId];
            [self saveViewState:vvc.viewId];
            
            src.group = nil;
            src.curChannel = nil;
            src.port = -1;
            
            if (g) {
                vvc.group = g;
                vvc.curChannel = nil;
            }
            else if (c) {
                vvc.group = nil;
                vvc.curChannel = c;
            }
            
            [self restoreViewState:vvc.viewId];
        }
        
        [self updatePlayInfos];
    }
}

- (void)setView :(int)vId state :(VIDEO_STATE)state
{
    if (vId >= 0 && vId < self.videoViewControllers.count) {
        VideoViewController *vvc = self.videoViewControllers[vId];
        [vvc setVideoState:state];
    }
}

- (VIDEO_STATE)stateOfView :(int)vId
{
    if (vId >= 0 && vId < self.videoViewControllers.count) {
        
        VideoViewController *vvc = self.videoViewControllers[vId];
        return vvc.videoState;
    }
    
    return NO_VIDEO;
}

- (id)objOfView :(int)vId
{
    if (vId >= 0 && vId < self.videoViewControllers.count) {
        VideoViewController *vvc = self.videoViewControllers[vId];
        
        if (vvc.group) {
            return vvc.group;
        }
        
        if (vvc.curChannel) {
            return vvc.curChannel;
        }
    }
    
    return nil;
}

- (id)selectedObj
{
    return [self objOfView:self.selectedViewId];
}

- (int)selectedChannelId
{
    Channel *c = [self.videoViewControllers[self.selectedViewId] curChannel];
    
    return c? c.uniqueId : -1;
}

#pragma mark -
- (void)setCurChannel :(Channel *)chn
                state :(VIDEO_STATE)state
               inView :(int)viewId
              restore :(BOOL)restore
{
    if (viewId < 0 || viewId >= 64)
        return;
    
    VideoViewController     *vvc        = self.videoViewControllers[viewId];
    NSString                *key        = [NSString stringWithFormat:@"%d_%u",chn.uniqueId,vvc.streamType];
    PlayInfoNode            *node       = [self.playInfos valueForKey:key];
    
    [vvc setVideoState:state];
    [vvc setCurChannel:chn];
    [vvc setPort:node.port];
    
    if ((state == VIDEO_PLAYING) && restore) {
        int v = [[self.viewState valueForKey:[NSString stringWithFormat:@"%d",chn.uniqueId]] intValue];
        [vvc setViewState:v];
    }
}


//停止接收所有通道数据
- (void)stopAcceptAll
{
    @synchronized(self) {
        NSArray *videoControllers = self.videoViewControllers;
        
        for (VideoViewController *vvc in videoControllers) {
            [vvc setCurChannel:nil];
            [vvc setGroup:nil];
            [vvc setVideoState:NO_VIDEO];
            
            [(OpenGLVidGridLayer *)vvc.view.layer clear];
        }
        
        NSArray *allNode = [self.playInfos allValues];
        for (PlayInfoNode *node in allNode) {
            AVPLAY_Stop(node.port);
        }
        [self.playInfos removeAllObjects];
    }
}


#pragma mark -
- (void)pageUp
{
    BOOL beyondBounds = (self.startViewId - self.pageSize) < 0 && (self.startViewId % self.pageSize);
    self.startViewId = beyondBounds? 0 : (self.startViewId + MAX_PAGE_SIZE - self.pageSize) %  MAX_PAGE_SIZE;
    [self repickVideoViewController];
}

- (void)pageDown
{
    ///If it is beyond the border the following boundary alignment
    if (self.startViewId == MAX_PAGE_SIZE - self.pageSize) {
        self.startViewId = 0;
    } else if (self.startViewId + self.pageSize > MAX_PAGE_SIZE - self.pageSize) {
        self.startViewId = MAX_PAGE_SIZE - self.pageSize;
    } else {
        self.startViewId = (self.startViewId + self.pageSize) % MAX_PAGE_SIZE;
    }
    [self repickVideoViewController];
}


- (void)addVideoViewController :(VideoViewController *)videoViewController
{
    if ([videoViewController isKindOfClass:[videoViewController class]]) {
        [self.videoViewControllers addObject:videoViewController];
        //添加引用
        [self.view addSubview:videoViewController.view];
    }
}

#pragma mark - private method
- (FOSSTREAM_TYPE)adaptStreamTypeForPort :(int)port
{
    FOSSTREAM_TYPE wndStreamType = FOSSTREAM_SUB;
    
    if (port >= 0 && port < self.videoViewControllers.count) {
        
        int option = self.wndStreamTypeOption;
        switch (option) {
            case 0: {//自适应
                int pageSize = self.pageSize;
                int startViewId = self.startViewId;
                int virtualPort = (port - startViewId) % pageSize + startViewId;
                switch (pageSize) {
                    case 1:
                    case 4:
                        wndStreamType = FOSSTREAM_MAIN;
                        break;
                    case 6:
                    case 8:
                        wndStreamType = (virtualPort == startViewId)? FOSSTREAM_MAIN : FOSSTREAM_SUB;
                        break;
                    default:
                        wndStreamType = FOSSTREAM_SUB;
                        break;
                }
                
                if (self.isSingleWndMode && self.selectedViewId == port) {
                    wndStreamType = FOSSTREAM_MAIN;
                }
            }
                break;
            case 1://全子码流
                wndStreamType = FOSSTREAM_SUB;
                break;
            case 2://全主码流
                wndStreamType = FOSSTREAM_MAIN;
                break;
            default:
                break;
        }
        
        
    }
    return wndStreamType;
}

#pragma mark - split view delegate
- (NSView *)selectedView
{
    int port = self.selectedViewId;
    return (port == -1)? nil : [(NSViewController *)self.videoViewControllers[port] view];
}


#pragma mark - Trace Play Info
- (void)tracePlayInfo
{
#if MVVC_Debug
    @synchronized (self) {
        NSArray  *keys = self.playInfos.allKeys;
        NSString *head = @"\n===========================================Multy Video Views Manager===========================================";
        NSString *tail = @"\n===============================================================================================================";
        NSString *content = @"";
        
        for (int i = 0; i < keys.count; i++) {
            PlayInfoNode *node = [self.playInfos valueForKey:keys[i]];
            __block NSString *viewList = @"";
            
            [node.viewList enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
                if ([obj isKindOfClass:[VideoViewController class]]) {
                    VideoViewController *vvc = obj;
                    viewList = [NSString stringWithFormat:@"%@,%d",viewList,vvc.viewId];
                }
            }];
            content = [NSString stringWithFormat:@"%@\n\
--->key=%@,port=%d,viewList=%@,cnt=%ld",content,keys[i],node.port,viewList,node.viewList.count];
        }
        
        NSLog(@"\n\n%@\n%@\n%@\n\n",head,content,tail);
    }
#endif
    
}
#pragma mark - Action & Event
- (void)splitView:(NSView *)view keyDown:(NSEvent *)theEvent
{
    switch([theEvent keyCode]) {
        case 53: // esc
            NSLog(@"ESC");
            [self toggleFullScreenMode];
//            [self.view exitFullScreenModeWithOptions:nil];
//            [self setFullScreenMode:NO];
            // Call the full-screen mode method
            break;
        default:
            break;
    }
}

- (void)splitView :(NSView *)view rightMouseDown :(NSEvent *)theEvent
{
    [self splitView:view mouseDown:theEvent];
}

- (void)splitView:(NSView *)view mouseDown:(NSEvent *)theEvent
{
    NSPoint             locationInWindow    = theEvent.locationInWindow;
    NSPoint             location            = [self.view convertPoint:locationInWindow fromView:nil];
    NSView              *hittedView         = [self.view hitTest:location];
    id<MVVMDelegate>    delegate            = self.delegate;
    
    if (!hittedView) {
        NSLog(@"no hitted view");
        return;
    }
    
    for (int idx = 0; idx < self.pageSize; idx++) {
        int                 port                    = idx + self.startViewId;
        int                 selectedViewId            = self.selectedViewId;
        VideoViewController *videoViewController    = [self.videoViewControllers objectAtIndex:port];
        
        if (videoViewController.view == hittedView) {
            //查看port是否发生了改变
            if (selectedViewId != port) {
                self.selectedViewId = port;
                //通知委托对象
                if ([delegate respondsToSelector:@selector(selectionDidChange:)]) {
                    [delegate selectionDidChange:[[NSNotification alloc] initWithName:@""
                                                                               object:self
                                                                             userInfo:nil]];
                }
            }
            
            [self.view setNeedsDisplay:YES];
        }
    }
    
    //处理双击事件
    if (theEvent.type == NSLeftMouseDown &&
        theEvent.clickCount == 2) {
        [self toggleSignleWndMode];
    }

}

#pragma mark - notification
//处理来自AlarmController的通知，改通知处于com.apple.root.default-qos 线程
- (void)handleAlarmSnapNotificate :(NSNotification *)aNotificate
{
    NSDictionary    *userInfo = aNotificate.userInfo;
    NSInteger       chnId = [[userInfo valueForKey:KEY_ALARM_CHANNEL_ID] integerValue];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        for (VideoViewController *vvc in self.videoViewControllers) {
            if (vvc.curChannel && vvc.curChannel.uniqueId == chnId) {
                [vvc snap:ALARM_SNAP];
            }
        }
    });
}


- (void)handleToobarNotification :(NSNotification *)aNotific
{
    NSString        *name  = aNotific.name;
    NSDictionary    *dict  = aNotific.userInfo;
    id              sender = aNotific.object;
    
    if ([name isEqualToString:VIDEO_VIEW_TOOLBAR_STATE_CHANGE_NOTIFICATION]) {
        [self handleViewClickedWithSender:sender];
        [self handleActionWithUserInfo:dict sender:sender];
    }
}

- (void)handleViewClickedWithSender :(VideoViewController *)sender
{
    id<MVVMDelegate> delegate       = self.delegate;
    int              selectedViewId = self.selectedViewId;

    for (int idx = 0; idx < self.pageSize; idx++) {
        int                 viewId  = idx + self.startViewId;
        VideoViewController *vvc    = [self.videoViewControllers objectAtIndex:viewId];
        
        if ((vvc.view == sender.view) && (selectedViewId != viewId)) {
            //查看port是否发生了改变
            self.selectedViewId = viewId;
            //通知委托对象
            if ([delegate respondsToSelector:@selector(selectionDidChange:)]) {
                NSNotification *aNotific = [[NSNotification alloc] initWithName:@""
                                                                         object:self
                                                                       userInfo:nil];
                [delegate selectionDidChange:aNotific];
            }
            
            [self.view setNeedsDisplay:YES];
        }
    }
}

- (void)handleActionWithUserInfo :(NSDictionary *)userInfo sender:(VideoViewController *)vvc
{
    Channel         *channel    = vvc.curChannel;
    NSUInteger      cmd         = [[userInfo valueForKey:KEY_VIDEO_VIEW_TOOLBAR_CMD] unsignedIntegerValue];
    BOOL            state       = [[userInfo valueForKey:KEY_VIDEO_VIEW_TOOLBAR_BTN_STATE] boolValue];
    
    if (channel) {
        switch (cmd) {
            case VVTB_TAKL: {
                for (VideoViewController *vvc in self.videoViewControllers) {
                    [vvc onTalkStateChange:0];
                }
                
                [vvc onTalkStateChange:state];
            }
                break;
                
            default:
                break;
        }
    }
}

- (void)handleRegisteredRenderNotification :(NSNotification *)aNotific
{
    //解析通知
    BOOL registOrUnRegist = [[aNotific.userInfo valueForKey:KEY_REGIST_OR_UNREGIST] boolValue];
    id<VideoViewProtocol> renderObj = [aNotific.userInfo valueForKey:KEY_RENDER_OBJ];
    
    if (!renderObj) return;
    
    @synchronized(self) {
        if (registOrUnRegist) {
            //在主/子码流中选择一路，作为渲染对象的码流类型
            for (int type = 0; type < 2; type++) {
                NSString *key = [NSString stringWithFormat:@"%d_%u",[renderObj curChannelId],type];
                PlayInfoNode *node = [self.playInfos valueForKey:key];
                //存在这样一路
                if (node) {
                    [renderObj setStreamType:type];
                    [renderObj setPort:node.port];
                    [node.viewList addObject:renderObj];
                    break;
                }
            }
        } else {
            NSString *key = [NSString stringWithFormat:@"%d_%u",[renderObj curChannelId],[renderObj streamType]];
            PlayInfoNode *node = [self.playInfos valueForKey:key];
            [node.viewList removeObject:renderObj];
            [renderObj setPort:-1];
        }
    }
}
#pragma mark - video player delegate
- (void)videoPlayer :(VideoPlayer *)player
        didReadData :(void *)bytes
             length :(size_t)length
               type :(int)type
          timeStamp :(double)timeStamp
          channelId :(int)channelId
{
    int port = -1;
    
    @synchronized(self) {
        NSString        *key        = [NSString stringWithFormat:@"%d_%u",channelId,FOSSTREAM_MAIN];
        PlayInfoNode    *node       = [self.playInfos valueForKey:key];
        if (node) {
            port = node.port;
        }
    }
    
    if (port >= 0) {
        switch (type) {
            case DATA_TYPE_AUDIO:
                AVPLAY_InputAudioData(port, (unsigned char *)bytes, length, timeStamp);
                break;
            case DATA_TYPE_VIDEO: {
                AVPLAY_InputVideoData(port, (unsigned char *)bytes, length, timeStamp);
                
#if 0
                char *buffer = (char *)bytes;
                NSLog(@"%d,%d,%d,%d,%d,%ld,%d,%d",buffer[0],buffer[1],buffer[2],buffer[3],buffer[4],length,channelId,FOSSTREAM_MAIN);
#endif
            }
                break;
            default:
                break;
        }
    }
}

#pragma mark - dispatch center data input
//当接收到来自中心的数据帧后，查找对应路数的端口号,存入数据.
- (void)didRecivedData :(void *)bytes
                length :(int)length
                  type :(int)type
             timeStamp :(double)timeStamp
             channelId :(int)channel_id
            streamType :(FOSSTREAM_TYPE)streamType
{
    int port = -1;
    @synchronized(self) {
        NSString        *key        = [NSString stringWithFormat:@"%d_%u",channel_id,streamType];
        PlayInfoNode    *node       = [self.playInfos valueForKey:key];

        if (node) {
            port = node.port;
        }
    }
    
    if (port >= 0) {
        switch (type) {
            case DATA_TYPE_AUDIO_PCM:
                AVPLAY_InputAudioData(port, (unsigned char *)bytes, length, timeStamp);
                break;
            case DATA_TYPE_VIDEO_H264:
                AVPLAY_InputVideoData(port, (unsigned char *)bytes, length, timeStamp);
                break;
            default:
                break;
        }
    }
}

#pragma mark - setter and getter
- (void)setPageSize:(int)pageSize
{
    if ([[MultyVideoViewsManager validPageSize] containsObject:[NSNumber numberWithInteger:pageSize]]) {
        _pageSize = pageSize;
        
        if (self.startViewId + pageSize > MAX_PAGE_SIZE) {
            self.startViewId = MAX_PAGE_SIZE - pageSize;
        }
        
        [self repickVideoViewController];
        [self setSignleWndMode:NO];
        //reset wnd stream type
        int count = (int)self.videoViewControllers.count ;
        for (int idx = 0; idx < count; idx++) {
            VideoViewController *controller = self.videoViewControllers[idx];
            controller.inSignleWndMode = NO;
            //如果窗口码流类型发生了改变，通知委托
            //将新码流和端口号 以消息的形式通知过去
            FOSSTREAM_TYPE newStreamType = [self adaptStreamTypeForPort :idx];
            if (controller.streamType != newStreamType) {
                controller.streamType = newStreamType;
                if ([self.delegate respondsToSelector:@selector(wndStreamTypeDidChange:)] &&
                    controller.curChannel) {
                    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
                    [userInfo setValue:[NSNumber numberWithInt:newStreamType] forKey:KEY_WND_STREAM_TYPE];
                    [userInfo setValue:[NSNumber numberWithInt:controller.viewId] forKey:KEY_PORT];
                    NSNotification *aNotific = [NSNotification notificationWithName:MVVM_WND_STREAM_TYPE_DID_CHANGE
                                                                             object:self
                                                                           userInfo:userInfo];
                    [self.delegate wndStreamTypeDidChange:aNotific];
                }
            }
        }
    }
}

- (int)pageSize
{
    return _pageSize? _pageSize : 1;
}

- (NSMutableArray *)videoViewControllers
{
    if (!_videoViewControllers) {
        _videoViewControllers = [[NSMutableArray alloc] init];
    }
    return _videoViewControllers;
}

- (void)setHideToolbar:(BOOL)hideToolbar
{
    _hideToolbar = hideToolbar;
    for (VideoViewController *videoViewController in self.videoViewControllers)
        [videoViewController setNeedDisplayToolbar :!hideToolbar];
    [self layout];
}

- (void)setWndStreamTypeOption:(int)wndStreamTypeOption
{
    _wndStreamTypeOption = wndStreamTypeOption;
    //apply
    int count = (int)self.videoViewControllers.count;
    for (int idx = 0; idx < count; idx++) {
        VideoViewController *vvc = self.videoViewControllers[idx];
        FOSSTREAM_TYPE newStreamType = [self adaptStreamTypeForPort :idx];
        if (vvc.streamType != newStreamType) {
            vvc.streamType = newStreamType;
            if ([self.delegate respondsToSelector:@selector(wndStreamTypeDidChange:)] &&
                vvc.curChannel) {
                NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
                [userInfo setValue:[NSNumber numberWithInt:newStreamType] forKey:KEY_WND_STREAM_TYPE];
                [userInfo setValue:[NSNumber numberWithInt:vvc.viewId] forKey:KEY_PORT];
                NSNotification *aNotific = [NSNotification notificationWithName:MVVM_WND_STREAM_TYPE_DID_CHANGE
                                                                         object:self
                                                                       userInfo:userInfo];
                [self.delegate wndStreamTypeDidChange:aNotific];
            }
        }
    }
}

- (NSMutableDictionary *)playInfos
{
    if (!_playInfos) {
        _playInfos = [[NSMutableDictionary alloc] init];
    }
    
    return _playInfos;
}

- (NSMutableDictionary *)viewState
{
    if (!_viewState) {
        _viewState = [[NSMutableDictionary alloc] init];
    }
    
    return _viewState;
}

- (Channel *)channelWithViewId :(int)vId
{
    if (vId >= 0 && vId < self.videoViewControllers.count)
        return [(VideoViewController *)self.videoViewControllers[vId] curChannel];
    
    return nil;
}

@end
