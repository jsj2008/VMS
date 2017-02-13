//
//  VMSLog.m
//  VMS
//
//  Created by mac_dev on 15/10/23.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "Log.h"



@interface Log()
@property (readwrite) int uniqueId;
@property (readwrite) NSString *opt;
@property (readwrite) NSString *date;
@property (readwrite) NSString *type;
@property (readwrite) NSString *event;
@end

@implementation Log

- (instancetype)initWithUniqueId:(int)uniqueId
                        operator:(NSString *)opt
                            date:(NSString *)date
                            type:(NSString *)type
                           event:(NSString *)event
{
    if (self = [super init]) {
        self.uniqueId = uniqueId;
        self.opt = opt;
        self.date = date;
        self.type = type;
        self.event = event;
        
    }
    
    return self;
}
@end
