//
//  VMSUser.h
//  VMS
//
//  Created by mac_dev on 15/10/21.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Foundation/Foundation.h>
#define ROOT    @"admin"

@interface VMSUser : NSObject

- (instancetype) initWithUniqueId :(int)uniqueId
                         userName :(NSString *)userName
                         password :(NSString *)psw
                           remark :(NSString *)remark
                          gorupId :(int)groupId;

@property (nonatomic,assign,readonly) int uniqueId;
@property (nonatomic,strong,readonly) NSString *userName;
@property (nonatomic,strong,readonly) NSString *password;
@property (nonatomic,strong,readonly) NSString *remark;
@property (nonatomic,assign,readonly) int groupId;

@end
