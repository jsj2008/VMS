//
//  IPCManageViewController.m
//  
//
//  Created by mac_dev on 16/6/2.
//
//

#import "IPCManageViewController.h"
#import "ChannelInfoCellView.h"
//#import <sys/socket.h>
#import <arpa/inet.h>

#define COL_IPC         @"ipc"
#define COL_NAME        @"name"
#define COL_INFO        @"info"
#define NAME_CELL_VIEW  @"name cell view"
#define INFO_CELL_VIEW  @"info cell view"
#define INFO_CELL_VIEW_EXPAND_HEIGHT    254
#define INFO_CELL_VIEW_COLLAPSE_HEIGHT  31
#define TV_IPC_LIST     @"ipc list"
#define TV_CHANNEL_INFO @"channel info"

@interface IPCManageViewController () {
    FOSNVR_IpcNode *_ipcNode;
    int _size;
}

@property (nonatomic,weak) IBOutlet NSTableView *ipcTV;
@property (nonatomic,weak) IBOutlet NSTableView *chnInfoTV;
@property (nonatomic,strong) NSIndexSet *expandedRowIndexs;
@property (nonatomic,assign) NSInteger selectedRow;

@end

@implementation IPCManageViewController

#pragma mark - public api

- (void)fetch
{
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int isEnabledAdd = 0;
        FOS_NVR_IPC_LIST nvrIPCList;
        memset(&nvrIPCList, 0, sizeof(FOS_NVR_IPC_LIST));
        FOSCAM_NVR_CONFIG nvrCfg;
        BOOL success = YES;
        
        if (self.device.channelCount <= MAX_CHANNEL_COUNT) {
            nvrIPCList.cnt = self.device.channelCount;
            
            //获取各通道信息
            for (int ch = 0; ch < self.device.channelCount; ch++) {
                char xml[OUT_BUFFER_LENGTH] = {0};
                nvrCfg.input = &ch;
                nvrCfg.output = xml;
                nvrCfg.outputLen = OUT_BUFFER_LENGTH;
                
                if ([[DispatchCenter sharedDispatchCenter] getConfig:&nvrCfg
                                                             forType:FOSCAM_NVR_CONFIG_IPC_LIST
                                                          fromDevice:self.device]) {
                    //解析结果
                    NSError *err = nil;
                    NSString *rawString = [NSString stringWithCString:xml encoding:NSASCIIStringEncoding];
                    NSDictionary *dict = [XMLHelper parserCGIXml:rawString error:&err];
                    
                    if (DEBUG_CGI) {
                        NSLog(@"%@",rawString);
                    }
                    
                    BOOL result = NO;
                    if (!err) {
                        if ([[dict valueForKey:@"result"] intValue] == 0) {
                            FOS_CHANNEL_INFO *chnInfo = nvrIPCList.chnInfo + ch;
                            
                            chnInfo->ch = [[dict valueForKey:@"chnnl"] intValue];
                            chnInfo->isEnable = [[dict valueForKey:@"isEnable"] intValue];
                            chnInfo->status = [[dict valueForKey:@"status"] intValue];
                            chnInfo->protocol = [[dict valueForKey:@"ptcls"] intValue];
                            chnInfo->webPort = [[dict valueForKey:@"httpPort"] intValue];
                            chnInfo->mediaPort = [[dict valueForKey:@"mediaPort"] intValue];
                            [[dict valueForKey:@"ipAddr"] getCString:chnInfo->url maxLength:128 encoding:NSASCIIStringEncoding];
                            [[dict valueForKey:@"devMac"] getCString:chnInfo->devMac maxLength:16 encoding:NSASCIIStringEncoding];
                            [[dict valueForKey:@"devName"] getCString:chnInfo->devName maxLength:64 encoding:NSASCIIStringEncoding];
                            [[dict valueForKey:@"userName"] getCString:chnInfo->username maxLength:128 encoding:NSASCIIStringEncoding];
                            
                            memset(chnInfo->chnName, 128, 0);
                            
                            if (chnInfo->isEnable == 0) {
                                chnInfo->protocol = -1;
                                chnInfo->webPort = 0;
                                
                                memset(chnInfo->devName, 0, 64);
                                memset(chnInfo->url, 0, 128);
                                memset(chnInfo->password, 0, 128);
                                memset(chnInfo->username,0,128);
                                memset(chnInfo->devMac, 0, 16);
                            } else {
                                sprintf(chnInfo->chnName, "%s(%s)",chnInfo->devName,chnInfo->url);
                            }
                            
                            //pwd
                            result = YES;
                        }
                    }
                    
                    if (!result) {
                        success = NO;
                        break;
                    }
                }
            }
            
            //获取自动添加设备
            
            char xml[OUT_BUFFER_LENGTH] = {0};
            nvrCfg.output = xml;
            
            if ([[DispatchCenter sharedDispatchCenter] getConfig:&nvrCfg
                                                         forType:FOSCAM_NVR_CONFIG_AUTO_ADD_IPC
                                                      fromDevice:self.device]) {
                NSError *err = nil;
                NSString *rawString = [NSString stringWithCString:xml encoding:NSASCIIStringEncoding];
                NSDictionary *dict = [XMLHelper parserCGIXml:rawString error:&err];
                
                if (DEBUG_CGI) {
                    NSLog(@"%@",rawString);
                }
                
                if (!err && dict) {
                    NSNumber *result = [dict valueForKey:KEY_XML_RESULT];
                    
                    if (result && result.intValue == 0) {
                        isEnabledAdd = [[dict valueForKey:@"isEnabledAdd"] intValue];
                    }
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [self setNvrIPCList:nvrIPCList];
                [self setAutoAddIPC:(isEnabledAdd == 1)];
            } else
                [self alert:NSLocalizedString(@"failed to get the settings", nil)
                       info:NSLocalizedString(@"time out", nil)];
            [self setActivity:NO];
        });
    });
}

- (void)push
{}

- (NSString *)description
{
    return NSLocalizedString(@"IP Camera Setup", nil);
}

- (SVC_OPTION)option
{
    return SVC_REFRESH;
}
#pragma mark - action
- (IBAction)switchAutoAdd:(id)sender
{
    [self setActivity:YES];
    __block int isAutoAdd = ([(NSButton *)sender state] == NSOnState);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        char xml[OUT_BUFFER_LENGTH] = {0};
        FOSCAM_NVR_CONFIG nvrCfg;
        BOOL success = NO;
        
        nvrCfg.input = &isAutoAdd;
        nvrCfg.output = xml;
        nvrCfg.outputLen = OUT_BUFFER_LENGTH;
        
        if ([[DispatchCenter sharedDispatchCenter] setConfig:&nvrCfg
                                                     forType:FOSCAM_NVR_CONFIG_AUTO_ADD_IPC
                                                    toDevice:self.device]) {
            NSError *err = nil;
            NSString *rawString = [NSString stringWithCString:xml encoding:NSASCIIStringEncoding];
            NSDictionary *dict = [XMLHelper parserCGIXml:rawString error:&err];
            
            NSLog(@"%@",rawString);
            
            if (!err && dict) {
                NSNumber *result = [dict valueForKey:KEY_XML_RESULT];
                
                if (result && result.intValue == 0) {
                    success = YES;
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self fetch];
            [self setActivity:NO];
        });
    });
}

- (IBAction)add:(id)sender
{
    NSInteger chn = self.chnInfoTV.selectedRow;
    NSTableCellView *cellView = [self.chnInfoTV viewAtColumn:1 row:chn makeIfNecessary:NO];
    
    if ([cellView isKindOfClass:[ChannelInfoCellView class]]) {
        __block FOS_CHANNEL_INFO chnInfo = [(ChannelInfoCellView *)cellView chnInfoFromUI];
        CH_INFO_ERR err = [self parserChannelInfo:chnInfo];
        if (err != CH_INFO_NO_ERR) {
            [self alert:NSLocalizedString(@"failed to add", nil)
                   info:[NSString stringWithFormat:@"%@",[self errMsg:err]]];
            return;
        }
        
        [self setActivity:YES];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            FOSCAM_NVR_CONFIG config;
            char xml[OUT_BUFFER_LENGTH] = {0};
            
            config.input = &chnInfo;
            config.output = xml;
            config.outputLen = OUT_BUFFER_LENGTH;
            
            BOOL success = NO;
            if([[DispatchCenter sharedDispatchCenter] setConfig:&config
                                                        forType:FOSCAM_NVR_CONFIG_ADD_IPC_LIST
                                                       toDevice:self.device]) {
                //解析结果
                NSError *err = nil;
                NSString *rawString = [NSString stringWithCString:xml encoding:NSASCIIStringEncoding];
                NSLog(@"%@",rawString);
                NSDictionary *values = [XMLHelper parserCGIXml:rawString error:&err];
                
                if (!err) {
                    NSNumber *result = [values valueForKey:KEY_XML_RESULT];
                    success = result && (result.intValue == 0);
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!success) {
                    [self alert:NSLocalizedString(@"failed to add", nil) info:@""];
                }
                [self setActivity:NO];
                [self fetch];
            });
        });
    }
}
- (IBAction)remove :(id)sender
{
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSInteger chn = self.chnInfoTV.selectedRow;
        FOSCAM_NVR_CONFIG config;
        char xml[OUT_BUFFER_LENGTH] = {0};
        
        config.input = &chn;
        config.output = xml;
        config.outputLen = OUT_BUFFER_LENGTH;
        
        BOOL success = NO;
        if([[DispatchCenter sharedDispatchCenter] setConfig:&config
                                                    forType:FOSCAM_NVR_CONFIG_DEL_IPC_LIST
                                                   toDevice:self.device]) {
            //解析结果
            NSError *err = nil;
            NSString *rawString = [NSString stringWithCString:xml encoding:NSASCIIStringEncoding];
            NSLog(@"%@",rawString);
            NSDictionary *values = [XMLHelper parserCGIXml:rawString error:&err];
            
            if (!err) {
                NSNumber *result = [values valueForKey:KEY_XML_RESULT];
                success = result && (result.intValue == 0);
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!success) {
                [self alert:NSLocalizedString(@"failed to remove", nil) info:@""];
            }
            [self setActivity:NO];
            [self fetch];
        });
    });
}

- (IBAction)discovery:(id)sender
{
    int size = 128;
    FOSNVR_IpcNode *ipcNode = malloc(sizeof(FOSNVR_IpcNode) * size);
    
    if ([[DispatchCenter sharedDispatchCenter] getIpcList:ipcNode size:&size fromNvr:self.device]) {
        [self setIpcList:ipcNode size:size];
    }
    else {
        free(ipcNode);
        [self setIpcList:NULL size:0];
    }
}

#pragma mark - life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self discovery:nil];
}

- (void)dealloc
{
    [self setIpcList:NULL size:0];
}

#pragma mark - table view datasouce
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    NSString *identifier = tableView.identifier;
    
    if ([identifier isEqualToString:TV_IPC_LIST])
        return _size;
    else if ([identifier isEqualToString:TV_CHANNEL_INFO])
        return self.nvrIPCList.cnt;
    
    return 0;
}


#pragma mark - convert ip from int to string
void inttoip(int ip_num, char *ip )
{
    struct in_addr tmp;
    tmp.s_addr = ip_num;
    strcpy( ip, (char*)inet_ntoa(tmp));
}

#pragma mark - table view delegate
- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row
{
    NSString *identifier = [tableColumn identifier];
    NSTableCellView *cellView = nil;
    
    if ([identifier isEqualToString:COL_NAME]) {
        cellView = [tableView makeViewWithIdentifier:NAME_CELL_VIEW owner:nil];
        cellView.textField.stringValue = [NSString stringWithFormat:@"%@%ld",NSLocalizedString(@"Channel", nil),row + 1];
    } else if ([identifier isEqualToString:COL_INFO]) {
        cellView = [tableView makeViewWithIdentifier:INFO_CELL_VIEW owner:self];
        ((ChannelInfoCellView *)cellView).chnInfo = self.nvrIPCList.chnInfo[row];
    } else if ([identifier isEqualToString:COL_IPC]) {
        FOSNVR_IpcNode *node =  _ipcNode + row;
        char ip[32] = {0};
        inttoip(node->ip, ip);

        cellView = [tableView makeViewWithIdentifier:NAME_CELL_VIEW owner:nil];
        cellView.textField.stringValue = [NSString stringWithFormat:@"%s(%s)",node->ipCamName,ip];
    }
    
    return cellView;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    NSString *identifier = tableView.identifier;
    
    if ([identifier isEqualToString:TV_CHANNEL_INFO])
        return row == tableView.selectedRow? INFO_CELL_VIEW_EXPAND_HEIGHT : INFO_CELL_VIEW_COLLAPSE_HEIGHT;
    
    return tableView.rowHeight;
}

/*
 *recieve tableview selection did changed notification
 *
 */
#pragma mark tableview extended delegate
- (void)tableView:(NSTableView *)tableView didClickedRow:(NSInteger)row
{
    NSString *identifier = tableView.identifier;
    
    if ([identifier isEqualToString:TV_IPC_LIST]) {
        //查看正在选中的 通道信息
        NSInteger selectedChnInfoRow = self.chnInfoTV.selectedRow;
        if (selectedChnInfoRow >= 0 && selectedChnInfoRow < self.device.channelCount) {
            //获取选中的ipc
            NSInteger selectedIPCRow = self.ipcTV.selectedRow;
            if (selectedIPCRow >= 0 && selectedIPCRow < _size) {
                FOS_CHANNEL_INFO    *chnInfo = _nvrIPCList.chnInfo + selectedChnInfoRow;
                FOSNVR_IpcNode      *ipcNode = _ipcNode + selectedIPCRow;
                
                strcpy(chnInfo->devName, ipcNode->ipCamName);
                strcpy(chnInfo->xAddr, ipcNode->xAddr);
                strcpy(chnInfo->devMac,ipcNode->ipCamID);
                strcpy(chnInfo->username, "admin");
                strcpy(chnInfo->password, "");
                inttoip(ipcNode->ip, chnInfo->url);
                
                chnInfo->webPort = ipcNode->port;
                chnInfo->mediaPort = ipcNode->mediaPort;
                chnInfo->protocol = ipcNode->protocol;
                chnInfo->productType = ipcNode->deviceType;
                chnInfo->status = 1;
                
                
                [self.chnInfoTV reloadDataForRowIndexes:self.expandedRowIndexs
                                          columnIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)]];
            }
        }
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    NSTableView *tableView = notification.object;
    NSString    *identifier = tableView.identifier;
    
    if ([identifier isEqualToString:TV_CHANNEL_INFO]) {
        NSIndexSet  *selectedRowIndexs = [tableView selectedRowIndexes];
        NSIndexSet  *expandedRowIndexs = self.expandedRowIndexs;
        
        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setDuration:0.3];
        [tableView noteHeightOfRowsWithIndexesChanged:expandedRowIndexs];
        [tableView noteHeightOfRowsWithIndexesChanged:selectedRowIndexs];
        [NSAnimationContext endGrouping];
        
        self.expandedRowIndexs = selectedRowIndexs;
    }
}



#pragma mark - private api
- (CH_INFO_ERR)parserChannelInfo :(FOS_CHANNEL_INFO)chnInfo
{
    CH_INFO_ERR err = CH_INFO_NO_ERR;
    
    if (0 == strcmp(chnInfo.devName, ""))
        err = CH_INFO_EMPTY_DEVICE_NAME;
    else if (0 == strcmp(chnInfo.url, ""))
        err = CH_INFO_EMPTY_URL;
    else if (chnInfo.webPort > 65535)
        err = CH_INFO_EMPTY_PORT;
    else if (0 == strcmp(chnInfo.username, ""))
        err = CH_INFO_EMPTY_USERNAME;
    
    return err;
}


- (NSString *)errMsg :(CH_INFO_ERR)code
{
    switch (code) {
        case CH_INFO_NO_ERR:
            return nil;
        case CH_INFO_EMPTY_DEVICE_NAME:
            return NSLocalizedString(@"the device name is empty", nil);
        case CH_INFO_EMPTY_URL:
            return NSLocalizedString(@"ip address is empty", nil);
        case CH_INFO_EMPTY_PORT:
            return NSLocalizedString(@"invalid port", nil);
        case CH_INFO_EMPTY_USERNAME:
            return NSLocalizedString(@"username is empty", nil);
        default:
            return NSLocalizedString(@"unknow error", nil);
    }
}

#pragma mark - update ui
- (void)updateIPCListUI
{
    [self.chnInfoTV reloadData];
    [self.chnInfoTV setNeedsDisplay:YES];
}

#pragma mark - setter & getter
- (void)setNvrIPCList:(FOS_NVR_IPC_LIST)nvrIPCList
{
    _nvrIPCList = nvrIPCList;
    [self updateIPCListUI];
}

- (void)setIpcList :(FOSNVR_IpcNode *)node size :(int)size
{
    if (node != _ipcNode) {
        //是否需要释放旧的内存
        if (_ipcNode != NULL && size > 0) {
            free(_ipcNode);
        }
        
        _ipcNode = node;
        _size = size;
        [self.ipcTV reloadData];
    }
}

@end
