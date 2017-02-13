//
//  HsDetectionAreaEditWindowController.h
//  
//
//  Created by mac_dev on 16/4/5.
//
//

#import "DetectionAreasEditWindowController.h"
#import "AreaEditView.h"

@interface HsDetectionAreaEditWindowController : DetectionAreasEditWindowController<AreaEditViewDelegate> {
    FOS_MOTIONDETECTCONFIG _detectConfig;
}

- (instancetype)initWithWindowNibName:(NSString *)windowNibName
                            channelId:(int)channelId
                         detectConfig:(FOS_MOTIONDETECTCONFIG)config;
- (void *)detectConfig;
- (void)preDone;
@end
