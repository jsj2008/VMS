//
//  AmbaDetectSettingViewController.h
//  
//
//  Created by mac_dev on 16/4/1.
//
//

#import "DetectSettingViewController.h"
#import "AmbaDetectionAreaEditWindowController.h"

@interface AmbaDetectSettingViewController : DetectSettingViewController

@property (nonatomic,assign) FOS_MOTIONDETECTCONFIG1 motionDetectConfig;

- (void)performFetch;
- (void)performPush;
- (void)updateMotionDetectConfigUI;
- (void)setMDC :(void *)config;
- (DetectionAreasEditWindowController *)daewc;
@end
