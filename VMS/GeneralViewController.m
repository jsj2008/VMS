//
//  GeneralViewController.m
//  VMS
//
//  Created by mac_dev on 2016/10/24.
//  Copyright © 2016年 mac_dev. All rights reserved.
//

#import "GeneralViewController.h"
#import "JFPreferencePanelController+StartUp.h"

@interface GeneralViewController ()

@property (weak) IBOutlet NSTextField *capturePathName;//快照存放路径
@property (weak,nonatomic) IBOutlet NSTextField *pollTimeTF;
@property (weak) IBOutlet NSMatrix *wndStreamType;//预览视频码流类型
@property (assign) BOOL saveLayout;//保存摆放位置
@property (assign) BOOL autoRun;//自动运行
@property (assign) BOOL autoSearch;//自动查找
@property (assign) BOOL autoLogin;//自动登录

@end

@implementation GeneralViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (NSString *)panelTitle
{
    return NSLocalizedString(@"General", nil);
}

#pragma mark - load
- (void)load
{
    self.basicSetting = [[VMSBasicSetting alloc] initWithPath:[VMSPathManager vmsConfPath:YES]];
    [self updateUIWithBasicSetting:self.basicSetting];
}

- (void)updateUIWithBasicSetting :(VMSBasicSetting *)setting
{
    if (setting) {
        [self.capturePathName setStringValue:setting.capturePathName];
        [self.pollTimeTF setIntegerValue:setting.pollTime];
        [self.wndStreamType selectCellAtRow:setting.wndStreamType column:0];
        [self setSaveLayout:setting.options & VMS_SAVE_LAYOUT];
        [self setAutoRun :setting.options & VMS_AUTO_RUN];
        [self setAutoSearch:setting.options & VMS_AUTO_SEARCH];
        [self setAutoLogin:setting.options & VMS_AUTO_LOGIN];
    }
}

#pragma mark - action
- (IBAction)cancel:(id)sender
{
    [self goBack];
}

- (IBAction)done:(id)sender
{
    self.basicSetting.capturePathName = self.capturePathName.stringValue;
    
    int pollTime = self.pollTimeTF.intValue;
    if (pollTime < 5 || pollTime >3600) {
        NSAlert *alert = [[NSAlert alloc] init];
        
        alert.messageText = NSLocalizedString(@"Patrol time out of range", nil);
        alert.informativeText = @"";
        
        [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
        [alert runModal];
        return;
    }
    self.basicSetting.pollTime = self.pollTimeTF.intValue;
    self.basicSetting.wndStreamType = (int)self.wndStreamType.selectedRow;
    
    int options = self.basicSetting.options;
    options = self.saveLayout? (options | VMS_SAVE_LAYOUT) : (options & ~VMS_SAVE_LAYOUT);
    
    
    
    if ([JFPreferencePanelController setStartupAtBoot:self.autoRun]) {
        options = self.autoRun? (options | VMS_AUTO_RUN) : (options & ~VMS_AUTO_RUN);
    }
    
    options = self.autoSearch? (options | VMS_AUTO_SEARCH) : (options & ~VMS_AUTO_SEARCH);
    options = self.autoLogin? (options | VMS_AUTO_LOGIN) : (options & ~VMS_AUTO_LOGIN);
    self.basicSetting.options = options;
    
    //写入文件中
    [self.basicSetting archive];
    
    //发送广播通知
    [[NSNotificationCenter defaultCenter] postNotificationName:BASIC_SETTING_DID_CHANGE_NOTIFICATION
                                                        object:self
                                                      userInfo:nil];
    [self goBack];
}



@end
