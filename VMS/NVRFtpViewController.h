//
//  NVRFtpViewController.h
//  
//
//  Created by mac_dev on 16/5/27.
//
//

#import "FtpViewController.h"

@interface NVRFtpViewController : FtpViewController

- (void)fetch;
- (void)push;
- (BOOL)urlNeedEncode;
- (BOOL)performTestFtp;

@end
