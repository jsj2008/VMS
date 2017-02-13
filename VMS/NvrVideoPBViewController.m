//
//  NvrVideoPBViewController.m
//  
//
//  Created by mac_dev on 16/6/13.
//
//

#import "NvrVideoPBViewController.h"
#import "CheckCellView.h"
#import "RecordFileDownloadWindowController.h"


#define NVR_PB_DEBUG    1
#define SECS_PER_DAY    86400.0
#define COL_TITLE       @"title"
#define COL_STATE       @"state"
#define KEY_CHECKED     @"checked"
#define KEY_STIME       @"stime"
#define KEY_ETIME       @"etime"
#define KEY_TTV_NODES   @"ttv nodes"
#define KEY_POINTS      @"points"
#define KEY_FILE_INFOS  @"file infos"
#define KEY_CH          @"channel"
#define KEY_DEVICE      @"device"
#define KEY_PLAYING     @"playing"
#define KEY_IS_FILE_END @"is_file_end"
#define KEY_FILLING     @"filling"

@interface NvrPbChannelState()
@end

@implementation NvrPbChannelState

- (instancetype)init
{
    if (self = [super init]) {
        self.viewId = -1;
        self.olvChecked = NO;
    }
    
    return self;
}

@end


@interface NvrVideoPBViewController ()

@property (nonatomic,strong) MultyVideoViewsManager *multyVideoViewsManager;
@property (nonatomic,weak) IBOutlet NSView *placeHolder;
@property (nonatomic,weak) IBOutlet NSOutlineView *outlineView;
@property (nonatomic,strong) NSAlert *playbackAlert;
@property (nonatomic,weak) IBOutlet JFButton *playButton;
@property (nonatomic,weak) IBOutlet NSTextField *ratioTF;
@property (weak,nonatomic) IBOutlet NSButton *scheduledVideo;
@property (weak,nonatomic) IBOutlet NSButton *manualVideo;
@property (weak,nonatomic) IBOutlet NSButton *alarmVideo;
@property (weak,nonatomic) IBOutlet NSButton *motionDetectingVideo;
@property (weak,nonatomic) IBOutlet NSButton *searchVideoBtn;
@property (weak,nonatomic) IBOutlet TFDatePicker *datePicker;
@property (weak,nonatomic) IBOutlet TimeTableView *timeTableView;
@property (weak,nonatomic) IBOutlet NSProgressIndicator *searchVideoSpin;
@property (nonatomic,strong) NSTimer *ttvTimer;
@property (nonatomic,strong) RecordFileDownloadWindowController *downloadMVC;

@property (nonatomic,strong) NSArray        *olvContents;
@property (nonatomic,strong) NSDictionary   *olvChannelStates;
@property (nonatomic,strong) NSMutableDictionary *progress;
@property (strong,nonatomic) NSArray        *ttvContents;
@property (strong,nonatomic) NSArray        *ttvGroupInfos;

@property (nonatomic,assign) time_t st;
@property (nonatomic,assign) time_t et;
@property (nonatomic,assign) float ratio;//倍率
@property (nonatomic,assign,getter=isSearching) BOOL searching;

@property (nonatomic,weak) IBOutlet JFBackground *scheduleRecordIndicator;
@property (nonatomic,weak) IBOutlet JFBackground *manualRecordIndicator;
@property (nonatomic,weak) IBOutlet JFBackground *alarmRecordIndicator;

@end

@implementation NvrVideoPBViewController

#pragma mark - private api
- (void)PLAYBACK_ALERT:(NSString *)info
{
    do{
        if (!self.playbackAlert) {
            NSAlert *alert = [[NSAlert alloc] init];
            
            alert.messageText = info;
            alert.informativeText = @"";
            
            [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
            [self setPlaybackAlert:alert];
           
            if (NSAppKitVersionNumber < NSAppKitVersionNumber10_9) {
                [[NSApplication sharedApplication] beginSheet:self.playbackAlert.window
                                               modalForWindow:self.view.window
                                                modalDelegate:self
                                               didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
                                                  contextInfo:NULL];
            }
            else {
                [self.playbackAlert beginSheetModalForWindow:self.view.window
                                           completionHandler:^(NSModalResponse returnCode) {
                                               [self didEndSheet:self.playbackAlert.window
                                                      returnCode:returnCode
                                                     contextInfo:NULL];
                                           }];
            }
            
        }
    }while (0);
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:nil];
    self.playbackAlert = nil;
}

- (Channel *)chnFromOutlineViewContentsWithId :(NSInteger)chnId
{
    Group *group = self.olvContents[0];
    NSArray *devices = [group children];
    
    for (CDevice *device in devices) {
        NSArray *channels = [device children];
        for (Channel *chn in channels) {
            if (chn.uniqueId == chnId) {
                return chn;
            }
        }
    }
    
    return nil;
}

#pragma mark - notification
- (void)handlePlaybackNotification :(NSNotification *)aNotific
{
    if ([aNotific.name isEqualToString:PB_NOTIFICATION]) {
        NSInteger devId = [[aNotific.userInfo valueForKey:KEY_EVENT_DEVICE_ID] longValue];
        FOSNVR_PBEVENT event = [[aNotific.userInfo valueForKey:KEY_EVENT_TYPE] intValue];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *gInfo = nil;
            for (NSDictionary *dict in self.ttvGroupInfos) {
                CDevice *dev = [dict valueForKey:KEY_DEVICE];
                
                if ([[dict valueForKey:KEY_PLAYING] boolValue] &&
                    dev.uniqueId == devId) {
                    gInfo = dict;
                    break;
                }
            }
            
            switch (event) {
                case FOSNVR_PBEVENT_FILE_END: {
                    [gInfo setValue:[NSNumber numberWithBool:YES] forKey:KEY_IS_FILE_END];
                    //查看是否所有的播放设备文件都结束了，如果结束了，就停止播放
                    BOOL isAllGroupFileEnd = YES;
                    for (NSDictionary *dict in self.ttvGroupInfos) {
                        if ([[dict valueForKey:KEY_PLAYING] boolValue] && ![[dict valueForKey:KEY_IS_FILE_END] boolValue]) {
                            isAllGroupFileEnd = NO;
                            break;
                        }
                    }
                    
                    if (isAllGroupFileEnd) {
                        [self performStop];
                    }
                }
                    break;
                case FOSNVR_PBEVENT_PROGRESS_START:
                    [gInfo setValue:[NSNumber numberWithBool:NO] forKey:KEY_IS_FILE_END];
                    break;
                case FOSNVR_PBEVENT_PROGRESS_END:
                    [gInfo setValue:[NSNumber numberWithBool:NO] forKey:KEY_FILLING];
                    break;
                default:
                    break;
            }
        });
    }
}


#pragma mark - action
#define MAX_CHECKED_CH_CNT  4
- (BOOL)checkable
{
    NSArray *allCStates = self.olvChannelStates.allValues;
    int checkedChnCnt = 0;
    
    for (NvrPbChannelState *cState in allCStates) {
        if (cState.olvChecked) {
            checkedChnCnt++;
        }
    }
    
    return (allCStates.count > 0) && (checkedChnCnt < 4);
}

- (IBAction)checkedTreeItem:(id)sender
{
    NSInteger           cId = [sender tag];
    BOOL                state = [(NSButton *)sender state] == NSOnState;
    NSString            *cKey = [NSString stringWithFormat:@"%ld",cId];
    NvrPbChannelState   *cState = [self.olvChannelStates valueForKey:cKey];
    
    if (state && ![self checkable]) {
        [self PLAYBACK_ALERT:NSLocalizedString(@"Maximum support 4 channel playback", nil)];
        [(NSButton *)sender setState:NSOffState];
        return;
    }
    
    if (cId >= 0 && (state != cState.olvChecked)) {
        cState.olvChecked = state;
        [self.outlineView reloadItem:[self chnFromOutlineViewContentsWithId:cId]];
    }
}

- (IBAction)outlineViewContextMenuAction:(id)sender
{
    NSInteger clickedRow = [self.outlineView clickedRow];
    BOOL state = ([sender tag] == 0);
    id item = nil;
    
    if (clickedRow != -1) {
        item = [self.outlineView itemAtRow:clickedRow];
        
        NSMutableArray *channels = [[NSMutableArray alloc] init];
        if ([item isKindOfClass:[Group class]]) {
            NSArray *devices = [(Group *)item children];
            for (CDevice *device in devices) {
                [channels addObjectsFromArray:[device children]];
            }
        } else if ([item isKindOfClass:[CDevice class]]) {
            [channels addObjectsFromArray:[(CDevice *)item children]];
        }
        
        for (Channel *channel in channels) {
            NSString            *cKey = [NSString stringWithFormat:@"%d",channel.uniqueId];
            NvrPbChannelState   *cState = [self.olvChannelStates valueForKey:cKey];
            
            cState.olvChecked = state;
        }
        
        [self.outlineView reloadItem:item reloadChildren:YES];
    }
}


- (int)typeFromFosNvrRecordType :(FOSNVR_RECORDTYPE)t
{
    switch (t) {
        case FOSNVRRDTYPE_SCHEDULE:
            return 0;
            
        case FOSNVRRDTYPE_MANUAL:
            return 1;
            
        case FOSNVRRDTYPE_MOTION:
        case FOSNVRRDTYPE_IOALARM:
            return 2;
            
            
        default:
            return 3;
    }
}


- (IBAction)findVideos:(id)sender
{
    if (self.isSearching)
        return;
    
    if (self.isPlaying) {
        [self PLAYBACK_ALERT:NSLocalizedString(@"Please stop playback", nil)];
        return;
    }
    
    //录像类型
    FOSNVR_RECORDTYPE recordType = 0;
    if (self.manualVideo.state == NSOnState) recordType |= FOSNVRRDTYPE_MANUAL;
    if (self.scheduledVideo.state == NSOnState) recordType |= FOSNVRRDTYPE_SCHEDULE;
    //if (self.motionDetectingVideo.state == NSOnState) recordType |= FOSNVRRDTYPE_MOTION;
    if (self.alarmVideo.state == NSOnState) recordType |= FOSNVRRDTYPE_IOALARM | FOSNVRRDTYPE_MOTION;
    
    if (recordType == 0) {
        [self PLAYBACK_ALERT:NSLocalizedString(@"Please select type", nil)];
        return;
    }
    
    //日期
    NSDate *date = [self.datePicker dateValue];
    time_t st = (long long)[[date dateByMovingToBeginningOfDay] timeIntervalSince1970];
    time_t et = (long long)[[date dateByMovingToEndOfDay] timeIntervalSince1970];
    
    self.searching = YES;
    self.searchVideoBtn.enabled = NO;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //遍历所有的设备，查找录像文件，生成TimeTable信息
        NSArray         *devices    = [(Group *)self.olvContents[0] children];
        DispatchCenter  *center     = [DispatchCenter sharedDispatchCenter];
        NSMutableArray  *contents   = [[NSMutableArray alloc] init];
        BOOL isUserSelectedChannel  = NO;
        
        for (CDevice *device in devices) {
            int channels = 0;
            NSMutableDictionary *subContents = [[NSMutableDictionary alloc] init];
            
            for (Channel *ch in [device children]) {
                NSString            *cKey = [NSString stringWithFormat:@"%d",ch.uniqueId];
                NvrPbChannelState   *cState = [self.olvChannelStates valueForKey:cKey];
                
                if (cState.olvChecked ) {
                    channels |= 1<<ch.logicId;
                    isUserSelectedChannel = YES;
                    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                    
                    [dict setValue:ch forKey:KEY_CH];
                    [dict setValue:[NSNumber numberWithBool:YES] forKey:KEY_CHECKED];
                    [dict setValue:[[NSMutableArray alloc] init] forKey:KEY_TTV_NODES];
                    [dict setValue:[[NSMutableArray alloc] init] forKey:KEY_FILE_INFOS];
                    [subContents setValue:dict forKey:[NSString stringWithFormat:@"%d",ch.logicId]];
                }
            }
            
            //通知中心查找录像文件
            int fileCnt = [center searchRecordFilesWithStartTime:st endTime:et type:recordType channels:channels fromDevice:device];
            
            for (int i = 0; i < fileCnt; i++) {
                FOSNVR_RecordNode node;
                if ([center getRecordNodeInfo:&node atIdx:i fromDevice:device]) {
#if 0
                    NSLog(@"indexNo = %d,ch = %d,filesize = %d, tm_start = %d,tm_end = %d record_type = %d",
                          node.indexNO,node.channel,node.fileSize,node.tmStart,node.tmEnd,node.recordType);
                    NSLog(@"%@,%@",[[NSDate dateWithTimeIntervalSince1970:node.tmStart] stringWithFormatter:@"dd/MM/YYYY hh:mm:ss"],
                          [[NSDate dateWithTimeIntervalSince1970:node.tmEnd] stringWithFormatter:@"dd/MM/YYYY hh:mm:ss"]);
#endif
                    if (node.channel < device.channelCount) {
                        NSString            *key        = [NSString stringWithFormat:@"%d",node.channel];
                        NSMutableDictionary *dict       = [subContents valueForKey:key];
                        NSMutableArray      *infos      = [dict valueForKey:KEY_FILE_INFOS];
                        NSMutableArray      *ttvNodes   = [dict valueForKey:KEY_TTV_NODES];
                        
                        CGFloat sPos = [self positionFromTimeInterval:(node.tmStart < st)? (unsigned)st : node.tmStart];
                        CGFloat ePos = [self positionFromTimeInterval:(node.tmEnd > et)? (unsigned)et : node.tmEnd];
                        TTV_NODE ttvNode;
                        
                        ttvNode.type = [self typeFromFosNvrRecordType:node.recordType];
                        ttvNode.x = sPos;
                        ttvNode.y = ePos;
                        //ttvNode.pt = NSMakePoint(sPos, ePos);

                        [ttvNodes addObject:[NSValue value:&ttvNode withObjCType:@encode(TTV_NODE)]];
                        [infos addObject:[NSValue value:&node withObjCType:@encode(FOSNVR_RecordNode)]];
                    }
                }
            }
            
            if (subContents.count > 0) {
                NSMutableArray *allValues = [NSMutableArray arrayWithArray:subContents.allValues];
                [allValues sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                    Channel *ch1 = [obj1 valueForKey:KEY_CH];
                    Channel *ch2 = [obj2 valueForKey:KEY_CH];
                    
                    return (ch1.logicId < ch2.logicId)? NSOrderedAscending : NSOrderedDescending;
                }];
                [contents addObjectsFromArray:[NSArray arrayWithObject:allValues]];
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            self.searching = NO;
            self.searchVideoBtn.enabled = YES;
            if (!isUserSelectedChannel) {
                [self PLAYBACK_ALERT:NSLocalizedString(@"Please select type", nil)];
                return;
            } else {
                [self setSt:st];
                [self setEt:et];
                [self setTtvContents:[NSArray arrayWithArray:contents]];
            }
        });
    });
}

- (IBAction)downloadAction:(id)sender
{
    //查看是否正在录像
    if (self.isPlaying) {
        [self PLAYBACK_ALERT:NSLocalizedString(@"Please stop playback", nil)];
        return;
    }
    
    [self performDownload];
}

- (IBAction)playbackControls:(id)sender
{
    switch ([sender tag]) {
        case 0://播放/暂停
            [self performPlay];
            break;
        case 1://停止
            [self performStop];
            break;
        case 2://倒播
            [self performBack];
            break;
        case 3://快播
            [self performFast];
            break;
        case 4://慢播
            [self performSlow];
            break;
        default:
            break;
    }
}

- (void)updateTimeTableUIAction :(NSTimer *)timer
{
    for (int g = 0;g < self.ttvGroupInfos.count ; g++) {
        NSDictionary *gInfo = self.ttvGroupInfos[g];
        if ([[gInfo valueForKey:KEY_PLAYING] boolValue] &&
            ![[gInfo valueForKey:KEY_FILLING] boolValue]) {
            NSDate *dt = [self.progress valueForKey:[NSString stringWithFormat:@"%d",g]];
            double t = [dt timeIntervalSinceDate :[dt dateByMovingToBeginningOfDay]];
            [self.timeTableView setPosition:t / SEC_PER_DAY  ForGroup:g];
        }
    }
}

- (CGFloat)positionFromTimeInterval :(unsigned int)tm
{
    NSDate *dt = [NSDate dateWithTimeIntervalSince1970:tm];
    NSDate *beginOfDay = [dt dateByMovingToBeginningOfDay];
    
    return [dt timeIntervalSinceDate:beginOfDay]/SEC_PER_DAY;
}

#pragma mark - life cycle
- (void)dealloc
{
    NSLog(@"Running in %@,'%@'",self.className,NSStringFromSelector(_cmd));
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)onViewLoad
{
    [self setupMultyVideoViewsManager];
    [self setupIndicators];
    [[DispatchCenter sharedDispatchCenter] addPBObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePlaybackNotification:) name:PB_NOTIFICATION object:nil];
    [self.outlineView reloadData];
    [self.outlineView expandItem:nil expandChildren:YES];
}

- (void)setupIndicators
{
    NSArray *indicators = @[self.scheduleRecordIndicator,
                            self.manualRecordIndicator,
                            self.alarmRecordIndicator];
    
    for (int i = 0; i < indicators.count; i++) {
        JFBackground *bg = indicators[i];
        bg.backgroundColor = [TimeTableView colorForType:i];
    }
}

- (void)loadView
{
    [super loadView];
    
    if (NSAppKitVersionNumber < NSAppKitVersionNumber10_10) {
        [self onViewLoad];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self onViewLoad];
}

- (void)setupMultyVideoViewsManager
{
    //We should keep the jfSplitview's size same as placeholder
    //add auto layout constraint for it
    NSView *view = self.multyVideoViewsManager.view;
    [self.placeHolder addSubview:view];
    
    NSLayoutAttribute layoutAttributes[4] = {
        NSLayoutAttributeTop,
        NSLayoutAttributeLeading,
        NSLayoutAttributeBottom,
        NSLayoutAttributeTrailing
    };
    
    NSView *superView = [view superview];
    [view setTranslatesAutoresizingMaskIntoConstraints:NO];
    for (int i = 0; i < 4; i++) {
        NSLayoutAttribute layoutAttribute = layoutAttributes[i];
        NSLayoutConstraint *constraint =
        [NSLayoutConstraint constraintWithItem:view
                                     attribute:layoutAttribute
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:superView
                                     attribute:layoutAttribute
                                    multiplier:1.0
                                      constant:0.0];
        [superView addConstraint:constraint];
    }
    
    [superView updateConstraints];
}

#pragma mark - tab mvc protocol
- (void)willTab :(NSNotification *)aNotific stop :(BOOL *)stop
{
    if (self.isPlaying) {
        [self PLAYBACK_ALERT:NSLocalizedString(@"Please stop playback", nil)];
        *stop = YES;
        return;
    }
    
    *stop = NO;
}


#pragma mark - outline view datasource
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    return !item? self.olvContents.count : [item children].count;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    return !item? self.olvContents[index] : [[item children] objectAtIndex:index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return !item? YES : [item children].count > 0;
}

#pragma mark - outline view delegate
- (NSView *)outlineView:(NSOutlineView *)outlineView
     viewForTableColumn:(NSTableColumn *)tableColumn
                   item:(id)item
{
    NSString *identifier = tableColumn.identifier;
    NSTableCellView *cellView = [outlineView makeViewWithIdentifier:identifier owner:self];;
    
    if ([identifier isEqualToString:COL_TITLE]) {
        //根据节点的类型，贴出不同的图标
        NSString *imageName,*title;
        
        if ([item isKindOfClass:[CDevice class]]) {
            imageName = @"NVR_Online";
            title = [item name];
        }
        else if ([item isKindOfClass:[Group class]]) {
            imageName = @"INPUT";
            title = [item name];
        }
        else if ([item isKindOfClass:[Channel class]]) {
            imageName = @"ChannelConnected";
            title = [NSString stringWithFormat:@"CH%d",[(Channel *)item logicId] + 1];
        }
        
        
        [cellView.imageView setImage:[NSImage imageNamed:imageName]];
        [cellView.textField setObjectValue:title];
    }
    else if ([identifier isEqualToString:COL_STATE]) {
        BOOL        state = NO;
        BOOL        hidden = YES;
        NSInteger   tag = -1;
        
        if ([item isKindOfClass:[Channel class]]) {
            NSString            *cKey = [NSString stringWithFormat:@"%d",((Channel *)item).uniqueId];
            NvrPbChannelState   *cState = [self.olvChannelStates valueForKey:cKey];
            
            hidden  = NO;
            state   = cState.olvChecked;
            tag     = [(Channel *)item uniqueId];
        }
        
        [(CheckCellView *)cellView setTag:tag];
        [(CheckCellView *)cellView setState:state];
        [(CheckCellView *)cellView setHidden:hidden];
    }
    
    return cellView;
}
#pragma mark - MVVM delegate
- (BOOL)shouldEnterSingleWnd
{
    return ![self.multyVideoViewsManager isFreeView:self.multyVideoViewsManager.selectedViewId];
}

- (void)selectionDidChange :(NSNotification *)aNotific
{}

#pragma mark - menu delegate
- (void)menuNeedsUpdate:(NSMenu *)menu
{
    NSInteger clickedRow = [self.outlineView clickedRow];
    id item = nil;
    BOOL hiden = YES;
    
    if (-1 != clickedRow) {
        item = [self.outlineView itemAtRow:clickedRow];
        //查看点击的结点类型
        if ([item isKindOfClass:[Group class]] ||
            [item isKindOfClass:[CDevice class]]) {
            hiden = NO;
        }
    }
    
    NSArray *menuItems = [menu itemArray];
    [menuItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj setHidden:hiden];
    }];
}

#pragma mark - timetable view delegate
- (NSUInteger)numberOfGroupInTimeTable :(NSView *)view
{
    return self.ttvContents.count;
}

- (NSUInteger)numberOfRowAtGroupIdx :(NSUInteger)idx inTimeTableView :(NSView *)view
{
    return [self.ttvContents[idx] count];
}

- (BOOL)timeTableView :(NSView *)view shouldCheckGroup :(NSUInteger)g row :(NSUInteger)r
{
    return [[[[self.ttvContents objectAtIndex:g] objectAtIndex:r] valueForKey:KEY_CHECKED] boolValue];
}

- (NSString *)timeTableView :(NSView *)view titleForGroup :(NSUInteger)g row :(NSUInteger)r
{
  
    return [(Channel *)[[[self.ttvContents objectAtIndex:g] objectAtIndex:r] valueForKey:KEY_CH] name];
}

- (NSArray *)timeTableView :(NSView *)view dateRangesForGroup :(NSUInteger)g row :(NSUInteger)r
{
    return [[[self.ttvContents objectAtIndex:g] objectAtIndex:r] valueForKey:KEY_TTV_NODES];
}

- (BOOL)shouldHittedTimeTableView :(NSView *)view
{
    return YES;
}

- (void)selectionDidChangeNotification :(NSNotification *)aNotific
{
    NSUInteger g = [[aNotific.userInfo valueForKey:KEY_GROUP] unsignedIntegerValue];
    NSUInteger r = [[aNotific.userInfo valueForKey:KEY_ROW] unsignedIntegerValue];

    if (g < self.ttvContents.count) {
        NSMutableDictionary *dict = [self.ttvContents[g] objectAtIndex:r];
        BOOL checked = [[dict valueForKey:KEY_CHECKED] boolValue];
        
        if (checked) {
            [dict setObject:[NSNumber numberWithBool:NO] forKey:KEY_CHECKED];
        }
        else {
            //查看选中通道数是否已经达到上限
            NSInteger selectedChannelsCount = 0;
            for (NSDictionary *d in [self.ttvContents firstObject]) {
                if ([[d valueForKey:KEY_CHECKED] boolValue]) {
                    ++selectedChannelsCount;
                }
            }
            
            if (selectedChannelsCount < 4)
                [dict setObject:[NSNumber numberWithBool:YES] forKey:KEY_CHECKED];
            else
                [self PLAYBACK_ALERT:NSLocalizedString(@"Maximum support 4 channel playback", nil)];
        }
        [aNotific.object setNeedsDisplay:YES];
    }
}

- (void)positionDidChangeNotification :(NSNotification *)aNotific
{
    NSUInteger  g = [[aNotific.userInfo valueForKey:KEY_GROUP] unsignedIntValue];
    double      position = [self.timeTableView positionOfGroup:g];
    time_t      t = self.st + SECS_PER_DAY * position;
    
    [self.ttvGroupInfos[g] setValue:[NSNumber numberWithBool:YES] forKey:KEY_FILLING];
    [self performSeekGroup:g withTime:t];
}


#pragma mark - player cmd
- (void)performPlay
{
    MultyVideoViewsManager *manager = self.multyVideoViewsManager;
    //根据时间表控件内容，开始进行播放
    if (!self.isPlaying) {
        //修改起始时间
        NSMutableArray *gInfos = [[NSMutableArray alloc] init];
        BOOL isChannels = NO;
        
        for (int g = 0; g < self.ttvContents.count; g++) {
            CDevice *device = nil;
            int channels = 0;
            //查看该组是否有勾选的通道
            NSArray *group = [self.ttvContents objectAtIndex:g];
            for (NSDictionary *dict in group) {
                BOOL                checked     = [[dict valueForKey:KEY_CHECKED] boolValue];
                Channel             *chn        = [dict valueForKey:KEY_CH];
                NSString            *cKey       = [NSString stringWithFormat:@"%d",chn.uniqueId];
                NvrPbChannelState   *cState     = [self.olvChannelStates valueForKey:cKey];
                
                
                if (checked) {
                    channels |= 1 << chn.logicId;
                    device = chn.device;
                    int viewId = [manager freeViewId];
                    if (viewId >= 0) {
                        [manager setView:viewId group:nil channel:chn];
                        [manager setView:viewId state:VIDEO_PLAYING];
                        cState.viewId = viewId;
                    }
                }
            }
        
            if (channels > 0) {
                NSMutableDictionary *gInfo = [[NSMutableDictionary alloc] init];
                
                [gInfos addObject:gInfo];
                [gInfo setValue:device forKey:KEY_DEVICE];
                [gInfo setValue:[NSNumber numberWithBool:YES] forKey:KEY_PLAYING];
                [[DispatchCenter sharedDispatchCenter] startPlaybackVideoFromDevice:device channels:channels st:(unsigned)self.st et:(unsigned)self.et];
                isChannels = YES;
            }
        }
        
        if (isChannels) {
            self.multyVideoViewsManager.pageSize = 4;
            self.playing = YES;
            self.ratio = 1.0;
            self.ttvGroupInfos = [NSArray arrayWithArray:gInfos];
        }
        else
            [self PLAYBACK_ALERT:NSLocalizedString(@"Unchecked", nil)];
    }
    else if (self.isPausing) {
        //像所有的设备发送唤醒命令
        [self sendCmd:FOSNVRPBCMD_RESUMEPLAY value:0];
        self.pausing = NO;
    }
    else {
        //像所有的设备发送唤醒命令
        [self sendCmd:FOSNVRPBCMD_PAUSEPLAY value:0];
        self.pausing = YES;
    }
}

- (void)performStop
{
    if (self.isPlaying) {
        for (int g = 0; g < self.ttvGroupInfos.count; g++) {
            NSArray         *group = self.ttvContents[g];
            NSDictionary    *gInfo = self.ttvGroupInfos[g];
            CDevice         *dev = [gInfo valueForKey:KEY_DEVICE];
            
            if ([[gInfo valueForKey:KEY_PLAYING] boolValue]) {
                [gInfo setValue:[NSNumber numberWithBool:NO] forKey:KEY_PLAYING];
                
                for (NSDictionary *cInfo in group) {
                    Channel             *chn = [cInfo valueForKey:KEY_CH];
                    NSString            *cKey = [NSString stringWithFormat:@"%d",chn.uniqueId];
                    NvrPbChannelState   *cState = [self.olvChannelStates valueForKey:cKey];
                    
                    if (cState.viewId >= 0) {
                        [self.multyVideoViewsManager setView:cState.viewId group:nil channel:nil];
                        cState.viewId = -1;
                    }
                }
                [[DispatchCenter sharedDispatchCenter] stopPlaybackVideoFromDevice:dev];
            }
        }
        self.playing = NO;
    }
}


- (void)performSeekGroup :(NSUInteger)g withTime :(time_t)t
{
    NSArray *gInfos = self.ttvGroupInfos;
    if (self.isPlaying && g < gInfos.count) {
        NSDictionary *dict = gInfos[g];
        if ([[dict valueForKey:KEY_PLAYING] boolValue]) {
            [[DispatchCenter sharedDispatchCenter] sendPlaybackCmd:FOSNVRPBCMD_SEEK
                                                             value:(int)t
                                                         forDevice:[dict valueForKey:KEY_DEVICE]];
        }
    }
}

- (void)sendCmd :(FOSNVR_PBCMD)cmd value :(int)val
{
    for (NSDictionary *gInfo in self.ttvGroupInfos) {
        if ([[gInfo valueForKey:KEY_PLAYING] boolValue]) {
            [[DispatchCenter sharedDispatchCenter] sendPlaybackCmd:cmd
                                                             value:val
                                                         forDevice:[gInfo valueForKey:KEY_DEVICE]];
        }
    }
}


- (void)performSlow
{
    if (self.isPlaying) {
        FOSNVR_PBCMD cmd = FOSNVRPBCMD_SLOWPLAY;
        int value = 1;
        
        if (self.ratio < 0) {
            self.ratio = 1/2.0;
            cmd = FOSNVRPBCMD_SLOWPLAY;
            value = 2;
        }
        else if (self.ratio <= 1.0) {
            float tmp = self.ratio / 2;
            self.ratio = (tmp < (1.0/32))? 1.0 : tmp;
            cmd = FOSNVRPBCMD_SLOWPLAY;
            value = 1/self.ratio;
        }
        else if (self.ratio == 4.0) {
            self.ratio = 1.0;
            cmd = FOSNVRPBCMD_FASTPLAY;
            value = 1;
        }
        else if (self.ratio > 4.0) {
            self.ratio /= 2;
            cmd = FOSNVRPBCMD_FASTPLAY;
            value = self.ratio;
        }
        [self sendCmd:cmd value:value];
    }
}

- (void)performFast
{
    if (self.isPlaying) {
        FOSNVR_PBCMD cmd = FOSNVRPBCMD_FASTPLAY;
        int value = 1;
        
        if (self.ratio < 0 || self.ratio == 1.0) {
            self.ratio = 4.0;
            cmd = FOSNVRPBCMD_FASTPLAY;
            value = 4;
        }
        else if (self.ratio < 1.0) {
            self.ratio *= 2;
            cmd = FOSNVRPBCMD_SLOWPLAY;
            value = 1/self.ratio;
        }
        else {
            float tmp = self.ratio * 2;
            self.ratio = (tmp > 32.0)?1.0 : tmp;
            cmd = FOSNVRPBCMD_FASTPLAY;
            value = self.ratio;
        }
        [self sendCmd:cmd value:value];
    }
}


- (void)performBack
{
    if (self.isPlaying) {
        int value = 4;
        if (self.ratio > 0) {
            self.ratio = -4;
            
        }
        else {
            float tmp = 2 * self.ratio;
            self.ratio = (fabs(tmp) > 32.0)? 1.0 : tmp;
        }
        
        value = fabs(self.ratio);
        [self sendCmd:FOSNVRPBCMD_BACKPLAY value:value];
    }
}

- (void)performDownload
{
    NSMutableArray *fileInfos = [[NSMutableArray alloc] init];
    
    for (NSArray *group in self.ttvContents) {
        for (NSDictionary *dict in group) {
            NSArray *nodes = [dict valueForKey:KEY_FILE_INFOS];
            Channel *ch = [dict valueForKey:KEY_CH];
            
            for (NSValue *nodeVal in nodes) {
                NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
                [info setValue:ch.device forKey:KEY_DEV];
                [info setValue:nodeVal forKey:KEY_NODE];
                [fileInfos addObject :info];
            }
        }
    }
    [self.downloadMVC setRecordFilesInfo:fileInfos];
    [self.downloadMVC.window makeKeyAndOrderFront:self];
}

#pragma mark - tab view delegate
- (BOOL)shouldRespondHitTestForView :(NSView *)view
{
    AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    return !appDelegate.isAppLocked;
}

#pragma mark - dispatch center protocol
- (void)didRecivedData:(void *)bytes
                length:(int)lenght
                  type:(int)type
             timeStamp:(double)timeStamp
             channelId:(int)channel_id
            streamType:(FOSSTREAM_TYPE)streamType
{
    //更新时间进度
    dispatch_async(dispatch_get_main_queue(), ^{
        for (int g = 0; g < self.ttvContents.count; g++) {
            for (NSDictionary *dict in self.ttvContents[g]) {
                if ([(Channel *)[dict valueForKey:KEY_CH] uniqueId] == channel_id) {
                    [self.progress setValue:[NSDate dateWithTimeIntervalSince1970:timeStamp]
                                     forKey:[NSString stringWithFormat:@"%d",g]];
                    break;
                }
            }
        }
    });
}
#pragma mark - private api
- (int)fitPageSizeForChannelCount :(int)count
{
    NSArray *availablePageSize = [MultyVideoViewsManager validPageSize];
    for (NSNumber *pageSize in availablePageSize)
        if (count <= pageSize.intValue) return pageSize.intValue;
    
    return 1;
}

#pragma mark - uninit
- (void)uninit
{
    DispatchCenter *center = [DispatchCenter sharedDispatchCenter];
    
    [center removePBObserver:self];
    [center removePBObserver:self.multyVideoViewsManager];
    
    self.multyVideoViewsManager.delegate = nil;
}

#pragma mark - getter and setter
- (MultyVideoViewsManager *)multyVideoViewsManager
{
    if (!_multyVideoViewsManager) {
        _multyVideoViewsManager =
        [[MultyVideoViewsManager alloc] initWithNibName:@"MultyVideoViewManager" bundle:[NSBundle mainBundle]];
        //组装
        for (int port = 0; port < 4; port++) {
            VideoViewController *videoViewController =
            [[VideoViewController alloc] initWithNibName :@"JFVideoView"
                                                  bundle :nil
                                                   viewId:port
                                                    type :AVPLAY_TYPE_FILE];
            
            
            [_multyVideoViewsManager addVideoViewController:videoViewController];
        }
        
        [[DispatchCenter sharedDispatchCenter] addPBObserver:_multyVideoViewsManager];
        [_multyVideoViewsManager setPageSize :4];
        [_multyVideoViewsManager setDelegate:self];
    }
    
    return _multyVideoViewsManager;
}

- (NSArray *)olvContents
{
    if (!_olvContents) {
        Group               *group = [[Group alloc] initWithUniqueId:-1 name:@"NVR" type:0 remark:@""];
        VMSDatabase         *db = [VMSDatabase sharedVMSDatabase];
        NSArray             *devices = [db fetchDevicesWithType:NVR];
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        
        
        for (CDevice *device in devices) {
            [db fetchChannelsWithDevice:device];
            
            for (Channel *c in device.children) {
                NSString *cKey = [NSString stringWithFormat:@"%d",c.uniqueId];
                [dict setValue:[[NvrPbChannelState alloc] init] forKey:cKey];
            }
        }
        
        [group.children addObjectsFromArray:devices];
        _olvContents = [NSArray arrayWithObject:group];
        _olvChannelStates = [NSDictionary dictionaryWithDictionary:dict];
    }
    
    return _olvContents;
}

- (NSMutableDictionary *)progress
{
    if (!_progress) {
        _progress = [[NSMutableDictionary alloc] init];
    }
    
    return _progress;
}

- (void)setDatePicker:(TFDatePicker *)datePicker
{
    _datePicker = datePicker;
    [_datePicker setDateValue:[NSDate date]];
}

- (void)setTimeTableView:(TimeTableView *)timeTableView
{
    _timeTableView = timeTableView;
    _timeTableView.backgroundColor = [NSColor gridColor];
    _timeTableView.delegate = self;
}

- (void)setTtvContents:(NSArray *)ttvContents
{
    _ttvContents = ttvContents;
    [self.timeTableView reloadData];
}

- (RecordFileDownloadWindowController *)downloadMVC
{
    if (!_downloadMVC) {
        
        _downloadMVC = [[RecordFileDownloadWindowController alloc] initWithWindowNibName:@"RecordFileDownloadWindowController"];
    }
    
    return _downloadMVC;
}

- (void)setRatio:(float)ratio
{
    _ratio = ratio;
    NSString *symbol = (_ratio > 0)? @">>":@"<<";
    if (fabs(_ratio) >= 1.0) {
        [self.ratioTF setStringValue:[NSString stringWithFormat:@"%@%dx",symbol,(int)fabs(_ratio)]];
    }
    else {
        [self.ratioTF setStringValue:[NSString stringWithFormat:@"%@1/%dx",symbol,(int)(1/fabs(_ratio))]];
    }
}

- (void)setPlaying:(BOOL)playing
{
    _playing = playing;
    
    if (_playing) {
        [self.playButton setImage:[NSImage imageNamed:@"Pause Off"]];
        [self.playButton setAlternateImage:[NSImage imageNamed:@"Pause On"]];
        [self.ttvTimer invalidate];
        self.ttvTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                         target:self
                                                       selector:@selector(updateTimeTableUIAction:)
                                                       userInfo:nil
                                                        repeats:YES];
    }
    else {
        [self.playButton setImage:[NSImage imageNamed:@"Play Off"]];
        [self.playButton setAlternateImage:[NSImage imageNamed:@"Play On"]];
        [self.ttvTimer invalidate];
        self.ttvTimer = nil;
    }
}

- (void)setPausing:(BOOL)pausing
{
    _pausing = pausing;
    if (_pausing) {
        [self.playButton setImage:[NSImage imageNamed:@"Play Off"]];
        [self.playButton setAlternateImage:[NSImage imageNamed:@"Play On"]];
    }
    else {
        [self.playButton setImage:[NSImage imageNamed:@"Pause Off"]];
        [self.playButton setAlternateImage:[NSImage imageNamed:@"Pause On"]];
    }
}

- (void)setSearching:(BOOL)searching
{
    if (searching) {
        [self.searchVideoSpin setHidden:NO];
        [self.searchVideoSpin startAnimation:self];
    }
    else {
        [self.searchVideoSpin stopAnimation:self];
        [self.searchVideoSpin setHidden:YES];
    }
}

- (void)setSearchVideoSpin:(NSProgressIndicator *)searchVideoSpin
{
    _searchVideoSpin = searchVideoSpin;
    _searchVideoSpin.hidden = YES;
}

- (void)setRatioTF:(NSTextField *)ratioTF
{
    _ratioTF = ratioTF;
    _ratioTF.stringValue = @"";
}
@end
