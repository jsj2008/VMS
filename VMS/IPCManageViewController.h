//
//  IPCManageViewController.h
//  
//
//  Created by mac_dev on 16/6/2.
//
//

#import "SettingViewController.h"
#import "VMSTableView.h"

#define MAX_CHANNEL_COUNT   12

typedef struct
{
    FOS_CHANNEL_INFO chnInfo[MAX_CHANNEL_COUNT];
    int cnt;
}FOS_NVR_IPC_LIST;


typedef NS_ENUM(NSUInteger, CH_INFO_ERR) {
    CH_INFO_NO_ERR,
    CH_INFO_EMPTY_DEVICE_NAME,
    CH_INFO_EMPTY_URL,
    CH_INFO_EMPTY_PORT,
    CH_INFO_EMPTY_USERNAME,
};

@interface IPCManageViewController : SettingViewController<NSTableViewDataSource,NSTableViewDelegate,ExtendedTableViewDelegate>

@property(nonatomic,assign) FOS_NVR_IPC_LIST nvrIPCList;
@property(nonatomic,assign) BOOL autoAddIPC;

- (NSString *)description;
- (SVC_OPTION)option;

@end
