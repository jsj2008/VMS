//
//  VMSLoginPanelController.m
//  VMS
//
//  Created by mac_dev on 15/10/21.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "VMSLoginPanelController.h"


@interface VMSLoginPanelController ()

@property (readwrite) VMS_OP op;
@property (nonatomic,weak) IBOutlet NSButton *ok;
@property (nonatomic,weak) IBOutlet NSTextField *userName;
@property (nonatomic,weak) IBOutlet NSTextField *password;
@property (assign,getter = isSavePassword) BOOL savePassword;
@property (assign,getter = isAutoLogin) BOOL autoLogin;
@property (nonatomic,strong) IBOutlet NSView *box;
@property (nonatomic,strong) NSAlert *alert;
@property (nonatomic,weak) IBOutlet NSButton *autoLoginBtn;
@end



@implementation VMSLoginPanelController


- (instancetype)initWithWindowNibName:(NSString *)windowNibName vmsOperator:(VMS_OP)op
{
    if (self = [super initWithWindowNibName:windowNibName]) {
        self.op = op;
    }
    
    return self;
}

- (void)awakeFromNib
{
    //做一些初始化工作
    NSButton *closeButton = [self.window standardWindowButton:NSWindowCloseButton];
    NSButton *miniaturizeButton = [self.window standardWindowButton:NSWindowMiniaturizeButton];
    NSButton *zoomButton = [self.window standardWindowButton:NSWindowZoomButton];
    NSColor *backgroundColor = [NSColor colorWithCalibratedRed:50/255.0 green:137/255.0 blue:209/255.0 alpha:1.0];
    
    closeButton.target = self;
    closeButton.action = @selector(exitAction:);
    miniaturizeButton.hidden = YES;
    zoomButton.hidden = YES;
    
    [self.window setBackgroundColor:backgroundColor];
    //[self.autoLoginBtn setHidden:self.op !=
}

- (void)windowDidLoad {
    [super windowDidLoad];
    // 设置窗口背景色
    [self updateUI];
    
    if (self.op == VMS_LOGIN && self.autoLogin) {
        int64_t delay = 1.0;
        dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC);
        dispatch_after(when, dispatch_get_main_queue(), ^{
            [self done:nil];
            //[self performSelectorInBackground:@selector(done:) withObject:nil];
        });
    }
    
    self.ok.title = [self titleForOption:self.op];
}

- (NSString *)titleForOption :(VMS_OP)op
{
    NSString *title;
    
    switch (op) {
        case VMS_LOGIN:
        case VMS_TOGGLE_USER:
            title = NSLocalizedString(@"Login", nil);
            break;
            
        case VMS_LOGOFF:
            title = NSLocalizedString(@"Logout", nil);
            break;
            
        case VMS_UNLOCK:
            title = NSLocalizedString(@"Unlock", nil);
            break;
            
        default:
            title = NSLocalizedString(@"OK", nil);
            break;
    }
    
    return title;
}


- (void)updateUI
{
    // 数据库
    VMSDatabase *db = [VMSDatabase sharedVMSDatabase];
    // 加载登录配置
    VMSBasicSetting *basicSetting = self.basicSetting;
    self.savePassword = basicSetting.options & VMS_SAVE_PSW;
    self.autoLogin = basicSetting.options & VMS_AUTO_LOGIN;
    // 加载最近登录用户信息
    int latestUserId = basicSetting.latestUserId;
    VMSUser *latestUser = [db fetchUserWithUniqueId:latestUserId];
    // 更新用户名控件
    [self.userName setStringValue:latestUser? latestUser.userName : @"admin"];
    // 更新登录密码
    if (self.isSavePassword) {
        //加载最近登录帐号密码
        [self.password setStringValue:latestUser? latestUser.password : @""];
    }
}

#pragma mark - Action
- (IBAction)done :(id)sender
{
    NSString *name = [self.userName stringValue];
    NSString *psw = [self.password stringValue];
    
    [sender setEnabled:NO];
    [self loginWithUserName:name password:psw completion:^(NSString *err, VMSUser *vmsUser) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!err) {
                //Do success stuff
                //Update basic setting
                int options = self.basicSetting.options;
                options = self.isSavePassword? (options | VMS_SAVE_PSW) : (options & ~VMS_SAVE_PSW);
                options = self.isAutoLogin? (options | VMS_AUTO_LOGIN) : (options & ~VMS_AUTO_LOGIN);
                
                self.basicSetting.options = options;
                self.basicSetting.latestUserId = vmsUser.uniqueId;
                
                [self.basicSetting archive];
                [[NSApplication sharedApplication] stopModalWithCode:NSModalResponseOK];
                [self.window orderOut:self];
            } else {
                //Shake window and alert
                [self.window shakeWithDuration:0.1f
                                numberOfShakes:4
                                 vigourOfShake:0.02f
                                    completion:^
                 {
                     NSAlert *alert = self.alert;
                     [alert setMessageText:err];
                     [alert beginSheetModalForWindow:self.window completionHandler:nil];
                     [sender setEnabled:YES];
                 }];
            }
        });
    }];
}

- (void)loginWithUserName :(NSString *)name
                 password :(NSString *)psw
               completion :(void (^)(NSString *err,VMSUser *vmsUser))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        VMSDatabase *db = [VMSDatabase sharedVMSDatabase];
        VMSUser *vmsUser = [db fetchUserWithUserName:name password:psw];
        NSString *err = nil;
        
        if (!name || [name isEqualToString:@""]) {
            err = NSLocalizedString(@"user name is empty", nil);
        } else if (!vmsUser) {
            err = NSLocalizedString(@"user name or password is incorrect", nil);
        }
        
        completion(err,vmsUser);
    });
}

- (IBAction)autoLoginClicked :(id)sender
{
    BOOL isAutoLogin = self.isAutoLogin;
    BOOL isSavePassword = self.isSavePassword;
    self.savePassword = isAutoLogin? isAutoLogin : isSavePassword;
}

- (IBAction)exitAction :(id)sender
{
    [[NSApplication sharedApplication] stopModalWithCode:NSModalResponseCancel];
    [self.window orderOut:self];
}
#pragma mark - setter && getter
- (void)setUserName:(NSTextField *)userName
{
    _userName = userName;
    [_userName.cell setVerticalCentering:YES];
}

- (void)setPassword:(NSTextField *)password
{
    _password = password;
    [_password.cell setVerticalCentering:YES];
}

- (void)setOk:(NSButton *)ok
{
    _ok = ok;
    [_ok setTitleColor:[NSColor whiteColor]];
}

- (void)setBox:(NSView *)box
{
    _box = box;
    [_box setWantsLayer:YES];
    [_box.layer setBackgroundColor:[NSColor colorWithCalibratedRed:232/255.0 green:235/255.0 blue:236/255.0 alpha:1.0].CGColor];
}

- (NSAlert *)alert
{
    if (!_alert) {
        _alert = [[NSAlert alloc] init];
    }
    
    return _alert;
}

- (void)setBasicSetting:(VMSBasicSetting *)basicSetting
{
    _basicSetting = basicSetting;
    //[self updateUI];
}
@end
