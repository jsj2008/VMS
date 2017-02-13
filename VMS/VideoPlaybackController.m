//
//  VideoPlaybackController.m
//  VMS
//
//  Created by mac_dev on 15/6/2.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "VideoPlaybackController.h"

#define KEY_TTV_NODES                       @"ttv_nodes"
#define NIB_JFSPLIT_VIEW                    @"JFSplitView"
#define ID_CHECK_BOX_CELL                   @"checkbox cell"
#define ID_TEXT_CELL                        @"text cell"
#define ID_SELECT_ALL                       @"select all"
#define ID_PLAYBACK_TABLEVIEW               @"playback tableview"
#define ID_TABLEVIEW_STATE_COLUMN           @"state column"
#define ID_TABLEVIEW_DEVICE_COLUMN          @"device column"
#define ID_TABLEVIEW_NUMBER_COLUMNE         @"number column"

#define KEY_CHECKED                         @"checked"
#define KEY_VIDEO_FILE_INFO                 @"videoFileInfo"
#define SECS_PER_DAY                        (24.0*60*60)
#define MAX_PLAY_CHANNEL_COUNT              4

#define debug   0

@implementation ChannelPlaybackInfo

- (id)init
{
    if (self = [super init]) {
        self.port = -1;
    }
    
    return self;
}

@end


@interface VideoPlaybackController ()

@property (nonatomic,strong) NSMutableArray *tableViewContents;
/*-------------------------------
 *checked       |channel        |
 *-------------------------------
 *NSNumber      |Channel        |
 *-------------------------------
 *KEY_CHECKED   |KEY_CHANNEL    |
 */
@property (nonatomic,strong) NSArray *timeTableContents;
/*---------------------------------------------------
 *checked       |channel        |dateRanges         |
 *---------------------------------------------------
 *NSNumber      |Channel        |NSArray            |
 *---------------------------------------------------
 *KEY_CHECKED   |KEY_CHANNEL    |KEY_DATE_RANGES    |
 */

/*----KEY_DATE_RANGES----
 *begin     |end        |
 *-----------------------
 *NSDate    |NSDate     |
 *-----------------------
 *KEY_BEGIN |KEY_END    |
 */
@property (nonatomic,strong) NSMutableDictionary *channelMap;
@property (nonatomic,strong) NSAlert *playbackAlert;
@property (nonatomic,strong) NSDate *beginDate;//视频播放起始时间,该时间由用户修改
//@property (nonatomic,strong) NSDate *baseDate;
//@property (nonatomic,assign) CGFloat momentOffset;
@property (nonatomic,weak) IBOutlet NSProgressIndicator *indicator;
@property (nonatomic,assign) BOOL activie;
@property (nonatomic,strong) NSTimer *ttvTimer;
@property (nonatomic,weak) IBOutlet JFButton *playButton;
@property (nonatomic,weak) IBOutlet JFButton *nextFrameButton;

@property (nonatomic,weak) IBOutlet JFBackground *scheduleRecordIndicator;
@property (nonatomic,weak) IBOutlet JFBackground *manualRecordIndicator;
@property (nonatomic,weak) IBOutlet JFBackground *alarmRecordIndicator;
@property (nonatomic,weak) IBOutlet NSTextField *speedIndicator;

@end


@implementation VideoPlaybackController

#pragma mark - alert
- (void)PLAYBACK_ALERT :(NSString *)INFO
{
    do {
        if (!self.playbackAlert) {
            NSAlert *alert = [[NSAlert alloc] init];
            
            alert.messageText = INFO;
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

#pragma mark - public api
- (NSMutableArray *)selectedChannelsFromTVContents :(NSArray *)contents
{
    NSMutableArray *selectedChannels = [[NSMutableArray alloc] init];
    
    for (NSDictionary *dict in contents) {
        BOOL checked = [[dict valueForKey:KEY_CHECKED] boolValue];
        Channel *channel = [dict valueForKey:KEY_CHANNEL];
        
        if (checked) {
            [selectedChannels addObject:channel];
        }
    }
    
    return selectedChannels;
}

- (NSArray *)videoTypesFromCheckboxs
{
    NSMutableArray *videoTypes = [[NSMutableArray alloc] init];
    if (self.scheduledVideo.state == NSOnState) [videoTypes addObject:@"0"];
    if (self.manualVideo.state == NSOnState) [videoTypes addObject:@"1"];
    if (self.alarmVideo.state == NSOnState) [videoTypes addObject:@"2"];
    //if (self.motionDetectingVideo.state == NSOnState) [videoTypes addObject:@"3"];
    
    return [NSArray arrayWithArray:videoTypes];
}


- (NSArray *)ptsFromFileInfos :(NSArray *)fileInfos
{
    NSMutableArray *pts = [[NSMutableArray alloc] init];
    
    for (NSDictionary *fileInfo in fileInfos) {
        NSDate  *begin = [fileInfo valueForKey:KEY_DATE_BEGIN];
        NSDate  *end = [fileInfo valueForKey:KEY_DATE_END];
        int     type = [[fileInfo valueForKey:KEY_RECORD_TYPE] intValue];
        
        NSDate *beginOfDay = [begin dateByMovingToBeginningOfDay];
        
        TTV_NODE node;
        
        node.type   = type;
        node.x     = [begin timeIntervalSinceDate:beginOfDay] / SECS_PER_DAY;
        node.y     = [end timeIntervalSinceDate:beginOfDay] / SECS_PER_DAY;
        
        [pts addObject:[NSValue value:&node withObjCType:@encode(TTV_NODE)]];
    }
    
    return [NSArray arrayWithArray:pts];
}



- (NSArray *)fileInfosAtPath :(NSString *)path withDate :(NSDate *)dt types :(NSArray *)types error :(NSError **)err
{
    NSError         *aError = nil;
    NSArray         *files  = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&aError];
    NSMutableArray  *fileInfos = [[NSMutableArray alloc] init];
    
    for (int i = 0; (i < files.count) && !aError; i++) {
        NSString *file = files[i];
        NSInteger type = 0;
        NSDate *begin,*end;
        
        if ([self getVideoType:&type beginDate:&begin endDate:&end fromFileName:file.lastPathComponent]) {
            //解析成功
            //查看日期是否过期或者异常
            if ([types containsObject:[NSString stringWithFormat:@"%ld",type]] &&
                [end compare :begin] == NSOrderedDescending &&
                [dt compare :begin] == NSOrderedAscending &&
                ([end timeIntervalSinceDate:dt] < SEC_PER_DAY)) {
                
                NSMutableDictionary *fileInfo = [[NSMutableDictionary alloc] init];
                [fileInfo setObject:begin forKey:KEY_DATE_BEGIN];
                [fileInfo setObject:end forKey:KEY_DATE_END];
                [fileInfo setObject:[NSNumber numberWithLong:type] forKey:KEY_RECORD_TYPE];
                [fileInfo setObject:[path stringByAppendingPathComponent:file] forKey:KEY_VIDEO_FILE_PATH];
                [fileInfos addObject:fileInfo];
            }
        }
    }
    
    return [NSArray arrayWithArray:fileInfos];
}

- (NSArray *)findVideosWithChannels :(NSArray *)chs
                              types :(NSArray *)types
                               date :(NSDate *)dt
                               path :(NSString *)path
                              error :(NSError **)err
{
    if (chs.count == 0)
        *err = [NSError errorWithDomain:@"com.foscam.vms.playback"
                                   code:-1
                               userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(@"Please select device", nil)}];
    else if (types.count == 0)
        *err = [NSError errorWithDomain:@"com.foscam.vms.playback"
                                   code:-2
                               userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(@"Please select type", nil)}];
    else {
        NSError *aError = nil;
        NSMutableArray *group = [[NSMutableArray alloc] init];
        
        for (int i = 0; (i < chs.count) && !aError; i++) {
            //开始遍历path下的所有文件夹
            Channel             *channel    = chs[i];
            NSFileManager       *manager    = [NSFileManager defaultManager];
            NSArray             *items      = [manager contentsOfDirectoryAtPath:path error:&aError];
            NSString            *prefix     = [NSString stringWithFormat:@"%d_",channel.uniqueId];
            NSMutableDictionary *dict       = [[NSMutableDictionary alloc] init];
            NSMutableArray      *fileInfos  = [[NSMutableArray alloc] init];
            NSMutableArray      *pts        = [[NSMutableArray alloc] init];
            
            for (int j = 0; (j < items.count) && !aError;j++) {
                //判断是否路径与是否包含前缀
                NSString    *item = items[j];
                NSString    *itemPath  = [path stringByAppendingPathComponent:item];
                BOOL        isDirectory = NO;
                
                if ([manager fileExistsAtPath:itemPath isDirectory:&isDirectory] && [item hasPrefix:prefix] && isDirectory) {
                    NSArray *tmp = [self fileInfosAtPath:itemPath withDate:dt types:types error:&aError];
                    
                    [fileInfos addObjectsFromArray:tmp];
                    [pts addObjectsFromArray:[self ptsFromFileInfos:tmp]];
                }
            }
            
            [dict setValue:[NSNumber numberWithBool:NO] forKey:KEY_CHECKED];
            [dict setValue:channel forKey:KEY_CHANNEL];
            [dict setValue:[NSArray arrayWithArray:fileInfos] forKey:KEY_MULTY_VIDEO_FILE_INFO];
            [dict setValue:pts forKey:KEY_TTV_NODES];
            [group addObject:dict];
        }
        
        *err = aError;
        return [NSArray arrayWithArray:group];
    }
    
    return nil;
}

- (void)performFindVideos
{
    BOOL success = NO;
    NSString *msg = nil;
    
    if (self.videoPlayer.isPlaying) {
        msg = NSLocalizedString(@"Please stop playback", nil);
    }
    else {
        NSMutableArray  *channels   = [self selectedChannelsFromTVContents:self.tableViewContents];
        NSArray         *types      = [self videoTypesFromCheckboxs];
        NSDate          *date       = [[self.datePicker dateValue] dateByMovingToBeginningOfDay];
        NSString        *path       = [self videoPath];
        NSError         *err        = nil;
        NSArray         *contents   = [self findVideosWithChannels:channels types:types date:date path:path error:&err];
        
        if (!err) {
            self.beginDate = date;
            self.timeTableContents = [NSArray arrayWithObject:contents];
            success = YES;
        }
        else {
            msg = err.localizedDescription;
        }
    }
    
    if (!success)
        [self PLAYBACK_ALERT:msg];
}

//- (void)performFindVideos
//{
//    if (!self.videoPlayer.isPlaying) {
//        NSMutableArray  *channels   = [self selectedChannelsFromTVContents:self.tableViewContents];
//        NSArray         *types      = [self videoTypesFromCheckboxs];
//        NSDate          *date       = [[self.datePicker dateValue] dateByMovingToBeginningOfDay];
//        NSString        *videoPath  = [self videoPath];
//        NSDateFormatter *formatter  = [[NSDateFormatter alloc] init];
//        
//        
//        if (channels.count == 0) {
//            [self PLAYBACK_ALERT:@"查找录像前，请选中设备!"];
//            return;
//        }
//        
//        if (types.count == 0) {
//            [self PLAYBACK_ALERT:@"查找录像前，请选中录像类型!"];
//            return;
//        }
//        [formatter setDateFormat:@"yyyy-MM-dd_HH-mm-ss"];
//        
//        self.beginDate = date;
//        //时间表内容
//        NSMutableArray *group = [[NSMutableArray alloc] init];
//        
//        for (Channel *channel in channels) {
//            NSMutableArray *multyFileInfo = [[NSMutableArray alloc] init];
//            NSMutableArray *pts = [[NSMutableArray alloc] init];
//            int channelId = (int)channel.uniqueId;
//            NSString *path = [NSString stringWithFormat:@"%@/%d",videoPath,channelId];
//            NSError *err;
//            NSURL *folderUrl = [NSURL URLWithString:path];
//            //这里要考虑文件夹不存在的情况
//            if (debug) NSLog(@"Searching for files at path %@",path);
//            
//            NSFileManager *defaultManager = [NSFileManager defaultManager];
//            if ([defaultManager fileExistsAtPath:folderUrl.path]) {
//                NSArray *fileURLs = [defaultManager contentsOfDirectoryAtURL :folderUrl
//                                                  includingPropertiesForKeys :nil
//                                                                     options :0
//                                                                       error :&err];
//                
//                if (!err) {
//                    for (NSURL *fileUrl in fileURLs) {
//                        //查看文件类型
//                        NSString *file = [fileUrl path];
//                        NSString *fileName = [file lastPathComponent];
//                        NSInteger type = 0;
//                        NSDate *begin,*end;
//                        
//                        if ([self getVideoType:&type beginDate:&begin endDate:&end fromFileName:fileName]) {
//                            //解析成功
//                            //查看日期是否过期或者异常
//                            if ([types containsObject:[NSString stringWithFormat:@"%ld",type]] &&
//                                [end compare :begin] == NSOrderedDescending &&
//                                [date compare :begin] == NSOrderedAscending &&
//                                ([end timeIntervalSinceDate:date] < SEC_PER_DAY)) {
//                                NSMutableDictionary *fileInfo = [[NSMutableDictionary alloc] init];
//                                [fileInfo setObject:begin forKey:KEY_DATE_BEGIN];
//                                [fileInfo setObject:end forKey:KEY_DATE_END];
//                                [fileInfo setObject:file forKey:KEY_VIDEO_FILE_PATH];
//                                [multyFileInfo addObject:fileInfo];
//                                NSDate *beginOfDay = [begin dateByMovingToBeginningOfDay];
//                                [pts addObject:[NSValue valueWithPoint:NSMakePoint([begin timeIntervalSinceDate:beginOfDay] / SECS_PER_DAY,
//                                                                                   [end timeIntervalSinceDate:beginOfDay] / SECS_PER_DAY)]];
//                            }
//                        }
//                    }
//                }
//                else
//                    NSLog(@"查找文件出错:%@",err);
//            }
//            
//            //组装
//            NSMutableDictionary *content = [[NSMutableDictionary alloc] init];
//            [content setObject:[NSNumber numberWithBool:NO] forKey:KEY_CHECKED];
//            [content setObject:channel forKey:KEY_CHANNEL];
//            [content setObject:multyFileInfo forKey:KEY_MULTY_VIDEO_FILE_INFO];
//            [content setObject:pts forKey:KEY_POINTS];
//            //装到大容器内
//            [group addObject:content];
//        }
//        [self setTimeTableContents:[NSArray arrayWithObject:group]];
//    }
//    else {
//        [self PLAYBACK_ALERT:@"查找录像前，请停止当前录像回放!"];
//    }
//}

- (void)performSeekDate
{
    NSDate *time = self.timePicker.dateValue;
    NSDate *dayBeginTime = [time dateByMovingToBeginningOfDay];
    CGFloat position = [time timeIntervalSinceDate:dayBeginTime] / SECS_PER_DAY;
    
    
    //清空数据队列中的数据
    for (NSDictionary *dict in [self.timeTableContents firstObject]) {
        NSString *key = [NSString stringWithFormat:@"%d",((Channel *)[dict valueForKey :KEY_CHANNEL]).uniqueId];
        ChannelPlaybackInfo *info = [self.channelMap valueForKey:key];
        [self.multyVideoViewsManager clearPort:info.port];
    }
    
    NSDate *progress = [NSDate dateWithTimeInterval:position * SECS_PER_DAY sinceDate:self.beginDate];
    
    [self.videoPlayer setSeekDate:progress];
}
#pragma mark - video player notification
- (void)handleVideoPlayerNotification :(NSNotification *)aNotific
{
    //解析通知
    VideoPlayer *sender = aNotific.object;
    
    if (!sender) return;
    if (sender == self.videoPlayer) {
        //调度到主线程进行消息处理
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *name = aNotific.name;
            if ([name isEqualToString:VIDEO_PLAYER_WILL_PLAY_NOTIFICATION]) {
                //Do something here;
            } else if ([name isEqualToString:VIDEO_PLAYER_WILL_PAUSE_NOTIFICATION]) {
                [self.playButton setImage:[NSImage imageNamed:@"Play Off"]];
                [self.playButton setAlternateImage:[NSImage imageNamed:@"Play On"]];
            } else if ([name isEqualToString:VIDEO_PLAYER_DID_RUSUME_NOTIFICATION]) {
                //恢复播放按钮状态
                [self.playButton setImage:[NSImage imageNamed:@"Pause Off"]];
                [self.playButton setAlternateImage:[NSImage imageNamed:@"Pause On"]];
            } else if ([name isEqualToString:VIDEO_PLAYER_DID_STOP_NOTIFICATION]) {
                NSMutableDictionary *channelMap = self.channelMap;
                MultyVideoViewsManager *manager = self.multyVideoViewsManager;
                for (NSDictionary *dict in [self.timeTableContents firstObject]) {
                    Channel *channel = [dict valueForKey :KEY_CHANNEL];
                    NSString *identifier = [NSString stringWithFormat:@"%d",channel.uniqueId];
                    ChannelPlaybackInfo *info = [channelMap valueForKey:identifier];
                    [manager setView:info.port group:nil channel:nil];
                }
                
                //恢复激活
                [self setActivie:YES];
                //恢复按钮状态
                [self.playButton setImage:[NSImage imageNamed:@"Play Off"]];
                [self.playButton setAlternateImage:[NSImage imageNamed:@"Play On"]];
                //结束定时器
                [self.ttvTimer invalidate];
                //[self updatePlayerSpeed:1.f];
            } else if ([name isEqualToString:VIDEO_PLAYER_SPEED_DID_CHANGE_NOTIFICATION]) {
                [self updatePlayerSpeed:sender.speed];
            }
        });
    }
}

- (void)updatePlayerSpeed :(double)speed
{
    if (speed >= 1.f) {
        self.speedIndicator.stringValue = [NSString stringWithFormat:@">>%dx",(int)speed];
    }
    else {
        assert(speed != 0);
        self.speedIndicator.stringValue = [NSString stringWithFormat:@">>1/%dx",(int)(1.0 / speed)];
    }
}

#pragma mark - time table delegate
- (NSUInteger)numberOfGroupInTimeTable :(NSView *)view
{
    return self.timeTableContents.count;
}

- (NSUInteger)numberOfRowAtGroupIdx :(NSUInteger)idx inTimeTableView :(NSView *)view
{
    return [self.timeTableContents[idx] count];
}

- (BOOL)timeTableView :(NSView *)view shouldCheckGroup :(NSUInteger)g row :(NSUInteger)r
{
    NSDictionary *dictForTimetableRow = [self.timeTableContents[g] objectAtIndex:r];
    return [[dictForTimetableRow objectForKey:KEY_CHECKED] boolValue];
}

- (NSString *)timeTableView :(NSView *)view titleForGroup :(NSUInteger)g row :(NSUInteger)r
{
    NSDictionary *dict = [self.timeTableContents[g] objectAtIndex:r];
    Channel *channel = [dict objectForKey:KEY_CHANNEL];
    return channel.name;
}

- (NSArray *)timeTableView :(NSView *)view dateRangesForGroup :(NSUInteger)g row :(NSUInteger)r
{
    NSDictionary *dictForTimetableRow = [self.timeTableContents[g] objectAtIndex:r];
    return [dictForTimetableRow valueForKey:KEY_TTV_NODES];
}

- (BOOL)shouldHittedTimeTableView :(NSView *)view
{
    return self.activie;
}

- (void)selectionDidChangeNotification :(NSNotification *)aNotific
{
    NSUInteger g = [[aNotific.userInfo valueForKey:KEY_GROUP] unsignedIntegerValue];
    NSUInteger r = [[aNotific.userInfo valueForKey:KEY_ROW] unsignedIntegerValue];
    if (g < self.timeTableContents.count) {
        NSMutableDictionary *dict = [self.timeTableContents[g] objectAtIndex:r];
        BOOL checked = [[dict valueForKey:KEY_CHECKED] boolValue];
        
        if (checked) {
            [dict setObject:[NSNumber numberWithBool:NO] forKey:KEY_CHECKED];
        } else {
            //查看选中通道数是否已经达到上限
            NSInteger selectedChannelsCount = 0;
            for (NSDictionary *d in [self.timeTableContents firstObject]) {
                if ([[d valueForKey:KEY_CHECKED] boolValue]) {
                    ++selectedChannelsCount;
                }
            }
        
            if (selectedChannelsCount < MAX_PLAY_CHANNEL_COUNT)
                [dict setObject:[NSNumber numberWithBool:YES] forKey:KEY_CHECKED];
            else
                [self PLAYBACK_ALERT:NSLocalizedString(@"Maximum support 4 channel playback", nil)];
        }
        [aNotific.object setNeedsDisplay:YES];
    }
}

- (void)positionDidChangeNotification :(NSNotification *)aNotific
{
    //用户选择了某一播放时刻，更新视频播放起始时间
    //并通知给播放器
    //清空数据队列中的数据
    for (NSDictionary *dict in self.timeTableContents[0]) {
        NSString *key = [NSString stringWithFormat:@"%d",((Channel *)[dict valueForKey :KEY_CHANNEL]).uniqueId];
        ChannelPlaybackInfo *info = [self.channelMap valueForKey:key];
        [self.multyVideoViewsManager clearPort:info.port];
    }
    
    CGFloat position = [self.timeTableView positionOfGroup:0];
    NSDate *progress = [NSDate dateWithTimeInterval:position * SECS_PER_DAY sinceDate:self.beginDate];
    
    [self.videoPlayer setSeekDate:progress];
}

#pragma mark - life cycle
- (void)dealloc
{
    NSLog(@"Running in %@,'%@'",self.className,NSStringFromSelector(_cmd));
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)onViewLoad
{
    [self setActivie:YES];
    [self setupIndicators];
    [self setupMultyVideoViewsManager];
    [self registObserver];
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

- (void)registObserver
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(handleVideoPlayerNotification:)
                   name:VIDEO_PLAYER_WILL_PLAY_NOTIFICATION
                 object:nil];
    [center addObserver:self
               selector:@selector(handleVideoPlayerNotification:)
                   name:VIDEO_PLAYER_WILL_PAUSE_NOTIFICATION
                 object:nil];
    [center addObserver:self
               selector:@selector(handleVideoPlayerNotification:)
                   name:VIDEO_PLAYER_DID_RUSUME_NOTIFICATION
                 object:nil];
    [center addObserver:self
               selector:@selector(handleVideoPlayerNotification:)
                   name:VIDEO_PLAYER_DID_STOP_NOTIFICATION
                 object:nil];
    [center addObserver:self
               selector:@selector(handleVideoPlayerNotification:)
                   name:VIDEO_PLAYER_SPEED_DID_CHANGE_NOTIFICATION
                 object:nil];
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
    
    [self updatePlayerSpeed:1.f];
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


#pragma mark - action
- (void)updateTimeTableUIAction :(NSTimer *)timer
{
    //获取播放器的进度，更新界面
    NSDate *progressDate = self.videoPlayer.progressDate;
    NSDate *seekDate = self.videoPlayer.seekDate;
    
    if (NSOrderedDescending != [seekDate compare:progressDate]) {
        NSDate *beginOfDay = [progressDate dateByMovingToBeginningOfDay];
        CGFloat position = [progressDate timeIntervalSinceDate:beginOfDay] / SECS_PER_DAY;
        [self.timeTableView setPosition:position ForGroup:0];
    }
}

//- (void)resetPlayDate :(id)sender
//{
//    if ([sender isKindOfClass:[TimeTableView class]]) {
//        TimeTableView *timetable = sender;
//        [self.videoPlayer setSeekDate:timetable.position];
//    }
//}

- (IBAction)tableviewCellAction:(NSButtonCell *)sender {
    NSInteger row = [self.tableView clickedRow];
    
    if (row < self.tableViewContents.count) {
        NSMutableDictionary *dict = self.tableViewContents[row];
        NSNumber *value = [dict valueForKey:KEY_CHECKED];
        BOOL checked = !value.boolValue;
        [dict setValue:[NSNumber numberWithBool:checked] forKey:KEY_CHECKED];
    }
    
    [self.tableView reloadData];
}


- (BOOL)getVideoType :(NSInteger *)type
           beginDate :(NSDate **)beginDate
             endDate :(NSDate **)endDate
        fromFileName :(NSString *)fileName
{
    NSScanner *scanner = [NSScanner scannerWithString:fileName];
    NSString *beginDateStr,*endDateStr;
    
    static NSString *dateFormatter = @"yyyy-MM-dd_HH-mm-ss";
    
    if ([scanner scanInteger:type] &&
        [scanner scanString:@"__" intoString:NULL] &&
        [scanner scanUpToString:@"___" intoString:&beginDateStr] &&
        [scanner scanString:@"___" intoString:NULL] &&
        [scanner scanUpToString:@".vms" intoString:&endDateStr] &&
        [scanner scanString:@".vms" intoString:NULL]) {
        
        *beginDate = [NSDate dateFromString:beginDateStr withFormatter:dateFormatter];
        *endDate = [NSDate dateFromString:endDateStr withFormatter:dateFormatter];
        
        return YES;
    }
    
    return NO;
}

- (IBAction)findVideos:(id)sender
{
    [self performFindVideos];
}

- (IBAction)seekDate:(id)sender
{
    [self performSeekDate];
}
//回放录像控制
- (IBAction)playbackControl:(id)sender
{
    [[[NSApplication sharedApplication] keyWindow] makeFirstResponder:nil];
    
    int tag = (int)[sender tag];
    switch (tag) {
        default:
        case 0://暂停
            break;
        case 1:
            [self performPlayAction];
            break;
        case 2://下一帧
            [self.videoPlayer nextFrame];
            break;
        case 3://停止
            [self.videoPlayer stop];
            break;
        case 4://慢放
            [self.videoPlayer slow];
            break;
        case 5://快放
            [self.videoPlayer fast];
            break;
        case 6:
            if ([self.videoPlayer isPlaying]) {
                [self PLAYBACK_ALERT:NSLocalizedString(@"Please stop playback", nil)];
                break;
            }
            [self performOpenFileAction];
            break;
    }
}

- (void)mouseDown:(NSEvent *)theEvent
{
    VMS_LOCKED_ALERT;
    [super mouseDown:theEvent];
}

#pragma mark - multi video view manager delegate
- (BOOL)shouldEnterSingleWnd
{
    //获取到正在播放的窗口，查看是否正在播放
    MultyVideoViewsManager  *manager        = [self multyVideoViewsManager];
    int                     viewId            = [manager selectedViewId];
    
    return ![manager isFreeView:viewId];
}
#pragma mark - private method
- (void)performPlayAction
{
    //添加用户勾选的通道
    VideoPlayer *videoPlayer = self.videoPlayer;
    MultyVideoViewsManager *manager = self.multyVideoViewsManager;
    
    if (![videoPlayer isPlaying]) {
        //修改起始时间
       
        int selectedChannelCount = 0;//纪录用户勾选的通道数.
        for (NSDictionary *dict in [self.timeTableContents firstObject]) {
            BOOL    checked             = [[dict valueForKey:KEY_CHECKED] boolValue];
            Channel *channel            = [dict valueForKey:KEY_CHANNEL];
            NSArray *multyVideoFileInfo = [dict valueForKey:KEY_MULTY_VIDEO_FILE_INFO];
            
            if (!checked) continue;
            selectedChannelCount++;
            if (multyVideoFileInfo.count > 0) {
                NSString *key = [NSString stringWithFormat:@"%d",channel.uniqueId];
                ChannelPlaybackInfo *info = [self.channelMap valueForKey:key];
                [videoPlayer addChannelWithId :channel.uniqueId multyVideoFileInfo:multyVideoFileInfo];
                //适配一个播放窗口
                int viewId = [manager freeViewId];
                if (viewId >= 0) {
                    [manager setView:viewId group:nil channel:channel];
                    [manager setView:viewId state:VIDEO_PLAYING];
                    info.port = viewId;
                }
            }
        }
        
        if (selectedChannelCount > 0) {
            [self.multyVideoViewsManager setPageSize:[self fitPageSizeForChannelCount:selectedChannelCount]];
            if ([videoPlayer play]) {
                [self.playButton setImage:[NSImage imageNamed:@"Pause Off"]];
                [self.playButton setAlternateImage:[NSImage imageNamed:@"Pause On"]];
                self.ttvTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                                 target:self
                                                               selector:@selector(updateTimeTableUIAction:)
                                                               userInfo:nil
                                                                repeats:YES];
            }
        } else {
            [self PLAYBACK_ALERT:NSLocalizedString(@"Unchecked", nil)];
        }
        
    } else if ([videoPlayer isPausing]) {
        [videoPlayer resume];
    } else {
        [videoPlayer pause];
    }
}

- (int)fitPageSizeForChannelCount :(int)count
{
    NSArray *availablePageSize = [MultyVideoViewsManager validPageSize];
    for (NSNumber *pageSize in availablePageSize)
        if (count <= pageSize.intValue) return pageSize.intValue;
    
    return 1;
}

- (void)performOpenFileAction
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    
    [openPanel setDelegate:self];
    [openPanel setDirectoryURL:[NSURL URLWithString:[self videoPath]]];
    [openPanel setAllowsMultipleSelection:NO];
  
    if ([openPanel runModal] == NSModalResponseOK) {
        NSString        *path   = [[[openPanel URLs] objectAtIndex:0] path];
        VideoFileReader *reader = [[VideoFileReader alloc] initWithFilePath :path];
        
        [reader open];
        NSDate *begin = [reader begin];
        NSDate *end = [reader end];
        int type = [reader type];
        NSDate *beginOfDay = [begin dateByMovingToBeginningOfDay];
        Channel *channel = [reader channel];
        
        self.timeTableContents = nil;
        NSMutableArray *group = [[NSMutableArray alloc] init];
        if (begin && end && channel) {
            
            NSMutableDictionary *fileInfo = [[NSMutableDictionary alloc] init];
            [fileInfo setObject :begin forKey:KEY_DATE_BEGIN];
            [fileInfo setObject :end forKey:KEY_DATE_END];
            [fileInfo setObject :path forKey:KEY_VIDEO_FILE_PATH];
            
            TTV_NODE ttvNode;
            
            ttvNode.type = type;
            ttvNode.x = [begin timeIntervalSinceDate:beginOfDay] / SEC_PER_DAY;
            ttvNode.y = [end timeIntervalSinceDate:beginOfDay] / SEC_PER_DAY;
            
            NSMutableDictionary *content = [[NSMutableDictionary alloc] init];
            [content setObject:[NSNumber numberWithBool:NO] forKey:KEY_CHECKED];
            [content setObject:channel forKey:KEY_CHANNEL];
            [content setObject:[NSMutableArray arrayWithObject:fileInfo] forKey:KEY_MULTY_VIDEO_FILE_INFO];
            [content setObject:[NSArray arrayWithObject:[NSValue value:&ttvNode withObjCType:@encode(TTV_NODE)]] forKey:KEY_TTV_NODES];
            [group addObject:content];
           
        }
        
        [self setTimeTableContents:[NSArray arrayWithObject:group]];
        [self.timeTableView setNeedsDisplay :YES];
        [self setBeginDate:[begin dateByMovingToBeginningOfDay]];
    }
}

#pragma mark - NSOpenPanel Delegate
- (BOOL)panel:(id)sender shouldEnableURL:(NSURL *)url
{
    NSNumber *isDirectory;
    NSError *err;
    BOOL success = [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&err];
    
    if (success && !err && [isDirectory boolValue]) {
        return YES;
    }
    
    return [[[url path] pathExtension] isEqualToString:@"vms"];
}
#pragma mark - table view data source
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.tableViewContents.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    ///cell-based table view
    NSString *identifier = tableColumn.identifier;
    NSDictionary *dict = [self.tableViewContents objectAtIndex:row];
    NSNumber *checked = [dict valueForKey:KEY_CHECKED];
    NSString *index = [NSString stringWithFormat:@"%ld",row];
    Channel *channel = [dict valueForKey:KEY_CHANNEL];
    
    id result = nil;
    if ([identifier isEqualToString:ID_TABLEVIEW_STATE_COLUMN]) result = checked;
    else if ([identifier isEqualToString:ID_TABLEVIEW_NUMBER_COLUMNE]) result = index;
    else if ([identifier isEqualToString:ID_TABLEVIEW_DEVICE_COLUMN]) result = channel.name;

    return result;
}

#pragma mark - VMSTabView Delegate
- (BOOL)shouldRespondHitTestForView:(NSView *)view
{
    AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    return !appDelegate.isAppLocked;
}

#pragma mark - table view delegate
- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    ///read only
    return NO;
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectTableColumn:(NSTableColumn *)tableColumn
{
    ///Select a column is prohibited
    return NO;
}

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn
{
    if ([tableView.identifier isEqualToString:ID_PLAYBACK_TABLEVIEW]) {
        NSString *columnID = tableColumn.identifier;
        if ([columnID isEqualToString:ID_TABLEVIEW_STATE_COLUMN]) {
            CheckboxHeaderCell *mHeaderCell = [tableColumn headerCell];
            BOOL state = [mHeaderCell getState];
            [mHeaderCell onClick];
            for (NSMutableDictionary *dict in self.tableViewContents) {
                
                if ([dict objectForKey:KEY_CHECKED]) {
                    [dict setValue:[NSNumber numberWithBool:!state] forKey:KEY_CHECKED];
                }
            }
            [self.tableView reloadData];
        }
    }
}


#pragma mark - tab mvc protocol
- (void)willTab :(NSNotification *)aNotific stop :(BOOL *)stop
{
    if (self.videoPlayer.isPlaying) {
        [self PLAYBACK_ALERT:NSLocalizedString(@"Please stop playback", nil)];
        *stop = YES;
    }
}

#pragma mark - getter and setter
- (MultyVideoViewsManager *)multyVideoViewsManager
{
    if (!_multyVideoViewsManager) {
       
        _multyVideoViewsManager = [[MultyVideoViewsManager alloc] initWithNibName:@"MultyVideoViewManager" bundle:[NSBundle mainBundle]];
        //组装
        for (int port = 0; port < 4; port++) {
            VideoViewController *videoViewController =
            [[VideoViewController alloc] initWithNibName :@"JFVideoView"
                                                  bundle :nil
                                                   viewId:port
                                                    type :AVPLAY_TYPE_FILE];
            
            [_multyVideoViewsManager addVideoViewController:videoViewController];
        }
        
        [self.videoPlayer addObserver:_multyVideoViewsManager];
        [_multyVideoViewsManager setPageSize :4];
        [_multyVideoViewsManager setDelegate:self];
    }
    
    return _multyVideoViewsManager;
}

- (NSMutableArray *)tableViewContents
{
    if (!_tableViewContents) {
        //重数据库中取回通道信息
        //首先取回所有设备
        VMSDatabase *database = [VMSDatabase sharedVMSDatabase];
        NSArray *devices = [database fetchDevices];
        
        //从设备中取回所有通道
        _tableViewContents = [[NSMutableArray alloc] init];
        for (CDevice *device in devices) {
            NSArray *channels = [database fetchChannelsWithDevice:device];
            for (Channel *channel in channels) {
                NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                [dict setValue :[NSNumber numberWithBool:NO] forKey:KEY_CHECKED];
                [dict setValue :channel forKey:KEY_CHANNEL];
                [_tableViewContents addObject:dict];
            }
        }
    }
    
    return _tableViewContents;
}

- (void)setTableView:(NSTableView *)tableView
{
    _tableView = tableView;
    
    //自定义的头空间Cell,用于绘制Checkbox
    CheckboxHeaderCell *mHeaderCell = [[CheckboxHeaderCell alloc] init];
    [mHeaderCell setBordered:YES];
    
    //替换新的头控件单元
    NSTableColumn *checkboxColumn = [_tableView tableColumnWithIdentifier:ID_TABLEVIEW_STATE_COLUMN];
    [checkboxColumn setHeaderCell:mHeaderCell];
}

- (void)setFindVideos:(NSButton *)findVideos
{
    _findVideos = findVideos;
    [_findVideos setTitleColor:[NSColor highlightColor]];
}

- (void)setSeekVideos:(NSButton *)seekVideos
{
    _seekVideos = seekVideos;
    [_seekVideos setTitleColor:[NSColor highlightColor]];
}

- (void)setSeekVideosZone:(JFBackground *)seekVideosZone
{
    _seekVideosZone = seekVideosZone;
    NSColor *color = [NSColor colorWithCalibratedRed:235/255.0 green:237/255.0 blue:240/255.0 alpha:1];
    [_seekVideosZone setBackgroundColor:color];
}

- (void)setTimeTableView:(TimeTableView *)timeTableView
{
    _timeTableView = timeTableView;
    [_timeTableView setBackgroundColor:[NSColor gridColor]];
    [_timeTableView setSelectable:YES];
}

- (void)setTimeTableContents:(NSArray *)timeTableContents
{
    _timeTableContents = timeTableContents;
    [self.timeTableView reloadData];
}

- (void)setDatePicker:(TFDatePicker *)datePicker
{
    _datePicker = datePicker;
    [_datePicker setDateValue:[NSDate date]];
}

- (VideoPlayer *)videoPlayer
{
    if (!_videoPlayer) {
        _videoPlayer = [[VideoPlayer alloc] init];
    }
    
    return _videoPlayer;
}

- (NSMutableDictionary *)channelMap
{
    if (!_channelMap) {
        _channelMap = [[NSMutableDictionary alloc] init];
        
        //首先取回所有设备
        VMSDatabase *db = [VMSDatabase sharedVMSDatabase];
        NSArray *devices = [db fetchDevices];
        //从设备中取回所有通道
        for (CDevice *device in devices) {
            NSArray *channels = [db fetchChannelsWithDevice:device];
            for (Channel *channel in channels) {
                NSString *key = [NSString stringWithFormat:@"%d",channel.uniqueId];
                ChannelPlaybackInfo *info = [[ChannelPlaybackInfo alloc] init];
                
                [_channelMap setValue :info forKey:key];
            }
        }
    }
    
    return _channelMap;
}

- (NSString *)videoPath
{
    NSString *path = [VMSPathManager vmsConfPath:YES];
    VMSRecordSetting *recordSetting = [[VMSRecordSetting alloc] initWithPath:path];
    return [recordSetting.recordingPathName stringByAppendingPathComponent:RECORD_FILE_FOLDER];
}

- (NSDate *)beginDate
{
    if (!_beginDate) {
        _beginDate = [[NSDate date] dateByMovingToBeginningOfDay];
    }
    
    return _beginDate;
}

- (void)setActivie:(BOOL)activie
{
    _activie = activie;
    if (activie)
        [self.indicator stopAnimation:self];
    else
        [self.indicator startAnimation:self];
    
    
    [self.indicator setHidden:activie];
}

- (void)setNextFrameButton:(JFButton *)nextFrameButton
{
    _nextFrameButton = nextFrameButton;
    _nextFrameButton.keyEquivalent = @"f";
}

@end
