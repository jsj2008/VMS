//
//  DeviceConnectionSettingSheetController.m
//  VMS
//
//  Created by mac_dev on 15/12/2.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "DeviceConnectionSettingSheetController.h"
#import "ModifyLoginInfoSheetController.h"

@interface DeviceConnectionSettingSheetController ()

@property (nonatomic,strong,readwrite) CDevice *device;

@property (nonatomic,weak) IBOutlet NSTextField *nameTF;
@property (nonatomic,weak) IBOutlet NSComboBox *type;
@property (nonatomic,weak) IBOutlet NSTextField *chnCountTF;
@property (nonatomic,weak) IBOutlet NSTextField *macAddrTF;
@property (nonatomic,weak) IBOutlet NSTextField *portTF;
@property (nonatomic,weak) IBOutlet NSTextField *userNameTF;
@property (nonatomic,weak) IBOutlet NSTextField *passwordTF;
@property (nonatomic,weak) IBOutlet NSProgressIndicator *indicator;
@property (nonatomic,strong) NSAlert *alert;
@property (nonatomic,strong) ModifyLoginInfoSheetController *modifyLoginInfoSheetController;

@end

@implementation DeviceConnectionSettingSheetController

#pragma mark - life circle
- (instancetype)initWithWindowNibName:(NSString *)windowNibName
                               device:(CDevice *)device
{
    if (self = [super initWithWindowNibName:windowNibName]) {
        self.device = device;
    }
    
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [self updateUI];
    [self setActive:NO];
    [self setAlert:[[NSAlert alloc] init]];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}


- (void)updateUI
{
    self.nameTF.stringValue = self.device.name;
    //self.type = self.device.type;
    [self.type selectItemAtIndex:self.device.type];
    [self.type setEnabled:NO];
    self.chnCountTF.integerValue = self.device.channelCount;
    self.chnCountTF.enabled = NO;
    self.macAddrTF.stringValue = self.device.macAddress;
    self.macAddrTF.enabled = NO;
    self.portTF.integerValue = self.device.port;
    self.userNameTF.stringValue = self.device.userName;
    self.passwordTF.stringValue = self.device.userPsw;
}

- (NSArray *)deviceTypes
{
    return @[@"FOSCAM IPC",@"FOSCAM NVR"];
}

- (void)centerWindow :(NSWindow *)w1 fromWindow :(NSWindow *)w2
{
    NSPoint origin = w2.frame.origin;
    
    origin.x += (w2.frame.size.width - w1.frame.size.width) / 2.0;
    origin.y += (w2.frame.size.height - w1.frame.size.height) / 2.0;
    
    [w1 setFrameOrigin:origin];
}
#pragma mark - interaction
- (CDevice *)deviceFromUI
{
    return [[CDevice alloc] initWithUniqueId:self.device.uniqueId
                                        name:self.nameTF.stringValue
                                        type:self.device.type
                                          ip:self.device.ip
                                        port:self.portTF.intValue
                                    userName:self.userNameTF.stringValue
                                     userPsw:self.passwordTF.stringValue
                                    rtspPort:self.portTF.intValue
                                  macAddress:self.macAddrTF.stringValue
                                serialNumber:self.device.serialNumber
                                decorderType:self.device.decoderType
                                channelCount:self.device.channelCount
                                       Group:nil];
}

- (IBAction)done :(id)sender
{
    //检查UI元素的合法性
    DCSSC_ERR errCode = [self checkParam];
    if (errCode != DCSSC_NO_ERROR) {
        NSString *msg = [self errMessage:errCode];
        self.alert.messageText = msg;
        [self.alert beginSheetModalForWindow:self.window completionHandler:NULL];
        return;
    }
    
    //查看登录信息是否发生改变
    if ([self isLoginDataChanged]) {
        //登录信息发生了改变，需要测试新的登录信息是否合法
        long userId = -1;
        int chnCnt = 0;
        int result = FOSCMDRET_FAILD;
        CDevice *device = [self deviceFromUI];
        
        if (userId = [DispatchCenter loginDeviceSync:device channelCnt:&chnCnt result:&result], userId >= 0) {
            BOOL cancel = NO;
            
            //查看是否是第一次登录
            if ([self.userNameTF.stringValue isEqualToString:@"admin"] &&
                [self.passwordTF.stringValue isEqualToString:@""]) {
                //设置是否强制使用默认用户名
                self.modifyLoginInfoSheetController.useDefaultUser = (device.type == NVR);
                //修改密码
                NSWindow *wnd = self.modifyLoginInfoSheetController.window;
                [self centerWindow:wnd fromWindow:self.window];
                
                switch ([NSApp runModalForWindow:wnd]) {
                    case NSModalResponseCancel:
                        cancel = YES;
                        break;
                        
                    case NSModalResponseOK: {
                        ModifyLoginInfo *info = self.modifyLoginInfoSheetController.info;
                        //通知中心 修改用户名于密码
                        if ([DispatchCenter modifyDeviceLoginInfo:device
                                                       withUserId:userId
                                                             user:info.modifiedName
                                                              psw:info.modifiedPwd]) {
                            self.userNameTF.stringValue = info.modifiedName;
                            self.passwordTF.stringValue = info.modifiedPwd;
                        }
                        else {
                            cancel = YES;
                            [self.alert setMessageText:NSLocalizedString(@"failed to modify login password", nil)];
                            [self.alert beginSheetModalForWindow:self.window completionHandler:NULL];
                        }
                    }
                        break;
                    default:
                        break;
                }
                
                [self.modifyLoginInfoSheetController close];
                [self setModifyLoginInfoSheetController:nil];
            }
            
            if (!cancel) {
                [self doOutput];
            }
        }
        else {
            [self.alert setMessageText:NSLocalizedString(@"the connection is not available", nil)];
            [self.alert setInformativeText:[DispatchCenter foscamReturnMessage:result]];
            [self.alert beginSheetModalForWindow:self.window completionHandler:NULL];
        }
        
        [DispatchCenter logoutDeviceSync:device withUserId:userId];
    } else {
        [self doOutput];
    }
}

- (IBAction)cancel :(id)sender
{
    if (NSAppKitVersionNumber < NSAppKitVersionNumber10_9)
        [[NSApplication sharedApplication] endSheet:self.window returnCode:NSModalResponseCancel];
    else
        [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
}

- (BOOL)isLoginDataChanged
{
    NSInteger port = self.portTF.integerValue;
    NSString *userName = self.userNameTF.stringValue;
    NSString *userPsw = self.passwordTF.stringValue;
    
    return self.device.port != port ||
    ![self.device.userName isEqualToString:userName] ||
    ![self.device.userPsw isEqualToString:userPsw];
}

- (void)doOutput
{
    self.device.name = self.nameTF.stringValue;
    self.device.port = self.portTF.intValue;
    self.device.userName = self.userNameTF.stringValue;
    self.device.userPsw = self.passwordTF.stringValue;
    

    if (NSAppKitVersionNumber < NSAppKitVersionNumber10_9)
        [[NSApplication sharedApplication] endSheet:self.window returnCode:NSModalResponseOK];
    else
        [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
}

- (IBAction)test :(id)sender
{
    CDevice *device = [[CDevice alloc] initWithUniqueId:self.device.uniqueId
                                                   name:self.nameTF.stringValue
                                                   type:self.device.type
                                                     ip:self.device.ip
                                                   port:self.portTF.intValue
                                               userName:self.userNameTF.stringValue
                                                userPsw:self.passwordTF.stringValue
                                               rtspPort:self.portTF.intValue
                                             macAddress:self.macAddrTF.stringValue
                                           serialNumber:self.device.serialNumber
                                           decorderType:self.device.decoderType
                                           channelCount:self.device.channelCount
                                                  Group:nil];
    
    [self setActive:YES];
    [sender setEnabled:NO];
    [DispatchCenter testDeviceValid:device
               withCompletingHandle:^(BOOL state,int code)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.alert.messageText = state? NSLocalizedString(@"the connection is available", nil) : NSLocalizedString(@"the connection is not available", nil);
            self.alert.informativeText = [DispatchCenter foscamReturnMessage:code];
            
            [self.alert beginSheetModalForWindow:self.window
                               completionHandler:^(NSModalResponse returnCode) {
                                   [sender setEnabled:YES];
                               }];
            [self setActive:NO];
        });
    }];
}


#pragma mark - error handle
- (DCSSC_ERR)checkParam
{
    DCSSC_ERR errCode = DCSSC_NO_ERROR;
    
    do {
        //设备名
        NSString *name = self.nameTF.stringValue;
        if (!name || [name isEqualToString:@""]) {
            errCode = DCSSC_EMPTY_DEVICE_NAME;
            break;
        }
        
        //用户名
        NSString *userName = self.userNameTF.stringValue;
        if (!userName || [userName isEqualToString:@""]) {
            errCode = DCSSC_EMPTY_USER_NAME;
            break;
        }
    } while (0);
    
    return errCode;
}

- (NSString *)errMessage :(DCSSC_ERR)err
{
    NSString *errMsg = NSLocalizedString(@"unknow error", nil);
    
    switch (err) {
        case DCSSC_EMPTY_DEVICE_NAME:
            errMsg = NSLocalizedString(@"the device name is empty", nil);
            break;
            
        case DCSSC_EMPTY_USER_NAME:
            errMsg = NSLocalizedString(@"the user id is empty", nil);
            break;
            
        case DCSSC_NO_ERROR:
            errMsg = NSLocalizedString(@"no error", nil);
            break;
            
        default:
            break;
    }
    
    return errMsg;
}
#pragma mark - setter && getter 
- (void)setDevice:(CDevice *)device
{
    _device = device;
    [self updateUI];
}

- (void)setActive :(BOOL)active
{
    if (active)
        [self.indicator startAnimation:self];
    else
        [self.indicator stopAnimation:self];
    
    self.indicator.hidden = !active;
}

- (ModifyLoginInfoSheetController *)modifyLoginInfoSheetController
{
    if (!_modifyLoginInfoSheetController) {
        _modifyLoginInfoSheetController = [[ModifyLoginInfoSheetController alloc] initWithWindowNibName:@"ModifyLoginInfoSheetController"];
    }
    
    return _modifyLoginInfoSheetController;
}



@end
