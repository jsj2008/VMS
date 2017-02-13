//
//  NVRDeviceInfoViewController.h
//  
//
//  Created by mac_dev on 16/5/25.
//
//


#import "DeviceInfoViewController.h"
#import <CoreImage/CoreImage.h>


typedef struct _FOS_NVR_P2PINFO_						//p2p status.
{
    int enable;
    char uid[UID_LEN];
    int port;
    int type;
}FOS_NVR_P2PINFO;

@interface NVRDeviceInfoViewController : DeviceInfoViewController

@property (nonatomic,assign) FOS_NVR_P2PINFO p2pInfo;

- (void)fetch;
- (void)push;
- (SVC_OPTION)option;
- (NSString *)description;
@end
