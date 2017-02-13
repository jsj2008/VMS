//
//  VideoBuffer.h
//  VMS
//
//  Created by mac_dev on 16/1/6.
//  Copyright (c) 2016年 mac_dev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VideoBuffer : NSObject

@property(nonatomic,assign,readonly) size_t capacity;
@property(nonatomic,assign,readonly) size_t length;
@property(nonatomic,assign,readonly) void *bytes;
@property(nonatomic,assign) NSInteger idx;
@property(nonatomic,strong) NSDate *beginDate;
@property(nonatomic,strong) NSDate *endDate;
@property(nonatomic,assign,getter = isFull) BOOL full;

- (instancetype)initWithSize :(size_t)capacity;
- (void)appendBytes :(const void *)bytes length:(NSUInteger)length;
- (void)clear;
- (void)dealloc;

@end
