//
//  Channel.m
//  VMS
//
//  Created by mac_dev on 15/7/10.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "Channel.h"
#import "CDevice.h"

@interface Channel()

@end

@implementation Channel
- (id)initWithUniqueId :(int)uniqueId
                  name :(NSString *)name
                  type :(int)type
               logicId :(int)logicId
               unused1 :(int)unused1
               unused2 :(int)unused2
                  mapX :(NSString *)mapX
                  mapY :(NSString *)mapY
         patrolGroupId :(int)patrolGroupId
               CDevice :(CDevice *)device
{
    if (self = [super initWithUniqueId:uniqueId name:name]) {
        self.type = type;
        self.logicId = logicId;
        self.unused1 = unused1;
        self.unused2 = unused2;
        self.mapX = mapX;
        self.mapY = mapY;
        self.patrolGroupId = patrolGroupId;
        self.device = device;
    }
    
    return self;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[self class]]) {
        return self.uniqueId == [object uniqueId];
    }
    return NO;
}

- (NSInteger)hash
{
    return self.uniqueId;
}

#pragma mark - nscopying delegate
- (id)copyWithZone:(NSZone *)zone
{
    Channel *copy = [[[self class] allocWithZone:zone] initWithUniqueId:self.uniqueId
                                                                   name:self.name
                                                                   type:self.type
                                                                logicId:self.logicId
                                                                unused1:self.unused1
                                                                unused2:self.unused2
                                                                   mapX:self.mapX
                                                                   mapY:self.mapY
                                                          patrolGroupId:self.patrolGroupId
                                                                CDevice:self.device];
    
    return copy;
}

- (void)dealloc
{
    //NSLog(@"Channel %ld dealloc",self.uniqueId);
}
@end
