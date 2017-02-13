//
//  DateRange.m
//  VMS
//
//  Created by mac_dev on 15/12/30.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "DateRange.h"

@implementation DateRange

- (instancetype)initWithStartDate :(NSDate *)start
                          endDate :(NSDate *)end
{
    if (self = [super init]) {
        self.startDate = start;
        self.endDate = end;
    }
    
    return self;
}

+ (instancetype)dateRangeWithStartDate :(NSDate *)start
                               endDate :(NSDate *)end
{
    
    return [[[self class] alloc] initWithStartDate:start endDate:end];
}

- (BOOL)isContainDate :(NSDate *)date
{
    if (!self.startDate || !self.endDate)
        return NO;
    
    return ([date compare:self.startDate] != NSOrderedAscending &&
    [date compare:self.endDate] != NSOrderedDescending);
}

@end
