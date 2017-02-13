//
//  UserGroup.m
//  VMS
//
//  Created by mac_dev on 15/10/22.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "UserGroup.h"
@interface UserGroup()
@property (readwrite) int uniqueId;
@property (readwrite) NSString *groupName;
@property (readwrite) NSString *remark;
@property (readwrite) NSString *right;
@property (readwrite) int level;
@end
@implementation UserGroup

- (instancetype)initWithUniqueId :(int)uniqueId
                       groupName :(NSString *)name
                          remark :(NSString *)remark
                           right :(NSString *)right
                           level :(int)level
{
    if (self = [super init]) {
        self.uniqueId = uniqueId;
        self.groupName = name;
        self.remark = remark;
        self.right = right;
        self.level = level;
    }
    
    return self;
}
@end
