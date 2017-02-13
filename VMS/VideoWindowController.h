//
//  VideoWindowController.h
//  VMS
//
//  Created by mac_dev on 15/8/13.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface VideoWindowController : NSWindowController
@property (assign,readonly) int port;
@property (assign,getter=isNeedDisplayToolbar) BOOL needDisplayToolbar;

- (id)initWithWindowNibName:(NSString *)windowNibName
                      port :(int)port;
@end
