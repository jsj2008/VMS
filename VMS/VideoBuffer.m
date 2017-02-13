//
//  VideoBuffer.m
//  VMS
//
//  Created by mac_dev on 16/1/6.
//  Copyright (c) 2016年 mac_dev. All rights reserved.
//

#import "VideoBuffer.h"

@interface VideoBuffer()
@property(readwrite) size_t capacity;
@property(readwrite) size_t length;
@property(readwrite) void *bytes;
@end

@implementation VideoBuffer

- (instancetype)initWithSize :(size_t)capacity
{
    if (self = [super init]) {
        self.capacity = capacity;
        self.length = 0;
        self.full = NO;
        self.bytes = NULL;
        
        if (capacity > 0) {
            size_t bufferSize = capacity * sizeof(char);
            self.bytes = (char *)malloc(bufferSize);
        }
    }
    
    return self;
}

- (void)dealloc
{
    if (self.bytes) {
        free(self.bytes);
        self.bytes = NULL;
        self.length = 0;
        self.full = NO;
    }
}

- (void)appendBytes :(const void *)bytes length:(NSUInteger)length
{
    assert(bytes);
    assert(length != 0);
    assert(length < 5242880);//断言原始数据不会超过5M
    
    if (bytes == NULL || length == 0) {
        return;
    }
    
    if (!self.bytes)
        return;
    
    //判断大小是否超出buffer的最大长度
    if (self.length + length <= self.capacity) {
        void *dst = (char *)self.bytes + self.length;
        memcpy(dst,bytes,length);
        self.length += length;
    }
}

- (void)clear
{
    if (!self.bytes)
        return;
    
    //重置buffer长度
    memset(self.bytes, 0, self.capacity);
    [self setLength:0];
    [self setFull:NO];
}


@end
