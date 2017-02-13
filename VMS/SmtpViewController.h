//
//  SmtpViewController.h
//  
//
//  Created by mac_dev on 16/5/26.
//
//

#import "SettingViewController.h"

typedef NS_ENUM(NSUInteger, SMTP_ERR) {
    SMTP_NO_ERR,
    SMTP_SERVER_FMT_ERR,
    SMTP_PORT_ERR,
    SMTP_USER_NAME_FMT_ERR,
    SMTP_USER_PSW_FMT_ERR,
    SMTP_SENDER_FMT_ERR,
    SMTP_RECEIVER_FMT_ERR,
};

@interface SmtpViewController : SettingViewController

@property (assign,nonatomic) FOS_SMTPCONFIG smtpConfig;

- (void)fetch;
- (void)push;
- (NSString *)description;
- (SVC_OPTION)option;
- (FOS_SMTPCONFIG)smtpConfigFromUI;
- (BOOL)urlNeedEncode;
- (BOOL)performTestSmtp;
- (int)checkSmtpFmtInvalid;
- (NSString *)errMsg :(SMTP_ERR)code;
@end
