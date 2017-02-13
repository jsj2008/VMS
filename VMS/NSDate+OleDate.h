//
//  NSDate+OleDate.h
//  VMS
//
//  Created by mac_dev on 15/8/20.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Foundation/Foundation.h>
#define SEC_PER_DAY 86400.0

@interface NSDate (OleDate)

+ (NSDate *)date1899;
+ (NSDate *)dateWithOleTimeStamp :(double)oleTimeStamp;
- (double)oleTimeStamp;

@end
