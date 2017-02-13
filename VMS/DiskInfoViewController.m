//
//  DiskInfoViewController.m
//  
//
//  Created by mac_dev on 16/6/7.
//
//

#import "DiskInfoViewController.h"

#define COL_NUM                 @"num"
#define COL_TYPE                @"type"
#define COL_STATUS              @"status"
#define COL_FREE                @"free"
#define COL_TOTAL               @"total"


@interface DiskInfoViewController ()

@property (nonatomic,weak) IBOutlet NSTableView *diskInfoTV;
@property (nonatomic,weak) IBOutlet NSPopUpButton *diskRewriteBtn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *previewTimeBtn;
@property (nonatomic,weak) IBOutlet NSButton *formatBtn;

@end

@implementation DiskInfoViewController

#pragma mark - public api
- (void)fetch
{
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FOSCAM_NVR_CONFIG config;
        char xml[OUT_BUFFER_LENGTH] = {0};
    
        config.output = xml;
        config.outputLen = OUT_BUFFER_LENGTH;
        
        BOOL success = NO;
        FOS_NVR_DISK_INFO  diskInfo;
        if ([[DispatchCenter sharedDispatchCenter] getConfig:&config
                                                     forType:FOSCAM_NVR_CONFIG_DISK_INFO
                                                  fromDevice:self.device]) {
            //解析结果
            NSError *err = nil;
            NSString *rawString = [NSString stringWithCString:xml encoding:NSASCIIStringEncoding];
            NSDictionary *dict = [XMLHelper parserCGIXml:rawString error:&err];
            
            if (DEBUG_CGI) {
                NSLog(@"%@",rawString);
            }
            
            if (!err) {
                NSString *result = [dict valueForKey:@"result"];
                if ([result isEqualToString:@"0"]) {
                    success = YES;
                    diskInfo.diskConfig.diskRewrite = [[dict valueForKey:@"diskRewrite"] intValue];
                    diskInfo.diskConfig.previewTime = [[dict valueForKey:@"previewTime"] intValue];
                    diskInfo.diskCnt = 0;
                    for (int i = 0; i < MAX_DISK_COUNT; i++) {
                        int disk = i + 1;
                        int enable = [[dict valueForKey:[NSString stringWithFormat:@"d%dStatus",disk]] intValue];
                        if (enable) {
                            diskInfo.diskCnt++;
                            diskInfo.status[i] = 1;
                            diskInfo.type[i] = [[dict valueForKey:[NSString stringWithFormat:@"d%dType",disk]] intValue];
                            diskInfo.freeSpace[i] = [[dict valueForKey:[NSString stringWithFormat:@"d%dFreeSpace",disk]] intValue];
                            diskInfo.totolSpace[i] = [[dict valueForKey:[NSString stringWithFormat:@"d%dTotalSpace",disk]] intValue];
                            diskInfo.canFormat[i] = [[dict valueForKey:[NSString stringWithFormat:@"d%dCanFormat",disk]] intValue];
                            diskInfo.isBusy[i] = [[dict valueForKey:[NSString stringWithFormat:@"d%dBusy",disk]] intValue];
                        } else
                            break;
                    }
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success)
                [self setDiskInfo:diskInfo];
            else
                [self alert:NSLocalizedString(@"failed to get the settings", nil)
                       info:NSLocalizedString(@"time out", nil)];
            [self setActivity:NO];
        });
    });
}

- (void)push
{
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //收集控件信息
        FOS_NVR_DISK_CONFIG diskCfg = [self diskConfigFromUI];
        FOSCAM_NVR_CONFIG config;
        char xml[OUT_BUFFER_LENGTH] = {0};
        
        config.input = &diskCfg;
        config.output = xml;
        config.outputLen = OUT_BUFFER_LENGTH;
        
        BOOL success = NO;
        if ([[DispatchCenter sharedDispatchCenter] setConfig:&config
                                                     forType:FOSCAM_NVR_CONFIG_DISK_INFO
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
            if (!success)
                [self alert:NSLocalizedString(@"failed to set the settings", nil)
                       info:NSLocalizedString(@"time out", nil)];
            [self setActivity:NO];
        });
    });
}

- (NSString *)description
{
    return NSLocalizedString(@"Hard Disk Information", nil);
}

- (SVC_OPTION)option
{
    return SVC_REFRESH | SVC_SAVE;
}

- (FOS_NVR_DISK_CONFIG)diskConfigFromUI
{
    FOS_NVR_DISK_CONFIG cfg;
    
    cfg.diskRewrite = (int)self.diskRewriteBtn.indexOfSelectedItem;
    cfg.previewTime = (int)self.previewTimeBtn.indexOfSelectedItem;
    
    return cfg;
}

#pragma mark - private api
- (void)updateDiskInfoUI
{
    [self.diskInfoTV reloadData];
    [self.diskRewriteBtn selectItemAtIndex:self.diskInfo.diskConfig.diskRewrite];
    [self.previewTimeBtn selectItemAtIndex:self.diskInfo.diskConfig.previewTime];
}
#pragma mark - action
- (IBAction)formatDisk:(id)sender
{
    __block NSInteger selectedDisk = self.diskInfoTV.selectedRow;
    if (selectedDisk == -1) {
        [self alert:NSLocalizedString(@"failed to format the disk", nil)
               info:NSLocalizedString(@"please select a disk", nil)];
        return;
    }
    
   
    //提示用户确认
    NSAlert *alert = [[NSAlert alloc] init];
    
    alert.messageText = NSLocalizedString(@"are you sure to format the disk?", nil);
    alert.informativeText = NSLocalizedString(@"you will irretrievably lose all of the files in your disk if you format it!", nil);
    alert.alertStyle = NSAlertStyleWarning;
    
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel",nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
    
    
    if (NSAlertSecondButtonReturn == [alert runModal]){
        
        [self setActivity:YES];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            //收集控件信息
            FOSCAM_NVR_CONFIG config;
            FOS_NVR_DISK_FORMAT_CONFIG nvrDiskFormatCfg;
            char xml[OUT_BUFFER_LENGTH] = {0};
            
            nvrDiskFormatCfg.diskNum = (int)selectedDisk;
            nvrDiskFormatCfg.type = 0;//这里默认使用0,格式化为录像盘
            config.input = &nvrDiskFormatCfg;
            config.output = xml;
            config.outputLen = OUT_BUFFER_LENGTH;
            
            BOOL success = NO;
            if ([[DispatchCenter sharedDispatchCenter] setConfig:&config
                                                         forType:FOSCAM_NVR_CONFIG_DISK_FORMAT
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
                if (!success)
                    [self alert:NSLocalizedString(@"failed to format the disk", nil)
                           info:NSLocalizedString(@"time out", nil)];
                
                [self setActivity:NO];
            });
        });
    }
}

#pragma mark - tableview datasource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.diskInfo.diskCnt;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSString *identifier = [tableColumn identifier];
    NSArray *cols = @[COL_NUM,COL_TYPE,COL_STATUS,COL_FREE,COL_TOTAL];
    
    switch ([cols indexOfObject:identifier]) {
        case 0:
            return [NSNumber numberWithInteger:row];
        case 1:
            return [self diskType:self.diskInfo.type[row]];
        case 2: {
            if (self.diskInfo.isBusy[row] == 1) {
                return NSLocalizedString(@"Recording", nil);
            }
            
            return [self diskStatus:self.diskInfo.status[row]];
        }
        case 3:
            return [NSString stringWithFormat:@"%d",self.diskInfo.freeSpace[row]];
        case 4:
            return [NSString stringWithFormat:@"%d",self.diskInfo.totolSpace[row]];
        default:
            return nil;
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    NSTableView *tv = notification.object;
    NSInteger selectedDisk = tv.selectedRow;
    //是否可以格式化
    self.formatBtn.enabled = self.diskInfo.canFormat[selectedDisk];
}

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return NO;
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectTableColumn:(NSTableColumn *)tableColumn
{
    return NO;
}
#pragma mark - data
- (NSArray *)diskFullOptions
{
    return @[NSLocalizedString(@"Stop Recording", nil),
             NSLocalizedString(@"Cover The Earliest Record", nil)];
}

- (NSArray *)preRecordTimes
{
    return @[NSLocalizedString(@"off", nil),@"1s",@"2s",@"3s",@"4s",@"5s"];
}

- (NSString *)diskStatus :(int)status
{
    switch (status) {
        case 0:
            return NSLocalizedString(@"Unformatted", nil);
        case 1:
            return NSLocalizedString(@"Video Disk", nil);
        case 2:
            return NSLocalizedString(@"Backup Disk", nil);
            
        default:
            return nil;
    }
}

- (NSString *)diskType :(int)type
{
    switch (type) {
        case 0:
            return NSLocalizedString(@"SATA Hard Drive", nil);
        case 1:
            return NSLocalizedString(@"ESATA Hard Drive", nil);
        case 2:
            return NSLocalizedString(@"USB Drive", nil);
            
        default:
            return nil;
    }
}
#pragma mark - setter & getter
- (void)setPreviewTimeBtn:(NSPopUpButton *)previewTimeBtn
{
    _previewTimeBtn = previewTimeBtn;
    [self setControl:_previewTimeBtn withTitles:[self preRecordTimes]];
}

- (void)setDiskRewriteBtn:(NSPopUpButton *)diskRewriteBtn
{
    _diskRewriteBtn = diskRewriteBtn;
    [self setControl:_diskRewriteBtn withTitles:[self diskFullOptions]];
}

- (void)setDiskInfo:(FOS_NVR_DISK_INFO)diskInfo
{
    _diskInfo = diskInfo;
    [self updateDiskInfoUI];
}
@end
