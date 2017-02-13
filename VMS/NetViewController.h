//
//  NetViewController.h
//  
//
//  Created by mac_dev on 16/5/26.
//
//

#import "SettingViewController.h"

typedef NS_ENUM(NSUInteger, NSVC_ERR) {
    NSVC_NO_ERR,
    NSVC_IP_FOMATE_ERR,
    NSVC_MASK_FOMATE_ERR,
    NSVC_GATE_FOMATE_ERR,
    NSVC_DNS1_FOMATE_ERR,
    NSVC_DNS2_FOMATE_ERR,
    NSVC_INVALID_HTTP_PORT,
    NSVC_INVALID_HTTPS_PORT,
    NSVC_INVALID_ONVIF_PORT,
    NSVC_SAME_PORT,
};



#define VMS_INVALIDP_PORT   -1
#define VMS_MIN_PORT        1
#define VMS_MAX_PORT        65535

@interface NetViewController : SettingViewController
@property (assign,nonatomic) FOS_IPINFO ipInfo;
@property (assign,nonatomic) FOS_UPNPCONFIG upnpConfig;
@property (assign,nonatomic) FOS_PORTINFO portInfo;

//ip
@property (nonatomic,assign) BOOL isDHCP;
@property (nonatomic,weak) IBOutlet NSTextField *ip;
@property (nonatomic,weak) IBOutlet NSTextField *mask;
@property (nonatomic,weak) IBOutlet NSTextField *gate;
@property (nonatomic,weak) IBOutlet NSTextField *dns1;
@property (nonatomic,weak) IBOutlet NSTextField *dns2;

//upnp
@property (nonatomic,assign) BOOL isUPNP;

//port
@property (weak) IBOutlet NSTextField *webPort;
@property (weak) IBOutlet NSTextField *httpsPort;
@property (weak) IBOutlet NSTextField *onvifPort;


- (void)fetch;
- (void)push;
- (NSString *)description;
- (NSVC_ERR)parserIP;
- (NSVC_ERR)parserPort;
- (NSString *)errMsg :(NSVC_ERR)code;
@end
