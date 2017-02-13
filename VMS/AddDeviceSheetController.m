//
//  AddDeviceSheetController.m
//  VMS
//
//  Created by mac_dev on 15/7/9.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "AddDeviceSheetController.h"
#import "ModifyLoginInfoSheetController.h"
#include <arpa/inet.h>

//table view identifier
#define ID_DEVICE_LIST      @"device list"
#define ID_DISCOVERY_LIST   @"discovery list"

//table view column identifier
#define ID_NAME             @"name"
#define ID_TYPE             @"type"
#define ID_IP               @"ip"
#define ID_PORT             @"port"
#define ID_MAC              @"mac"


#define ID_CHECK_STATE      @"check"
#define MAX_CHANNEL_CNT     10

@interface AddDeviceSheetController ()<NSTableViewDataSource,NSTableViewDelegate>
//Data
@property (copy) NSArray *discoveries;
@property (nonatomic,weak) IBOutlet NSView *managementView;
@property (nonatomic,weak) IBOutlet NSPopUpButton *deviceTypeBtn;
@property (nonatomic,weak) IBOutlet NSTextField *deviceNameTF;
@property (nonatomic,weak) IBOutlet NSTextField *ipAddressTF;
@property (nonatomic,weak) IBOutlet NSTextField *macAddressTF;
@property (nonatomic,weak) IBOutlet NSTextField *portTF;
@property (nonatomic,weak) IBOutlet NSTextField *userNameTF;
@property (nonatomic,weak) IBOutlet NSSecureTextField *userPSWTF;
@property (nonatomic,weak) IBOutlet NSTextField *uidTF;
@property (nonatomic,assign) BOOL enableP2pConnection;
@property (nonatomic,weak) IBOutlet NSTextField *discoveryCountTF;
@property (nonatomic,weak) IBOutlet NSTableView *discoveryList;
@property (nonatomic,weak) IBOutlet NSButton *discoverBT;
@property (nonatomic,weak) IBOutlet NSButton *addBT;
@property (nonatomic,weak) IBOutlet NSPopUpButton *filterBT;
@property (strong,nonatomic) NSAlert *alert;
@property (nonatomic,assign) ADSC_ERR lastError;
@property (nonatomic,assign) FOSCMD_RESULT lastCode;
@property (nonatomic,strong) ModifyLoginInfoSheetController *modifyLoginInfoSheetController;

@end

@implementation AddDeviceSheetController

#pragma mark - life cycle
- (void)windowDidLoad {
    [super windowDidLoad];
    [self discovery :nil];
    [self setLastError :ADSC_NO_ERR];
}

- (void)dealloc
{
    NSLog(@"Add device sheet controller dealloc");
}

#pragma mark - user interaction
- (IBAction)cancel:(id)sender {
    if (NSAppKitVersionNumber < NSAppKitVersionNumber10_9)
        [[NSApplication sharedApplication] endSheet:self.window returnCode:NSModalResponseCancel];
    else
        [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
}

- (IBAction)add:(id)sender {
    CDevice *dev = [self manualAdd];
    
    //错误处理
    if (self.lastError == ADSC_NO_ERR) {
        if (dev) {
            self.device = dev;
            
            if (NSAppKitVersionNumber < NSAppKitVersionNumber10_9)
                [[NSApplication sharedApplication] endSheet:self.window returnCode:NSModalResponseCancel];
            else
                [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
        }
    } else {
        //添加失败
        self.alert = [[NSAlert alloc] init];
        self.alert.messageText = NSLocalizedString(@"failed to add device", nil);
        
        if (ADSC_LOGIN_FAILED == self.lastError) {
            self.alert.informativeText = [DispatchCenter foscamReturnMessage:self.lastCode];
        }
        else {
            self.alert.informativeText = [self errMsg:self.lastError];
        }
        
        [self.alert beginSheetModalForWindow:self.window completionHandler:NULL];
    }
}

//For test
- (IBAction)discovery:(id)sender {
    NSLog(@"Running in %@,'%@'",[self class],NSStringFromSelector(_cmd));
    
    [self.discoverBT setEnabled:YES];
    [DispatchCenter searchDevicesWithCompletingHandle:^(NSArray *devices) {
        
        NSMutableArray *devicesNotExist = [[NSMutableArray alloc] init];
        VMSDatabase *db = [VMSDatabase sharedVMSDatabase];

        for (CDevice *device in devices) {
            if (![db fetchDeviceWithEntity:@"mac_address" value:device.macAddress]) {
                [devicesNotExist addObject:device];
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSPredicate *filter = [NSPredicate predicateWithBlock:^BOOL(id  _Nonnull evaluatedObject,NSDictionary<NSString *,id> * _Nullable bindings) {
                CDevice *dev = (CDevice *)evaluatedObject;
                BOOL pass = YES;
                
                switch (self.filterBT.indexOfSelectedItem) {
                    case 1:
                        pass = (dev.type == IPC);
                        break;
                    case 2:
                        pass = (dev.type == NVR);
                        break;
                    case 0:
                    default:
                        break;
                }
                
                return pass;
            }];
            
            [devicesNotExist filterUsingPredicate:filter];
            
            [self setDiscoveries:devicesNotExist];
            [self.discoveryList reloadData];
            [self.discoverBT setEnabled:YES];
            [self.discoveryCountTF setStringValue:[NSString stringWithFormat:@"%ld %@",
                                                   self.discoveries.count,
                                                   NSLocalizedString(@"devices found", nil)]];
        });
    }];
}

#pragma mark - private method
- (ADSC_ERR)parser :(CDevice *)device
{
    if ([device.name isEqualToString:@""])
        return ADSC_EMPTY_NAME;
    if ([device.userName isEqualToString:@""])
        return ADSC_EMPTY_USER_NAME;
    
    if (self.enableP2pConnection) {
        if ([device.serialNumber isEqualToString:@""])
            return ADSC_EMPTY_UID;
    } else {
        if ([device.ip isEqualToString:@""])
            return ADSC_EMPTY_IP;
        
        if ([device.macAddress isEqualToString:@""])
            return ADSC_EMPTY_MAC_ADDR;
        
        if (device.port == 0)
            return ADSC_EMPTY_PORT;
    }
    
    return ADSC_NO_ERR;
}

- (NSString *)errMsg :(ADSC_ERR)errCode
{
    switch (errCode) {
        case ADSC_EMPTY_NAME:
            return NSLocalizedString(@"the device name is empty", nil);
        case ADSC_EMPTY_IP:
            return NSLocalizedString(@"ip address is empty", nil);
        case ADSC_EMPTY_PORT:
            return NSLocalizedString(@"invalid port", nil);
        case ADSC_EMPTY_USER_NAME:
            return NSLocalizedString(@"the user id is empty", nil);
        case ADSC_EMPTU_PASSWORD:
            return NSLocalizedString(@"the password is empty", nil);
        case ADSC_EMPTY_UID:
            return NSLocalizedString(@"the uid is empty", nil);
        case ADSC_NO_ERR:
            return NSLocalizedString(@"no error", nil);
        case ADSC_EMPTY_MAC_ADDR:
            return NSLocalizedString(@"the mac address is empty", nil);
        case ADSC_LOGIN_FAILED:
            return NSLocalizedString(@"login failed", nil);
        case ADSC_ADD_DEVICE_FAIL:
            return NSLocalizedString(@"failed to add device", nil);
        case ADSC_MODIFY_LOGIN_INFO_FAILED:
            return NSLocalizedString(@"failed to modify login password", nil);
        default:
            return NSLocalizedString(@"unknow error", nil);
    }
}



- (void)errorRaised :(int)dId
{
}

+ (BOOL)insertDevice :(CDevice *)device
{
    if (device) {
        VMSDatabase *db = [VMSDatabase sharedVMSDatabase];
        int         dId = -1;
        int         exist = [db fetchEntityCount:@"t_channel"];
        
        if (exist < 0 || device.channelCount <= 0) {
            return NO;
        }
        
        int freeChannelCnt = MAX_CHANNEL_CNT - exist;
        
        if (freeChannelCnt > 0) {
            if (device.channelCount > freeChannelCnt) {
                device.channelCount = freeChannelCnt;
            }
            
            dId = [db insertDevice:device];
            
            if (dId >= 0) {
                device.uniqueId = dId;
                
                //在该设备下，插入通道
                BOOL error = NO;
                for (int ch = 0; ch < device.channelCount; ch++) {
                    NSString *chName = (device.type == IPC)? device.name : [NSString stringWithFormat:@"%@_CH%d",device.name,(ch + 1)];
                    Channel *chn = [[Channel alloc] initWithUniqueId:-1
                                                                name:chName
                                                                type:0
                                                             logicId:ch
                                                             unused1:0
                                                             unused2:0
                                                                mapX:@""
                                                                mapY:@""
                                                       patrolGroupId:-1
                                                             CDevice:device];
                    int cId = [db insertChannel:chn];
                    
                    if (cId >= 0) {
                        chn.uniqueId = cId;
                        //在该通道下插入录像信息
                        for (int weekday = 0; weekday < 7; weekday++) {
                            long long data = 0x0000000000000000;
                            for (int halfHour = 0; halfHour < 48; halfHour++) {
                                long long bit = 0x0000000000000001;
                                data |= bit << halfHour;
                            }
                            
                            int recId = [db insertScheduledTaskWithChannelId:cId
                                                                        data:data
                                                                     weekday:weekday
                                                                  withEntity:@"t_rec_plan"];
                            
                            int alarmId = [db insertScheduledTaskWithChannelId:cId
                                                                          data:0x0000000000000000
                                                                       weekday:weekday
                                                                    withEntity:@"t_alarm_plan"];
                            
                            if (recId < 0 || alarmId < 0) {
                                error = YES;
                                break;
                            }
                        }
                        
                        if (error) {
                            break;
                        }
                        else {
                            //在该通道下插入报警联动
                            int alarmLinkId = [db insertAlarmLinkage:[[AlarmLink alloc] initWithUniqueId:-1
                                                                                               alarmType:0
                                                                                                 linkage:0
                                                                                               channelId:cId]];
                            if (alarmLinkId < 0) {
                                error = YES;
                                break;
                            }
                        }
                    }
                    else {
                        break;
                    }
                }
                
                return !error;
            }
        }
    }
    
    return NO;
}

- (CDevice *)addDevice :(CDevice *)device
{
    @try {
        VMSDatabase *db = [VMSDatabase sharedVMSDatabase];
        if (device) {
            //查询相同mac地址或者uid的设备
            if (self.enableP2pConnection? ![db fetchDeviceWithEntity:@"serial_number" value:device.serialNumber] : ![db fetchDeviceWithEntity:@"mac_address" value:device.macAddress]) {
                //插入设备
                if ([AddDeviceSheetController insertDevice:device]) {
                    return device;
                }
                else {
                    [db deleteDevice:device];
                }
            }
        }
    }
    @catch (NSException *exception) {
        NSLog(@"添加设备发生异常%@",exception);
    }

    return nil;
}

- (void)centerWindow :(NSWindow *)w1 fromWindow :(NSWindow *)w2
{
    NSPoint origin = w2.frame.origin;
    
    origin.x += (w2.frame.size.width - w1.frame.size.width) / 2.0;
    origin.y += (w2.frame.size.height - w1.frame.size.height) / 2.0;
    
    [w1 setFrameOrigin:origin];
}

//手动添加
- (CDevice *)manualAdd
{
    ADSC_ERR code = ADSC_NO_ERR;
    
    //开始手动添加
    int dev_type = (int)self.deviceTypeBtn.indexOfSelectedItem;
    
    NSString *name = self.deviceNameTF.stringValue;
    NSString *tag = self.enableP2pConnection? self.uidTF.stringValue : self.macAddressTF.stringValue;
    
    name = [NSString stringWithFormat:@"%@(%@)",name,tag];
    
    
    CDevice *device = [[CDevice alloc] initWithUniqueId:-1
                                                   name:name
                                                   type:dev_type
                                                     ip:self.ipAddressTF.stringValue
                                                   port:self.portTF.intValue
                                               userName:self.userNameTF.stringValue
                                                userPsw:self.userPSWTF.stringValue
                                               rtspPort:self.portTF.intValue
                                             macAddress:self.macAddressTF.stringValue
                                           serialNumber:self.enableP2pConnection? self.uidTF.stringValue : @""
                                           decorderType:0
                                           channelCount:1
                                                  Group:nil];
    //解析
    code = [self parser:device];
    if (code != ADSC_NO_ERR) {
        self.lastError = code;
        return nil;
    }
    
    //测试设备合法性(同步)
    int chnCnt = 0;
    int result = FOSCMDRET_FAILD;
    long userId = -1;
    
    if (userId = [DispatchCenter loginDeviceSync:device channelCnt:&chnCnt result:&result], userId >= 0) {
        //测试是否为首次登陆(user = "admin",pwd = "")
        BOOL cancel = NO;
        BOOL modify = NO;
        if ([device.userName isEqualToString:@"admin"] &&
            [device.userPsw  isEqualToString:@""]) {
            //跳转至密码修改页面
            //是否强制用户使用默认用户名
            self.modifyLoginInfoSheetController.useDefaultUser = (device.type == NVR);
            //设置窗口出现位置
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
                        device.userName = info.modifiedName;
                        device.userPsw = info.modifiedPwd;
                        modify = YES;
                    }
                    else {
                        cancel = YES;
                        self.lastError = ADSC_MODIFY_LOGIN_INFO_FAILED;
                    }
                }
                    break;
                default:
                    break;
            }
            
            [self.modifyLoginInfoSheetController close];
            [self setModifyLoginInfoSheetController:nil];
        }
        
        //登出
        [DispatchCenter logoutDeviceSync:device withUserId:userId];
        
        
        if (cancel) {
            return nil;
        }
        else {
            if (modify && device.type == NVR) {
                //重新登录，拿下通道数
                int result = FOSCMDRET_FAILD;
                long userId = [DispatchCenter loginDeviceSync:device channelCnt:&chnCnt result:&result];
                [DispatchCenter logoutDeviceSync:device withUserId:userId];
            }
            
            //添加
            device.channelCount = chnCnt;
            CDevice *newDevice = [self addDevice:device];
            self.lastError = newDevice? ADSC_NO_ERR : ADSC_ADD_DEVICE_FAIL;
            
            return newDevice;
        }
    }
    else {
        self.lastError = ADSC_LOGIN_FAILED;
        self.lastCode = result;
    }
    
    return nil;
}

- (NSString *)typeStringWithIntegerType :(DEVICE_TYPE)type
{
    NSString *typeString = @"";
    
    switch (type) {
        case IPC:
            typeString = @"IPC";
            break;
        case NVR:
            typeString = @"NVR";
            break;
        default:
            break;
    }
    
    return typeString;
}

#pragma mark - table view datasource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.discoveries.count;
}

- (id)tableView:(NSTableView *)tableView
objectValueForTableColumn:(NSTableColumn *)tableColumn
            row:(NSInteger)row
{
    NSString *identifier_column = tableColumn.identifier;
    NSArray *contents = self.discoveries;
    CDevice *device = [contents objectAtIndex:row];
    
    id result = nil;
    
    if ([identifier_column isEqualToString:ID_NAME]) {
//        NSNumber *state = [self.discoveriesState valueForKey:[NSString stringWithFormat:@"%ld",row]];
//        result = state? state : [NSNumber numberWithBool:NO];
        result = device.name;
    } else if ([identifier_column isEqualToString:ID_TYPE]) {
        result = [self typeStringWithIntegerType:(DEVICE_TYPE)device.type];
    } else if ([identifier_column isEqualToString:ID_IP]) {
        result = device.ip;
    } else if ([identifier_column isEqualToString:ID_PORT]) {
        result = [NSString stringWithFormat:@"%d",device.port];
    } else if ([identifier_column isEqualToString:ID_MAC]) {
        result = device.macAddress;
    }
    
    return result;
}

#pragma mark - table view delegate
- (BOOL)tableView:(NSTableView *)tableView
shouldEditTableColumn:(NSTableColumn *)tableColumn
              row:(NSInteger)row
{
    return NO;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    //When user selected one row,we should respond to this event.
    NSTableView *tableview = notification.object;
    NSInteger row = [tableview selectedRow];
    
    
    if (row < self.discoveries.count ) {
        //将选中的设备信息显示到输入框中
        CDevice *device = [self.discoveries objectAtIndex:row];
        self.deviceNameTF.stringValue = device.name;
        self.ipAddressTF.stringValue = device.ip;
        self.portTF.integerValue = device.port;
        self.macAddressTF.stringValue = device.macAddress;
        self.userNameTF.stringValue = device.userName;
        self.userPSWTF.stringValue = device.userPsw;
        self.uidTF.stringValue = device.serialNumber;
        
        [self.deviceTypeBtn selectItemAtIndex:device.type];
    }
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectTableColumn:(NSTableColumn *)tableColumn
{
    ///Select a column is prohibited
    return NO;
}


#pragma mark - setter && getter
//- (void)setDeviceTypeCB:(NSComboBox *)deviceTypeCB
//{
//    _deviceTypeCB = deviceTypeCB;
//    [self.deviceTypeCB selectItemAtIndex:0];
//}

- (ModifyLoginInfoSheetController *)modifyLoginInfoSheetController
{
    if (!_modifyLoginInfoSheetController) {
        _modifyLoginInfoSheetController = [[ModifyLoginInfoSheetController alloc] initWithWindowNibName:@"ModifyLoginInfoSheetController"];
    }
    
    return _modifyLoginInfoSheetController;
}

@end
