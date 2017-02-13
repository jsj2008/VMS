//
//  FtpViewController.h
//  
//
//  Created by mac_dev on 16/5/26.
//
//

#import "SettingViewController.h"

@interface FtpViewController : SettingViewController

@property (assign,nonatomic) FOS_FTPCONFIG ftpConfig;

- (void)fetch;
- (void)push;
- (NSString *)description;
- (SVC_OPTION)option;
- (BOOL)urlNeedEncode;
- (FOS_FTPCONFIG)ftpConfigFromUI;
- (BOOL)performTestFtp;
@end
