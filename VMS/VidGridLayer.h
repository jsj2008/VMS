//
//  OpenGLVidGridLayer.h
//  MultiLayer
//
//  Created by mac_dev on 15/11/2.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <Cocoa/Cocoa.h>
#import "OpenGLVidGridLayer.h"
@interface VidGridLayer : CALayer {
    NSInteger _pageSizeRecord;
    NSInteger _startPortRecord;
}
@property (nonatomic,assign) NSInteger pageSize;
@property (nonatomic,assign) NSInteger keyPort;
@property (nonatomic,assign,getter = isSingleViewMode) BOOL singleViewMode;
@property (nonatomic,assign,getter = isDisplayWidgets) BOOL displayWidgets;
- (instancetype)initWithCount :(NSInteger)count;
- (void)layout :(BOOL)animate withCompletionBlock :(void (^)(void)) block;
- (void)pageUp;
- (void)pageDown;
- (void)toggleSingleViewMode;
- (void)toggleDisplayWidgets;
- (CALayer *)layerAtPort :(NSInteger)port;

@end
