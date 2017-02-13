//
//  DateRange.h
//  VMS
//
//  Created by mac_dev on 15/12/30.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DateRange : NSObject

@property (nonatomic, retain) NSDate * startDate;
@property (nonatomic, retain) NSDate * endDate;

- (instancetype)initWithStartDate :(NSDate *)start
                          endDate :(NSDate *)end;
+ (instancetype)dateRangeWithStartDate :(NSDate *)start
                               endDate :(NSDate *)end;

- (BOOL)isContainDate :(NSDate *)date;
@end
