//
//  OSDViewController.h
//  
//
//  Created by mac_dev on 16/5/23.
//
//

#import "SettingViewController.h"
#import "PrivacyCoverEditWindowController.h"

@interface OSDViewController : SettingViewController

@property (nonatomic,weak) IBOutlet NSPopUpButton *osdMaskEnableBtn;
@property (nonatomic,weak) IBOutlet NSButton *privacyCoverEditBtn;
@property (assign,nonatomic) FOS_OSDConfigMsg osdConfigMsg;
@property (assign,nonatomic) int osdMaskEnable;
@property (assign,nonatomic) FOS_OSDMASKAREA osdMaskArea;

- (void)fetch;
- (void)push;
- (NSString *)description;
- (BOOL)enableOSD;
- (BOOL)enablePrivacyCover;
- (FOS_OSDConfigMsg)osdConfigMsgFromUI;
- (int)osdMaskEnableFromUI;

@end
