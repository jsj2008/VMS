//
//  JFSplitView.h
//  VMS
//
//  Created by mac_dev on 15/5/14.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "DragView.h"

@protocol JFSplitViewDelegate<NSObject>
- (NSView *)selectedView;
- (void)splitView :(NSView *)view mouseDown:(NSEvent *)theEvent;//这里为了兼容10_10之前的版本，这里主动通知委托
- (void)splitView :(NSView *)view keyDown :(NSEvent *)theEvent;//这里为了兼容10_10之前的版本，这里主动通知委托
- (void)splitView :(NSView *)view rightMouseDown :(NSEvent *)theEvent;
@end

@interface JFSplitView : DragView
@property(assign) IBOutlet id<JFSplitViewDelegate> delegate1;

@end

