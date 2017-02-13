//
//  PluginFullScreenWindowController.h
//  WebPlugin
//
//  Created by mac_dev on 15/11/11.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PluginNotification.h"
#import "../../VidGridLayer/VidGridLayer/VidGridLayer.h"
#import "NSWindow+FullScreen.h"


typedef bool (*SHOULD_ENTER_FULL_SCREEN)(void *userData,void *mouseDownLayer);

@interface PluginFullScreenWindowController : NSWindowController<NSWindowDelegate> {
    SHOULD_ENTER_FULL_SCREEN _shouldEnterFullScreen;
    void *_userData;
}



- (instancetype)init;

- (void)registCallback :(SHOULD_ENTER_FULL_SCREEN)shouldEnterFullScreen
              userData :(void *)userData;
- (void)renderWithData :(const void *)data
              lineSize :(int)lineSize
                videoW :(int)videoW
                videoH :(int)videoH;

- (void)toggleFullScreen;
- (BOOL)isInFullScreenMode;
@end
