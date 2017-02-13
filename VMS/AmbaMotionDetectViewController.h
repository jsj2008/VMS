//
//  AmbaDetectViewController.h
//  
//
//  Created by mac_dev on 16/5/25.
//
//

#import "MotionDetectViewController.h"


@interface AmbaMotionDetectViewController : MotionDetectViewController

- (void)fetch;
- (void)push;
- (DetectionAreasEditWindowController *)daewc;
- (void)onEditDone:(void *)cfg;

@end
