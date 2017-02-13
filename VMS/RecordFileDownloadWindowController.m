//
//  RecordFileDownloadWindowController.m
//  
//
//  Created by mac_dev on 16/6/22.
//
//

#import "RecordFileDownloadWindowController.h"



#define DOWNLOAD_MVC_DEBUG  1
#define ROWS_PER_PAGE       20

@interface RecordFileDownloadWindowController ()

@property(nonatomic,assign) NSUInteger curPage;
@property(nonatomic,assign) NSUInteger pageCnt;
@property(nonatomic,strong) NSMutableArray *curPageFileInfos;
@property(nonatomic,weak) IBOutlet NSTableView *tableView;
@property(nonatomic,weak) IBOutlet NSTextField *pageCntTF;
@property(nonatomic,weak) IBOutlet NSTextField *curPageTF;
@property(nonatomic,weak) IBOutlet NSButton *downloadBtn;
@property(nonatomic,weak) IBOutlet NSTextField *destPathTF;
@property(nonatomic,assign,getter=isDownload) BOOL download;
@property(nonatomic,strong) NSString *destPath;
@property(nonatomic,strong) NSCondition *downloadCond;
@property(nonatomic,assign) Download_Event downloadEvent;
@property(nonatomic,assign) BOOL trigged;
@property(nonatomic,strong) NSMutableDictionary *curDownloadFile;//当前的下载文件
@end

@implementation RecordFileDownloadWindowController

#pragma mark - notification
- (void)handleDispatchCenterNotification :(NSNotification *)aNotific
{
    if ([aNotific.name isEqualToString:RECORD_FILE_DOWNLOAD_PROGRESS_NOTIFICATION]) {
        //do something
        float progress = [[aNotific.userInfo valueForKey:KEY_PROGRESS] intValue];
        [self.downloadCond lock];
        
        //根据当前的进度更新tableview
        NSString *val = nil;
        if (progress < 0 || progress >100) {
            val = NSLocalizedString(@"Failed", nil);
            self.downloadEvent = Download_Event_EXP;
            self.trigged = YES;
            [self.downloadCond signal];
        } else if (progress == 100) {
            val = NSLocalizedString(@"Done", nil);
            self.downloadEvent = Download_Event_Complete;
            self.trigged = YES;
            [self.downloadCond signal];
        } else {
            val = [NSString stringWithFormat:@"%d%%",(int)progress];
        }
        
        [self updateDownloadProgress:val forDict:self.curDownloadFile];
        [self.downloadCond unlock];
        
#if 0
        NSLog(@"progress=%f",progress);
#endif
    }
}

#pragma mark - download thread
- (void)downloadRoutine :(NSArray *)files
{
    DispatchCenter *center = [DispatchCenter sharedDispatchCenter];
    BOOL cancel = NO;
    BOOL stop = NO;
    self.trigged = NO;
    
    for (int i = 0; !stop && (i < files.count); i++) {
        NSMutableDictionary *file = files[i];
        self.curDownloadFile = file;
        
        if (cancel) {
            [self updateDownloadProgress:NSLocalizedString(@"Cancel", nil) forDict:file];
        } else {
            CDevice *dev = [file valueForKey:KEY_DEV];
            NSValue *nodeVal = [file valueForKey:KEY_NODE];
            int tickets = 5;
            BOOL getTicket = NO;
            
            [center setDownloadPath:(char *)[self.destPath UTF8String] forDevice:dev];
            while (--tickets > 0) {
                if ([center downloadRecordFile:nodeVal  count:1 fromDevice:dev]) {
                    getTicket = YES;
                    break;
                }
                //1s后尝试重连
                usleep(1000000);
            }
            
            if (getTicket) {
                //等待中心事件回调
                [self.downloadCond lock];
                if (!self.trigged) {
                    [self.downloadCond wait];
                }
                //查看下载事件
                switch (self.downloadEvent) {
                    case Download_Event_Complete:{
                        if(DOWNLOAD_MVC_DEBUG) NSLog(@"截获下载完成事件");
                    }
                        break;
                    case Download_Event_Cancel:{
                        [center downloadCancel:dev];
                        [self updateDownloadProgress:@"已取消" forDict:file];
                        cancel = YES;
                        if(DOWNLOAD_MVC_DEBUG) NSLog(@"截获取消事件");
                    }
                        break;
                    case Download_Event_EXP: {
                        stop = YES;
                        if(DOWNLOAD_MVC_DEBUG) NSLog(@"截获异常事件");
                    }
                    default:
                        break;
                }
                
                self.trigged = NO;
                [self.downloadCond unlock];
            } else {
                [self updateDownloadProgress:NSLocalizedString(@"time out", nil) forDict:file];
                stop = YES;
            }
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.download = NO;
    });
}

#pragma mark - life cycle
- (void)windowDidLoad {
    [super windowDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDispatchCenterNotification:)
                                                 name:RECORD_FILE_DOWNLOAD_PROGRESS_NOTIFICATION
                                               object:nil];
    self.downloadCond = [[NSCondition alloc] init];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    NSButton *closeButton = [self.window standardWindowButton:NSWindowCloseButton];
    closeButton.target = self;
    closeButton.action = @selector(exitAction:);
}

- (void)dealloc
{
    NSLog(@"Running in %@,'%@'",self.className,NSStringFromSelector(_cmd));
    [self cancelDownload];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - action
- (IBAction)exitAction:(id)sender
{
    //查看是否正在下载
    if (self.isDownload) {
        NSAlert *alert = [[NSAlert alloc] init];
        
        alert.messageText = NSLocalizedString(@"Downloading video files", nil);
        alert.informativeText = NSLocalizedString(@"Please stop downloading the video", nil);
        
        [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
        [alert runModal];
    } else {
        [self close];
    }
}

- (void)cancelDownload
{
    [self.downloadCond lock];
    self.trigged = YES;
    self.download = NO;
    self.downloadEvent = Download_Event_Cancel;
    [self.downloadCond signal];
    [self.downloadCond unlock];
}

- (IBAction)download:(id)sender
{
    if (!self.isDownload) {
        //查看是否有勾选的文件
        NSMutableArray *selectedFiles = [[NSMutableArray alloc] init];
        
        for (NSDictionary *file in self.recordFilesInfo) {
            if ([[file valueForKey:KEY_CHECKED] boolValue]) {
                [selectedFiles addObject:file];
            }
            [file setValue:@"" forKey:KEY_PRO];
        }
        
        if (selectedFiles.count == 0) {
            NSAlert *alert = [[NSAlert alloc] init];
            
            alert.messageText = NSLocalizedString(@"No files have been selected", nil);
            [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
            [alert runModal];
        
            return;
        }
        
        NSOpenPanel *panel = [NSOpenPanel openPanel];
        [panel setAllowsMultipleSelection:NO];
        [panel setCanChooseDirectories:YES];
        [panel setCanChooseFiles:NO];
        [panel setResolvesAliases:YES];
        
        if ([panel runModal] == NSModalResponseOK) {
            //设置目的地
            [self setDestPath:[panel.URL.path stringByAppendingString:@"/"]];
            //准备
            for (NSDictionary *file in selectedFiles) {
                [file setValue:@"等待" forKey:KEY_PRO];
                FOSNVR_RecordNode node;
                [[file valueForKey:KEY_NODE] getValue:&node];
                
#if 0
                NSLog(@"indexNO=%d,tms=%d,tme=%d,dts=%@,dte=%@",node.indexNO,node.tmStart,node.tmEnd,[[NSDate dateWithTimeIntervalSince1970:node.tmStart] stringWithFormatter:@"dd/MM/YYYY HH:mm:ss"],
                      [[NSDate dateWithTimeIntervalSince1970:node.tmEnd] stringWithFormatter:@"dd/MM/YYYY HH:mm:ss"]);
#endif
            }
            self.download = YES;
            //发射
            [NSThread detachNewThreadSelector:@selector(downloadRoutine:) toTarget:self withObject:selectedFiles];
        }
    } else
        [self cancelDownload];
}

- (IBAction)lastPage:(id)sender
{
    self.curPage--;
}

-(IBAction)nextPage:(id)sender
{
    self.curPage++;
}

- (IBAction)jump:(id)sender
{
    NSUInteger p = self.curPageTF.integerValue - 1;
    if (p < self.pageCnt) {
        self.curPage = p;
    }
}

- (IBAction)tableviewCellAction:(NSButtonCell *)sender {
    NSInteger row = [self.tableView clickedRow];
    
    if (row < self.curPageFileInfos.count) {
        NSMutableDictionary *dict = self.curPageFileInfos[row];
        NSNumber *value = [dict valueForKey:KEY_CHECKED];
        BOOL checked = !value.boolValue;
        [dict setValue:[NSNumber numberWithBool:checked] forKey:KEY_CHECKED];
    }
    
    [self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
}
#pragma mark - private api
- (void)updateDownloadProgress :(NSString *)title forDict :(NSMutableDictionary *)dict
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [dict setValue:title forKey:KEY_PRO];
        [self.tableView reloadData];
    });
}

- (NSString *)stringForRecordFileType :(int)type
{
    NSString *ret = @"";
    switch (type) {
        case 1:
        case 2:
            ret = NSLocalizedString(@"Normal Record", nil);
            break;
        case 4:
        case 8:
            ret = NSLocalizedString(@"Alarm Record", nil);
            break;
        default:
            break;
    }
    return ret;
}

#pragma mark - table view datasource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.curPageFileInfos.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSString *key = tableColumn.identifier;
    NSDictionary *dict = self.curPageFileInfos[row];
    
    id ret = nil;
    if ([key isEqualToString:KEY_CHECKED])
        ret = [dict valueForKey:KEY_CHECKED];
    else if ([key isEqualToString:KEY_NUM])
        ret = [NSString stringWithFormat:@"%lu",self.curPage * ROWS_PER_PAGE + row + 1];
    else if ([key isEqualToString:KEY_DEV])
        ret = [(CDevice *)[dict valueForKey:KEY_DEV] name];
    else if ([key isEqualToString:KEY_PRO])
        ret = [dict valueForKey:KEY_PRO];
    else {
        //node part
        NSValue *nodeVal = [dict valueForKey:KEY_NODE];
        FOSNVR_RecordNode node;
        
        if (nodeVal) {
            [nodeVal getValue:&node];
            
            if ([key isEqualToString:KEY_CHN])
                ret = [NSNumber numberWithInt:node.channel + 1];
            else if ([key isEqualToString:KEY_TYPE])
                ret = [self stringForRecordFileType:node.recordType];
            else if ([key isEqualToString:KEY_ST])
                ret = [[NSDate dateWithTimeIntervalSince1970:node.tmStart] stringWithFormatter:@"dd/MM/YYYY HH:mm:ss"];
            else if ([key isEqualToString:KEY_ET])
                ret = [[NSDate dateWithTimeIntervalSince1970:node.tmEnd] stringWithFormatter:@"dd/MM/YYYY HH:mm:ss"];
            else if ([key isEqualToString:KEY_SIZE]){
                ret =[NSString stringWithFormat:@"%.2fMB",node.fileSize / (1024 * 1024 * 1.0)];
            }
        }
    }
    
    return ret;
}

#pragma mark - tableview delegate
- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return NO;
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectTableColumn:(NSTableColumn *)tableColumn
{
    return NO;
}

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn
{
    if ([tableColumn.identifier isEqualToString:KEY_CHECKED]) {
        CheckboxHeaderCell *mHeaderCell = [tableColumn headerCell];
        [mHeaderCell onClick];
        BOOL checked = [mHeaderCell getState];
        for (NSMutableDictionary *dict in self.curPageFileInfos) {
            [dict setValue:[NSNumber numberWithBool:checked] forKey:KEY_CHECKED];
        }
        [self.tableView reloadData];
    }
}

#pragma mark - setter && getter
- (void)setRecordFilesInfo:(NSArray *)recordFilesInfo
{
    //按开始倒序排列
    _recordFilesInfo = [recordFilesInfo sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        FOSNVR_RecordNode node1,node2;
        [[obj1 valueForKey:KEY_NODE] getValue:&node1];
        [[obj2 valueForKey:KEY_NODE] getValue:&node2];
        
        return (node1.tmStart > node2.tmStart)? NSOrderedAscending : NSOrderedDescending;
    }];
    NSUInteger filesCnt = _recordFilesInfo.count;
    NSUInteger div = filesCnt / ROWS_PER_PAGE;
    NSUInteger mod = filesCnt % ROWS_PER_PAGE;
    
    self.pageCnt = div + ((mod == 0)? 0 : 1);
    [self.pageCntTF setStringValue:[NSString stringWithFormat:@"%lu",self.pageCnt]];
    [self setCurPage:0];
}

- (void)setCurPage:(NSUInteger)curPage
{
    if (curPage < self.pageCnt) {
        _curPage = curPage;
        
        NSMutableArray *arr = [[NSMutableArray alloc] init];
        for (NSUInteger i = 0; i < ROWS_PER_PAGE; i++) {
            NSUInteger idx = (ROWS_PER_PAGE * _curPage) + i;
            if (idx < self.recordFilesInfo.count) {
                [arr addObject:self.recordFilesInfo[idx]];
            }
        }

        self.curPageFileInfos = arr;
        self.curPageTF.stringValue = [NSString stringWithFormat:@"%lu",self.curPage + 1];
        CheckboxHeaderCell *mHeaderCell = [(NSTableColumn *)self.tableView.tableColumns[0] headerCell];
        
        if ([mHeaderCell getState] == NSOnState) {
            [mHeaderCell onClick];
        }
        
        [self.tableView reloadData];
    }
}

- (void)setPageCntTF:(NSTextField *)pageCntTF
{
    _pageCntTF = pageCntTF;
    _pageCntTF.stringValue = [NSString stringWithFormat:@"%lu",self.pageCnt];
}

- (void)setCurPageTF:(NSTextField *)curPageTF
{
    _curPageTF = curPageTF;
    _curPageTF.stringValue = [NSString stringWithFormat:@"%lu",self.curPage + 1];
}

- (void)setTableView:(NSTableView *)tableView
{
    _tableView = tableView;
    
    //自定义的头空间Cell,用于绘制Checkbox
    CheckboxHeaderCell *mHeaderCell = [[CheckboxHeaderCell alloc] init];
    [mHeaderCell setBordered:YES];
    
    //替换新的头控件单元
    NSTableColumn *checkboxColumn = [_tableView tableColumnWithIdentifier:KEY_CHECKED];
    [checkboxColumn setHeaderCell:mHeaderCell];
}

- (void)setDestPath:(NSString *)destPath
{
    _destPath = destPath;
    self.destPathTF.stringValue = _destPath;
}

- (void)setDownload:(BOOL)download
{
    _download = download;
    self.downloadBtn.title = _download? NSLocalizedString(@"Cancel", nil) : NSLocalizedString(@"Donwload", nil);
}
@end
