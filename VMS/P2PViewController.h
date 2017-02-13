//
//  P2PViewController.h
//  
//
//  Created by mac_dev on 16/5/23.
//
//

#import "SettingViewController.h"

typedef NS_ENUM(NSUInteger, P2P_ERR) {
    P2P_NO_ERR,
    P2P_INVALID_P2P_PORT,
};

#define VMS_MIN_PORT    1
#define VMS_MAX_PORT    65533

@interface P2PViewController : SettingViewController

@property (assign,nonatomic) FOS_P2PENABLE p2pEnableInfo;
@property (assign,nonatomic) FOS_P2PINFO p2pInfo;
@property (assign,nonatomic) FOS_P2PPORT p2pPortInfo;

- (void)fetch;
- (void)push;
- (NSString *)description;

@end
