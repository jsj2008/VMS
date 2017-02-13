//
//  DetectionAreasEditWindowController.h
//  VMS
//
//  Created by mac_dev on 15/9/29.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DispatchCenter.h"
#import "../libplay/libplay/avplay_sdk.h"
#import "AVPLAYLayer.h"
#import "VideoViewProtocol.h"


@interface DetectionAreasEditWindowController : NSWindowController<VideoViewProtocol>

- (instancetype)initWithWindowNibName :(NSString *)windowNibName
                            channelId :(int)channelId;
//重写下面的方法
- (void *)detectConfig;
- (void)preDone;
//Action
- (IBAction)done :(id)sender;
- (IBAction)cancel:(id)sender;

@property (nonatomic,weak) IBOutlet NSView *renderView;
@property (nonatomic,assign,readonly) NSInteger channelId;
@property (nonatomic,assign) FOSSTREAM_TYPE streamType;
@property (nonatomic,assign) int port;

@end
