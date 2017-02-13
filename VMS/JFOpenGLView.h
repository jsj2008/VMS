//
//  JFOpenGLView.h
//  VMS
//
//  Created by mac_dev on 15/5/21.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface JFOpenGLView : NSView
@property (nonatomic,getter=isConnected) BOOL connected;

- (void)setTarget :(id)target action :(SEL)action;
@end
