//
//  NSString+VMSVideoFileName.h
//  VMS
//
//  Created by mac_dev on 16/1/11.
//  Copyright (c) 2016年 mac_dev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSDate + SRAdditions.h"

@interface NSString (VMSVideoFileName)

- (void)getVideoType :(NSInteger *)type
           beginDate :(NSDate **)beginDate
             endDate :(NSDate **)endDate;
@end
