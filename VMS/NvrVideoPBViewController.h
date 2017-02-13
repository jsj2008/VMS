//
//  NvrVideoPBViewController.h
//  
//
//  Created by mac_dev on 16/6/13.
//
//

#import <Cocoa/Cocoa.h>

#import "MultyVideoViewsManager.h"
#import "VideoViewController.h"
#import "AppDelegate.h"
#import "DispatchCenter.h"
#import "TimeTableView.h"
#import "NSMutableArray+Reverse.h"
#import "VMSTabView.h"


@interface NvrPbChannelState : NSObject

@property(nonatomic,assign,getter=isOlvChecked) BOOL olvChecked;
@property(nonatomic,assign) int viewId;

- (instancetype)init;

@end

@interface NvrVideoPBViewController : NSViewController<TabMVCProtocol,MVVMDelegate,
NSOutlineViewDataSource,NSOutlineViewDelegate,NSMenuDelegate,TimeTableViewDelegate,
DispatchProtocal,VMSTabViewDelegate>

@property(nonatomic,assign,getter=isPlaying) BOOL playing;
@property(nonatomic,assign,getter=isPausing) BOOL pausing;

- (void)uninit;
@end
