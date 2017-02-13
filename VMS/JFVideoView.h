//
//  JFVideoView.h
//  VMS
//
//  Created by Jeff on 15/5/17.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JFOpenGLView.h"

@protocol JFVideoViewDelegate

@end

@interface JFVideoView : NSView
@property (nonatomic) BOOL selected;
@property (assign) id<JFVideoViewDelegate> delegate;
@end
