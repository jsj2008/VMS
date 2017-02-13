//
//  Poll.h
//  VMS
//
//  Created by mac_dev on 15/9/3.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Group.h"
#import "Channel.h"
@interface Poll : NSObject

@property (assign) int uniqueId;
@property (weak) Group *group;//轮巡组
@property (assign) int channelId;//通道
@property (assign) int waitSec;//等待时间
@property (assign) int sequenceNum;//轮巡顺序

- (id)initWithUniqueId :(int)uniqueId
                 group :(Group *)group
             channelId :(int)channelId
               waitSec :(int)waitSec
           sequenceNum :(int)sequenceNum;
@end
