//
//  ChannelInfoCellView.h
//  
//
//  Created by mac_dev on 16/6/3.
//
//

#import <Cocoa/Cocoa.h>
#import "../FoscamNetSDK/NVR/FoscamNvrNetSDK.h"

typedef enum _AppPotocol_
{
    AP_FS = (1 << 0),
    AP_RC = (1 << 1),
    AP_RTSP = (1 << 2),
    AP_ONVIF = (1 << 3),
    AP_UNKNOW,
}AppProtocol_e;

@interface ChannelInfoCellView : NSTableCellView

@property(nonatomic,assign) FOS_CHANNEL_INFO chnInfo;
- (FOS_CHANNEL_INFO)chnInfoFromUI;
@end
