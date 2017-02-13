//
//  TimeScheduleView.h
//  VMS
//
//  Created by mac_dev on 15/6/29.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSUInteger, TPV_STYLE) {
    StartWithMonday,
    StartWithSunday,
};

@interface TimePickerView : NSView
@property(nonatomic,assign) TPV_STYLE style;

- (void)reloadData;
- (void)setSchedule :(long long[7])schedule;
- (BOOL)getSchedule :(long long[]) schedule lenght :(NSUInteger)len;

@end
