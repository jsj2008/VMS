//
//  JFSplitViewController.h
//  VMS
//
//  Created by mac_dev on 15/5/20.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VideoViewController.h"
#import "JFSplitView.h"
#import "SystemSettingSheetController.h"

#define MAX_PAGE_SIZE      64


#define MVVM_WND_STREAM_TYPE_DID_CHANGE @"window stream type did change"
//#define KEY_WND_STREAM_TYPE     @"window stream type"
#define KEY_PORT                @"port"

@protocol MVVMDelegate <NSObject>


//是否能够放大
- (BOOL)shouldEnterSingleWnd;
@optional
//选择的窗口发生了改变.
- (void)selectionDidChange :(NSNotification *)aNotific;
//窗口码流发生改变
- (void)wndStreamTypeDidChange :(NSNotification *)aNotific;
//已经退出了全屏
- (void)didExitFullScreenMode :(NSNotification *)aNotific;
@end


@interface MultyVideoViewsManager : NSViewController<JFSplitViewDelegate,DispatchProtocal,VideoPlayerProtocol>

@property (nonatomic,assign) int pageSize;//每一页的大小
@property (nonatomic,assign,readonly) int startViewId;
@property (nonatomic,assign,readonly) int selectedViewId;
@property (nonatomic,assign) int wndStreamTypeOption;
@property (nonatomic,assign,getter = isHideToolbar) BOOL hideToolbar;
@property (nonatomic,assign,getter = isFullScreenMode) BOOL fullScreenMode;
@property (nonatomic,assign,getter = isSingleWndMode) BOOL signleWndMode;
@property (nonatomic,assign) id<MVVMDelegate> delegate;

//向管理器中添加视频控制器
+ (NSArray *)validPageSize;
- (void)addVideoViewController :(VideoViewController *)videoViewController;
- (void)pageUp;
- (void)pageDown;
- (void)toggleSignleWndMode;
- (void)toggleFullScreenMode;

//开始接收指定通道的数据
- (void)stopAcceptAll;
- (void)setView :(int)vId group :(Group *)g channel :(Channel *)c;
- (void)setView :(int)vId state :(VIDEO_STATE)state;
- (VIDEO_STATE)stateOfView :(int)vId;
- (id)objOfView :(int)vId;
- (id)selectedObj;
- (int)selectedChannelId;
//返回空闲窗口
- (int)freeViewId;
//获取指定端口码流类型
- (void)setWndStreamTypeOption:(int)wndStreamTypeOption;
- (FOSSTREAM_TYPE)streamTypeOfViewId :(int)viewId;
//清空数据队列
- (void)clearPort :(int)port;
//获取屏幕坐标点所对应的端口号
- (int)viewIdForPoint :(NSPoint)screenPoint;
- (BOOL)isFreeView :(int)viewId;
//归档
- (void)archive;
- (void)unArchive;

//指定窗口的通道Id
- (Channel *)channelWithViewId :(int)vId;
@end
