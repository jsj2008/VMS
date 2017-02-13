//
//  NVRSmtpViewController.h
//  
//
//  Created by mac_dev on 16/5/26.
//
//

#import "SmtpViewController.h"

@interface NVRSmtpViewController : SmtpViewController

- (void)fetch;
- (void)push;
- (BOOL)urlNeedEncode;
- (BOOL)performTestSmtp;
@end
