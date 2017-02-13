//
//  VMSLog.h
//  VMS
//
//  Created by mac_dev on 15/10/23.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Log : NSObject

- (instancetype)initWithUniqueId :(int)uniqueId
                        operator :(NSString *)opt
                            date :(NSString *)date
                            type :(NSString *)type
                           event :(NSString *)event;


@property (assign,readonly) int uniqueId;
@property (strong,readonly) NSString *opt;
@property (strong,readonly) NSString *date;
@property (strong,readonly) NSString *type;
@property (strong,readonly) NSString *event;


@end
