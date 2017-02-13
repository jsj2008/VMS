//
//  HsDetectSettingViewController.h
//  
//
//  Created by mac_dev on 16/4/1.
//
//

#import "DetectSettingViewController.h"
#import "HsDetectionAreaEditWindowController.h"

@interface HsDetectSettingViewController : DetectSettingViewController

@property (nonatomic,assign) FOS_MOTIONDETECTCONFIG motionDetectConfig;
- (void)fetch;
- (void)push;
- (NSString *)description;

- (void)performFetch;
- (void)performPush;
- (void)updateMotionDetectConfigUI;
- (void)setMDC :(void *)config;
- (DetectionAreasEditWindowController *)daewc;
@end
