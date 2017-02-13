//
//  NVRPTZSpeedViewController.h
//  
//
//  Created by mac_dev on 16/5/30.
//
//

#import "PTZSpeedViewController.h"

@interface NVRPTZSpeedViewController : PTZSpeedViewController

- (void)fetch;
- (void)push;
- (NSString *)description;
- (FOS_NVR_PTZ_SPEED)nvrSpeedFromUI;
@end
