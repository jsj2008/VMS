//
//  AmbaDetectionAreaEditWindowController.h
//  VMS
//
//  Created by Jeff on 16/4/2.
//  Copyright (c) 2016年 mac_dev. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DetectionAreasEditWindowController.h"
#import "AmbaDetectComponentViewController.h"
#import "PrivacyCoverEditView.h"

@interface AmbaDetectionAreaEditWindowController : DetectionAreasEditWindowController {
    FOS_MOTIONDETECTCONFIG1 _detectConfig;
}

- (instancetype)initWithWindowNibName:(NSString *)windowNibName
                            channelId:(int)channelId
                         detectConfig:(FOS_MOTIONDETECTCONFIG1)config;
- (void *)detectConfig;
- (void)preDone;
@end

