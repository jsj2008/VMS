//
//  VideoViewProtocol.h
//  VMS
//
//  Created by mac_dev on 16/3/29.
//  Copyright (c) 2016年 mac_dev. All rights reserved.
//

#ifndef VMS_VideoViewProtocol_h
#define VMS_VideoViewProtocol_h

#import "../FoscamNetSDK/IPCSDK_for_mac150629/include/fossdk.h"

#define REGISTERED_RENDER_NOTIFICATION      @"registed render notification"
#define KEY_RENDER_OBJ                      @"render obj"
#define KEY_REGIST_OR_UNREGIST              @"regist or unrigist"

@protocol VideoViewProtocol <NSObject>
@required

- (void)setPort :(int)port;
- (int)port;
- (void)render;
- (void)clear;
- (int)curChannelId;
- (FOSSTREAM_TYPE)streamType;
- (BOOL)isListen;

@optional


- (void)setStreamType :(FOSSTREAM_TYPE)streamType;
- (void)onAudioStateChange :(int)state;
- (void)onTalkStateChange :(int)state;

@end
#endif
