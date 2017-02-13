//
//  UserGroup.h
//  VMS
//
//  Created by mac_dev on 15/10/22.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserGroup : NSObject

- (instancetype)initWithUniqueId :(int)uniqueId
                       groupName :(NSString *)name
                          remark :(NSString *)remark
                           right :(NSString *)right
                           level :(int)level;
@property (assign,readonly) int uniqueId;
@property (strong,readonly) NSString *groupName;
@property (strong,readonly) NSString *remark;
@property (strong,readonly) NSString *right;
@property (assign,readonly) int level;
@end
