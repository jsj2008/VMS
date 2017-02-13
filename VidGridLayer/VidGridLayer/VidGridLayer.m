//
//  OpenGLVidGridLayer.m
//  MultiLayer
//
//  Created by mac_dev on 15/11/2.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "VidGridLayer.h"

@interface VidGridLayer()
@property (nonatomic,strong) NSMutableArray *subLayers;
@property (nonatomic,assign) NSInteger startPort;
@end

@implementation VidGridLayer
- (instancetype)initWithCount :(NSInteger)count
{
    if (self = [super init]) {
        self.backgroundColor = [NSColor whiteColor].CGColor;
        self.subLayers = [[NSMutableArray alloc] init];
        self.delegate = self;
        for (int i = 0; i < count; i++) {
            OpenGLVidGridLayer *subLayer = [[OpenGLVidGridLayer alloc] initWithVId:i];
            [self addSublayer:subLayer];
            [self.subLayers addObject:subLayer];
        }
    }
    
    return self;
}

#pragma mark - public api
- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self layout:NO withCompletionBlock:NULL];
}

- (CALayer *)layerAtPort:(NSInteger)port
{
    if ([self isValidPort:port])
        return self.subLayers[port];
    
    return nil;
}

- (void)layout :(BOOL)animate withCompletionBlock :(void (^)(void)) block;
{
    NSInteger pageSize = self.pageSize;
    NSInteger startPort = self.startPort;
    NSInteger clip = [self clipWithPageSize:pageSize];
    NSRect bounds = NSInsetRect(self.bounds, 1, 1);
    
    NSInteger cellIndex = 0;
    CGFloat BW = bounds.size.width;
    CGFloat BH = bounds.size.height;
    CGFloat CW = BW / clip - 2;
    CGFloat CH = BH / clip - 2;
    
    
    [self.subLayers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CALayer *subLayer = obj;
        subLayer.hidden = YES;
    }];
    
    [CATransaction begin];
    id anObject = (id)(animate? kCFBooleanFalse : kCFBooleanTrue);
    [CATransaction setValue:anObject forKey:kCATransactionDisableActions];
    for (NSInteger idx = 0; idx < clip * clip; idx++) {
        NSRect frame = NSZeroRect;
        NSInteger port = -1;
        NSInteger row = (clip - 1) - idx / clip;
        NSInteger col = idx % clip;
        
        if (0 == idx && pageSize < clip * clip) {
            //第一个单元进行特殊处理
            port = startPort + cellIndex++;
            frame = CGRectMake(bounds.origin.x + 1,
                               bounds.origin.y + BH * 1 / clip + 1,
                               BW * (clip - 1) / clip - 2,
                               BH * (clip - 1) / clip - 2);
        } else if ((pageSize < clip * clip) && row >0 && (col < clip - 1)) {
            continue;
        } else {
            port = startPort + cellIndex++;
            frame = CGRectMake(bounds.origin.x + col * BW / clip + 1,
                               bounds.origin.y + row * BH / clip + 1,
                               CW ,CH);
        }
        
        if (port < self.subLayers.count) {
            CALayer *subLayer = self.subLayers[port];
            [subLayer setHidden:NO];
            [subLayer setFrame:frame];
            [subLayer setNeedsDisplay];
        } else {
            NSLog(@"Err");
        }
    }
    [CATransaction setCompletionBlock:block];
    [CATransaction commit];
    [self setNeedsDisplay];
}

- (void)pageUp
{
    BOOL beyondBounds = (self.startPort - self.pageSize) < 0 && (self.startPort % self.pageSize);
    NSInteger countOfSubLayers = self.subLayers.count;
    self.startPort = beyondBounds? 0 : (self.startPort + countOfSubLayers - self.pageSize) %  countOfSubLayers;
    [self layout:NO withCompletionBlock:NULL];
}

- (void)pageDown
{
    NSInteger countOfSubLayers = self.subLayers.count;
    if (self.startPort == countOfSubLayers - self.pageSize) {
        self.startPort = 0;
    } else if (self.startPort + self.pageSize > countOfSubLayers - self.pageSize) {
        self.startPort = countOfSubLayers - self.pageSize;
    } else {
        self.startPort = (self.startPort + self.pageSize) % countOfSubLayers;
    }
    [self layout:NO withCompletionBlock:NULL];
}

//切换单窗口模式
- (void)toggleSingleViewMode
{
    NSInteger keyPort = self.keyPort;
    OpenGLVidGridLayer *keyLayer = self.subLayers[keyPort];
    
    if (keyLayer.isInSingleViewMode) {
        //切换成正常状态
        [keyLayer setInSingleViewMode:NO];
        [self setSingleViewMode:NO];
        [self setStartPort:_startPortRecord];
        [self setPageSize:_pageSizeRecord];
    } else if (!self.isSingleViewMode) {
        //当前不再单窗口模式
        //切换为单窗口模式
        _startPortRecord = self.startPort;
        _pageSizeRecord = self.pageSize;
        //默认情况下，调用SetPageSize会自动切出单窗口模式
        [self setStartPort:keyPort];
        [self setPageSize:1];
        [keyLayer setInSingleViewMode:YES];
        [self setSingleViewMode:YES];
    }
}

//切换显示小工具
- (void)toggleDisplayWidgets
{
}

#pragma mark - draw
- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
    NSInteger keyPort = self.keyPort;
    CALayer *keyLayer = self.subLayers[keyPort];
    if (!keyLayer.isHidden) {
        CGRect frame = NSInsetRect(keyLayer.frame, -1, -1);
        CGContextSetRGBStrokeColor(ctx, 1.0, 0, 0, 1.0);
        CGContextStrokeRect(ctx, frame);
    }
}

#pragma mark - private
- (BOOL)isValidPort :(NSInteger)port
{
    return port >=0 && port < self.subLayers.count;
}

- (NSArray *)validPageSize
{
    return [NSArray arrayWithObjects:@1,@4,@6,@8,@9,@16,@25,@36,@49,@64,nil];
}

- (NSInteger)clipWithPageSize :(NSInteger)size
{
    NSInteger temp = (NSInteger)sqrt(size);
    return size == temp * temp? temp : size/2;
}


#pragma mark - setter && getter
- (void)setPageSize:(NSInteger)pageSize
{
    if ([[self validPageSize] containsObject:[NSNumber numberWithInteger:pageSize]]) {
        _pageSize = pageSize;
        NSInteger count = self.subLayers.count;
        if (self.startPort + pageSize > count)
            self.startPort = count - pageSize;
        
        [self setSingleViewMode:NO];
        [self.subLayers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            OpenGLVidGridLayer *subLayer = obj;
            subLayer.inSingleViewMode = NO;
        }];
        [self layout:YES withCompletionBlock:^{
            [self setNeedsDisplay];
        }];
    }
}
@end
