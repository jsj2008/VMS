//
//  Cocoa_VMSLivePluginImpl.h
//  VMSWebPlugin
//
//  Created by mac_dev on 15/11/6.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Quartz/Quartz.h>
#import "PluginCallbackFuncs.h"
#import "Cocoa_VMSPluginImpl.h"


@interface Cocoa_VMSLivePluginImpl : Cocoa_VMSPluginImpl


- (instancetype)initWithLayer :(CALayer *)layer;
- (void)setPluginCallbacks :(PluginCallbackFuncs*)pluginCallbacks
                  userData :(void *)userData;
- (int)loginWithServer :(const char *)server
                  port :(int)port
                  name :(const char *)name
                   pwd :(const char *)pwd;
- (void)logoff;
- (void)fullScreen;
- (void)cancelFullSrceen;
- (void)relayoutWithHCount :(int) hcount
                    vCount :(int) vcount;
- (const char *)openVideo :(const char*)xml;
- (const char *)closeVideo;
- (const char *)snapShot :(const char *)xml;
- (const char *)openAudio;
- (const char *)closeAudio;
- (const char *)getCurViewInfo;
- (void)ptzControll :(const char *)xml;
- (void)closeAllVideo;
@end
