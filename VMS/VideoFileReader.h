//
//  VideoFileReader.h
//  VMS
//
//  Created by mac_dev on 15/8/19.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../FoscamNetSDK/RecordDef.h"
#import "NSDate+OleDate.h"
#import "Channel.h"
@interface VideoFileReader : NSObject

@property (copy,readonly) NSString *path;

- (id)initWithFilePath :(NSString *)path;
- (void)dealloc;
- (void)open;
- (void)close;
- (NSDate *)begin;
- (NSDate *)end;
- (int)type;
- (size_t)read :(void *)buffer size :(size_t)size;
- (size_t)read :(void *)buffer
          size :(size_t)size
          type :(int *)type
     timestamp :(double *)timestamp;
- (void)seekWithDate :(NSDate *)date;
- (Channel *)channel;
@end
