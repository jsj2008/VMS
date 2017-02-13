//
//  AVPLAYLayer.h
//  VMS
//
//  Created by mac_dev on 2016/11/28.
//  Copyright © 2016年 mac_dev. All rights reserved.
//

#import "../VidGridLayer/VidGridLayer/OpenGLVidGridLayer.h"
#import "../libplay/libplay/avplay_sdk.h"
#import "NSImage+Flip.h"

@interface AVPLAYLayer : OpenGLVidGridLayer

@property(nonatomic,assign) int port;

- (bool)getData :(void **)pixels pitch :(int *)pitch width :(int *)width height :(int *)height;
- (NSImage *)snap;

@end
