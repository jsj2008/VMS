//
//  Group.m
//  VMS
//
//  Created by mac_dev on 15/7/8.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "Group.h"

@interface Group()
@end

@implementation Group


- (id)initWithUniqueId :(int)uniqueId
                  name :(NSString *)name
                  type :(int)type
                remark :(NSString *)remark
{
    if (self = [super initWithUniqueId:uniqueId name:name]) {
        self.type = type;
        self.remark = remark;
    }
    
    return self;
}


#pragma mark - copying delegate
#pragma mark - nscopying delegate
- (id)copyWithZone:(NSZone *)zone
{
    Group *copy = [[[self class] allocWithZone:zone] initWithUniqueId :self.uniqueId
                                                                 name :self.name
                                                                 type :self.type
                                                               remark :self.remark];
    
    return copy;
}

- (void)dealloc
{
//    if (self.type == 3) {
//        NSLog(@"Root group %ld dealloc",self.uniqueId);
//    } else {
//        NSLog(@"Group %ld dealloc",self.uniqueId);
//    }
}
@end
