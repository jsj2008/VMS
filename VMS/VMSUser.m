//
//  VMSUser.m
//  VMS
//
//  Created by mac_dev on 15/10/21.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "VMSUser.h"

@interface VMSUser()
@property (readwrite) int uniqueId;
@property (readwrite) NSString *userName;
@property (readwrite) NSString *password;
@property (readwrite) NSString *remark;
@property (readwrite) int groupId;
@end

@implementation VMSUser

- (instancetype) initWithUniqueId :(int)uniqueId
                         userName :(NSString *)userName
                         password :(NSString *)psw
                           remark :(NSString *)remark
                          gorupId :(int)groupId;
{
    if (self = [super init]) {
        self.uniqueId = uniqueId;
        self.userName = userName;
        self.password = psw;
        self.remark = remark;
        self.groupId = groupId;
    }
    
    return self;
}
@end
