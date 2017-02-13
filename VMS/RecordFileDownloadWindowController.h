//
//  RecordFileDownloadWindowController.h
//  
//
//  Created by mac_dev on 16/6/22.
//
//

#import <Cocoa/Cocoa.h>
#import "../FoscamNetSDK/IPCSDK_for_mac150629/include/FosNvrDef.h"
#import "../FoscamNetSDK/NVR/FoscamNvrNetSDK.h"
#import "NSDate + SRAdditions.h"
#import "DispatchCenter.h"
#import "CheckboxHeaderCell.h"

#define KEY_CHECKED @"checked"
#define KEY_NUM     @"num"
#define KEY_DEV     @"dev"
#define KEY_NODE    @"node"
#define KEY_CHN     @"chn"
#define KEY_TYPE    @"type"
#define KEY_ST      @"st"
#define KEY_ET      @"et"
#define KEY_SIZE    @"size"
#define KEY_PRO     @"pro"


typedef NS_ENUM(NSUInteger, Download_Event) {
    Download_Event_Cancel,
    Download_Event_EXP,
    Download_Event_Complete,
};

@interface RecordFileDownloadWindowController : NSWindowController<NSTableViewDataSource,
NSTableViewDelegate,NSOpenSavePanelDelegate,DispatchProtocal>

@property(nonatomic,strong) NSArray *recordFilesInfo;
@end
