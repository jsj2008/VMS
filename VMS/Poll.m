//
//  Poll.m
//  VMS
//
//  Created by mac_dev on 15/9/3.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "Poll.h"

@implementation Poll

- (id)initWithUniqueId :(int)uniqueId
                 group :(Group *)group
             channelId :(int)channelId
               waitSec :(int)waitSec
           sequenceNum :(int)sequenceNum;
{
    if (self = [super init]) {
        self.uniqueId = uniqueId;
        self.group = group;
        self.channelId = channelId;
        self.waitSec = waitSec;
        self.sequenceNum = sequenceNum;
    }
    
    return self;
}
@end
