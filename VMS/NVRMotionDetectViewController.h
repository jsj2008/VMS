//
//  NVRHsMotionDetectViewController.h
//  
//
//  Created by mac_dev on 16/5/30.
//
//

#import "MotionDetectViewController.h"
#import "AmbaDetectionAreaEditWindowController.h"
#import "HsDetectionAreaEditWindowController.h"

@interface NVRMotionDetectViewController : MotionDetectViewController

- (void)fetchHsMotionConfig;
- (void)fetchAmbaMotionConfig;
- (void)pushHsDetectConfig;
- (void)pushAmbaDetectConfig;

- (NSArray *)linkages;
- (NSString *)audioAlarmTitle;

@end
