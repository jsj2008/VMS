//
//  NSDate+HalfHour.h
//  VMS
//
//  Created by mac_dev on 15/8/25.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (HalfHour)
- (int)floorHalfHour;
- (int)ceilHalfHour;
+ (NSDate *)dateFromHalfHour :(int)halfHour;
@end
