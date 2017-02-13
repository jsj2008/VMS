//
//  VMSVersionControll.h
//  VMS
//
//  Created by mac_dev on 15/12/31.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Foundation/Foundation.h>



#define VMS_ALPHA_V0_0_0    @"V0.0.0"
#define VMS_ALPHA_V0_0_1    @"V0.0.1"
#define VMS_ALPHA_V0_0_3    @"V0.0.3"
#define VMS_ALPHA_V0_0_5    @"V0.0.5"
#define VMS_BROAD_BEAN_BETA @"V0.1.2"

@interface VMSVersionManager : NSObject


+ (NSString *)latestVersion;
+ (NSComparisonResult)compareVersion :(NSString *)VA
                         withVersion :(NSString *)VB;

+ (BOOL)getVersion:(NSString *)version
             major:(int *)major
             minor:(int *)minor
          revision:(int *)revision;
@end
