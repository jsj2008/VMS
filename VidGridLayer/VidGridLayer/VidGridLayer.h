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

//! Project version number for RegexKit.
FOUNDATION_EXPORT double RegexKitVersionNumber;

//! Project version string for RegexKit.
FOUNDATION_EXPORT const unsigned char RegexKitVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <RegexKit/PublicHeader.h>

FOUNDATION_EXPORT @interface VidGridLayer : CALayer {
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
- (void)setFrame:(CGRect)frame;
@end
