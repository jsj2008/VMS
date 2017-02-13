//
//  SystemTimeViewController.m
//  
//
//  Created by mac_dev on 16/5/23.
//
//

#import "SystemTimeViewController.h"
#import "TFDatePickerPopoverController.h"

@interface SystemTimeViewController ()

@property (nonatomic,strong) NSDate *clockDate;
@property (nonatomic,weak) IBOutlet NSPopUpButton *timeZoneBtn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *dateFormatBtn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *timeFormatBtn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *ntpServerBtn;
@property (nonatomic,assign) BOOL ntpEnable;
@property (nonatomic,assign) BOOL shouldUpdateClockTime;
@property (nonatomic,weak) IBOutlet NSPopUpButton *hourBtn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *minutesBtn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *secondBtn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *ampmBtn;
@property (nonatomic,weak) IBOutlet NSButton *date;
@property (nonatomic,strong) TFDatePickerPopoverController *datePickerPopoverController;
@property (nonatomic,assign) BOOL dstEnable;
@property (nonatomic,weak) IBOutlet NSPopUpButton *dstBtn;

@property (nonatomic,assign) int dst;

@end

@implementation SystemTimeViewController

#pragma mark - public api
- (BOOL)gmt
{
    return NO;
}

- (void)fetch
{
    [self setActivity:YES];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FOSCAM_NET_CONFIG config;
        FOS_DEVSYSTEMTIME devSystemTime;
        config.info = &devSystemTime;
        BOOL success = [[DispatchCenter sharedDispatchCenter] getConfig:&config
                                                                forType:FOSCAM_NET_CONFIT_DEVICE_SYSTEM_TIME
                                                             fromDevice:self.device];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                //这里板端有一处bug,所有的字段都为-1,需要重取
                static BOOL isBug = NO;
                
                if (devSystemTime.year == -1) {
                    
                    if (isBug) {
                        isBug = NO;
                        [self alert:NSLocalizedString(@"failed to get the settings", nil)
                               info:NSLocalizedString(@"time out",nil)];
                    }
                    else {
                        isBug = YES;
                        [self fetch];
                        return;
                    }
                }
                else {
                    isBug = NO;
                    [self setDeviceSystemTime:devSystemTime];
                    [self.timeUpdate fire];
                }
            }
            else
                [self alert:NSLocalizedString(@"failed to get the settings", nil)
                       info:NSLocalizedString(@"time out",nil)];
            
            [self setActivity:NO];
        });
    });
}

- (void)push
{
    [self setActivity:YES];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FOSCAM_NET_CONFIG config;
        FOS_DEVSYSTEMTIME sysTime = [self devSysTimeFromUI];
        config.info = &sysTime;
        BOOL success = [[DispatchCenter sharedDispatchCenter] setConfig:&config
                                                                forType:FOSCAM_NET_CONFIT_DEVICE_SYSTEM_TIME
                                                               toDevice:self.device];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success)
                [self fetch];
            else
                [self alert:NSLocalizedString(@"failed to set the settings", nil)
                       info:NSLocalizedString(@"time out", nil)];
            
            [self setActivity:NO];
        });
    });
}

- (NSString *)description
{
    return NSLocalizedString(@"Device Time", nil);
}

- (SVC_OPTION)option
{
    return SVC_REFRESH | SVC_SAVE;
}

#pragma mark - event
- (void)mouseDown:(NSEvent *)event
{
    [super mouseDown:event];
    
    self.shouldUpdateClockTime = YES;
}


#pragma mark - action
- (IBAction)updateClockTimeAction:(id)sender
{
    NSUInteger tag = [sender tag];
    
    switch (tag) {
        case 0://时区
            [self updateClockDateUI];
            [self updateClockTimeUI];
            [self setShouldUpdateClockTime:YES];
            break;
        case 1://时间格式
            [self alterTimeFmt];
            [self updateClockTimeUI];
            [self setShouldUpdateClockTime:YES];
            break;
        case 2://日期格式
            [self updateClockDateUI];
            [self setShouldUpdateClockTime:YES];
            break;
        case 3:
        case 4:
        case 5:
        case 6:
            //h,m,s,ampm
            [self setShouldUpdateClockTime:NO];
            break;
        default:
            break;
    }
    
}

- (IBAction)timeUpdate :(NSTimer *)sender
{
    //更新时钟Date，更新界面
    self.clockDate = [self.clockDate dateByAddingTimeInterval:1];
    
    if (self.shouldUpdateClockTime) {
        [self updateClockDateUI];
        [self updateClockTimeUI];
    }
}


- (IBAction)selectDate :(id)sender
{
    NSRect          rc          = [sender frame];
    NSDatePicker    *datePicker = self.datePickerPopoverController.datePicker;
    NSInteger       timeZoneIdx = [self.timeZoneBtn indexOfSelectedItem];
    NSInteger       timeOffset  = (-1) * [[self availableTimeZone][timeZoneIdx] integerValue];
    NSTimeZone      *timeZone   = [NSTimeZone timeZoneForSecondsFromGMT:timeOffset];
    
    //初始化datePicker
    [datePicker setTimeZone:timeZone];
    [datePicker setDatePickerElements:NSYearMonthDayDatePickerElementFlag];
    [datePicker setDatePickerMode:NSSingleDateMode];
    [datePicker setDatePickerStyle:NSClockAndCalendarDatePickerStyle];
    [datePicker setDateValue :self.clockDate];
    
    
    //获取当前控件日期
    [self.datePickerPopoverController showDatePickerRelativeToRect:rc
                                                            inView:self.view
                                                  completionHander:^(NSDate *selectedDate)
     {
         //更新时钟
         [self setClockDate:selectedDate];
         //更新控件
         [self updateClockDateUI];
         [self updateClockTimeUI];
     }];
}

- (IBAction)syncPCTerminalTime:(id)sender
{
    NSCalendar  *calendar       = [NSCalendar currentCalendar];
    NSTimeZone  *timeZone       = [calendar timeZone];
    NSInteger   timeZoneOffset  = (-1) * timeZone.secondsFromGMT;
    NSUInteger  timeZoneIdx     = [[self availableTimeZone] indexOfObject:[NSNumber numberWithInteger:timeZoneOffset]];
    if (timeZoneIdx < self.timeZoneBtn.itemArray.count) {
        //更新时区
        [self.timeZoneBtn selectItemAtIndex:timeZoneIdx];
    }
    
    //更新时钟时间
    self.clockDate = [NSDate date];
    
    //更新UI
    [self updateClockTimeUI];
    [self updateClockDateUI];
    
    //取消夏令时
    self.dstEnable = NO;
}

//应用夏令时，单位分钟
- (void)applyDst :(int)dst
{
    self.clockDate = [self.clockDate dateByAddingTimeInterval:dst * 60];
    
    [self updateClockDateUI];
    [self updateClockTimeUI];
}

- (IBAction)dstChange :(id)sender
{
    //recover to no dst
    [self applyDst:(-1) * self.dst];
    
    if (!self.dstEnable)
        self.dst = 0;
    else {
        int dst = (int)self.dstBtn.selectedTag;
        [self applyDst:dst];
        self.dst = dst;
    }
}

#pragma mark - life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.syncIPCTimeBtn.hidden = (self.device.type == IPC);
}

- (void)viewWillDisappear
{
    [self.timeUpdate invalidate];
    [self setTimeUpdate :nil];
}

#pragma mark - private api
- (void)convertGTMToLocal :(FOS_DEVSYSTEMTIME *)devSystemTime
{
    NSDateComponents *src = [[NSDateComponents alloc] init];
    
    src.year = devSystemTime->year;
    src.month = devSystemTime->mon;
    src.day = devSystemTime->day;
    src.hour = devSystemTime->hour;
    src.minute = devSystemTime->minute;
    src.second = devSystemTime->sec;
    src.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    
    
    NSDateComponents *dest = [self convertDateComponents:src toTimezone:[NSTimeZone timeZoneForSecondsFromGMT:(devSystemTime->timeZone) * (-1)]];

    if (devSystemTime) {
        devSystemTime->year = (int)dest.year;
        devSystemTime->mon = (int)dest.month;
        devSystemTime->day = (int)dest.day;
        devSystemTime->hour = (int)dest.hour;
        devSystemTime->minute = (int)dest.minute;
        devSystemTime->sec = (int)dest.second;
    }
}

//当时间格式发生改变时，需要更新界面
- (void)alterTimeFmt
{
    NSUInteger timeFmtIdx = self.timeFormatBtn.indexOfSelectedItem;
    
    switch (timeFmtIdx) {
        case 0://12
            [self setControl:self.hourBtn withRange:[self hour12Range]];
            [self.ampmBtn setHidden:NO];
            break;
        case 1://24
            [self setControl:self.hourBtn withRange:[self hour24Range]];
            [self.ampmBtn setHidden:YES];
            break;
        default:
            break;
    }
    
    [self updateClockTimeUI];
}

- (NSDate *)clockDateFromDevSysTime :(FOS_DEVSYSTEMTIME)devSysTime
{
    NSInteger   timeZoneOffset  = (-1) * devSysTime.timeZone;
    NSTimeZone  *timeZone       = [NSTimeZone timeZoneForSecondsFromGMT:timeZoneOffset];
    NSCalendar  *calendar       = [NSCalendar currentCalendar];
    
    [calendar setTimeZone:timeZone];
    
    return [calendar dateWithEra :1
                            year :devSysTime.year
                           month :devSysTime.mon
                             day :devSysTime.day
                            hour :devSysTime.hour
                          minute :devSysTime.minute
                          second :devSysTime.sec
                      nanosecond :0];
}


- (NSDateComponents *)convertDateComponents :(NSDateComponents *)components
                                 toTimezone :(NSTimeZone *)timezone
{
    if (components) {
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDate *date = [calendar dateFromComponents:components];
        
        if (date) {
            NSCalendarUnit flag =
            NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay |
            NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond|
            NSCalendarUnitTimeZone;
            
            [calendar setTimeZone:timezone];
            
            return [calendar components:flag fromDate:date];
        }
    }
    
    return nil;
}

- (void)getYear :(int *)y
         mounth :(int *)m
            day :(int *)d
 fromDateString :(NSString *)str
    withFormate :(NSUInteger)fmt

{
    NSString    *spliter;
    int         *num[3] = {0};
    
    switch (fmt) {
        default:
        case 0://年-月-日
            spliter = @"-";
            num[0] = y;
            num[1] = m;
            num[2] = d;
            break;
        case 1://日/月/年
            spliter = @"/";
            num[0] = d;
            num[1] = m;
            num[2] = y;
            break;
        case 2://月/日/年
            spliter = @"/";
            num[0] = m;
            num[1] = d;
            num[2] = y;
            break;
    }
    
    NSArray *components = [str componentsSeparatedByString:spliter];
    for (int i = 0; i < components.count; i++) {
        NSString    *component = components[i];
        NSScanner   *scannner = [NSScanner scannerWithString:component];
        
        [scannner scanInt:num[i]];
    }
}

- (NSString *)stringFromYear :(NSInteger)year
                       month :(NSInteger)mon
                         day :(NSInteger)day
                      format :(NSInteger)format
{
    NSString *date = nil;
    switch (format) {
        case 0://年-月-日
            date = [NSString stringWithFormat:@"%ld-%ld-%ld",year,mon,day];
            break;
        case 1://日/月/年
            date = [NSString stringWithFormat:@"%ld/%ld/%ld",day,mon,year];
            break;
        case 2://月/日/年
            date = [NSString stringWithFormat:@"%ld/%ld/%ld",mon,day,year];
            break;
        default:
            break;
    }
    return date;
}

- (NSUInteger)hour24FromHour12 :(NSUInteger)hour12
                          ampm :(NSUInteger)ampm
{
    //说明，这里的number 是0 - 11,传统意义上的12小时制,0刻为12刻
    assert(hour12 < 12);
    assert(hour12 >= 0);
    return ampm * 12 + hour12;
}

- (NSUInteger)hour12FromHour24 :(NSUInteger)hour24
                          ampm :(NSUInteger *)ampm
{
    //说明，这里的number 是0 - 11,传统意义上的12小时制,0刻为12刻
    assert(hour24 < 24);
    assert(hour24 >= 0);
    *ampm = hour24 / 12;
    
    return hour24 % 12;
}

//控件上显示的时间为用户所选中的时区对应的时间，在将参数发送回客户端前，统一转换为GMT时间.
- (FOS_DEVSYSTEMTIME)devSysTimeFromUI
{
    FOS_DEVSYSTEMTIME devSysTime;
    NSUInteger  timeZoneIdx = self.timeZoneBtn.indexOfSelectedItem;
    NSArray     *timeZones  = [self availableTimeZone];
    NSInteger   offset      = (-1) * [timeZones[timeZoneIdx] integerValue];
    NSString    *dateString = self.date.title;
    
    int         y = 0;
    int         M = 0;
    int         d = 0;
    int         dateFmt     = (int)self.dateFormatBtn.indexOfSelectedItem;
    int         timeFmt     = (int)self.timeFormatBtn.indexOfSelectedItem;
    NSString    *ntpServer  = [self.ntpServerBtn titleOfSelectedItem];
    int         h           = (int)self.hourBtn.indexOfSelectedItem;
    int         m           = (int)self.minutesBtn.indexOfSelectedItem;
    int         s           = (int)self.secondBtn.indexOfSelectedItem;
    int         ampm        = (int)self.ampmBtn.selectedTag;
    
    [self getYear:&y mounth:&M day:&d fromDateString:dateString withFormate:dateFmt];
    
    if (timeFmt == 0) {
        h = (ampm == 0)? h : (h+12);
    }
    NSDateComponents *src = [[NSDateComponents alloc] init];
    src.year = y;
    src.month = M;
    src.day = d;
    src.hour = h;
    src.minute = m;
    src.second = s;
    src.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:offset];
    
    NSDateComponents *dest = [self convertDateComponents:src toTimezone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    devSysTime.timeZone     = [timeZones[timeZoneIdx] intValue];
    devSysTime.timeSource   = self.ntpEnable;
    devSysTime.dateFormat   = (int)self.dateFormatBtn.indexOfSelectedItem;
    devSysTime.timeFormat   = (int)self.timeFormatBtn.indexOfSelectedItem;
    devSysTime.year         = (int)dest.year;
    devSysTime.mon          = (int)dest.month;
    devSysTime.day          = (int)dest.day;
    devSysTime.hour         = (int)dest.hour;
    devSysTime.minute       = (int)dest.minute;
    devSysTime.sec          = (int)dest.second;
    devSysTime.isDst        = (int)self.dstEnable;
    devSysTime.dst          = (int)self.dstBtn.selectedTag;
    
    [ntpServer getCString:devSysTime.ntpServer maxLength:FOS_NTPSERVER_LEN encoding:NSASCIIStringEncoding];
    
    return devSysTime;
}

- (void)updateClockDateUI
{
    NSDate              *clockDate      = self.clockDate? self.clockDate : [NSDate date];
    NSUInteger          timeZoneIdx     = self.timeZoneBtn.indexOfSelectedItem;
    NSInteger           timeZoneOffset  = (-1) * [[self availableTimeZone][timeZoneIdx] integerValue];
    NSTimeZone          *timeZone       = [NSTimeZone timeZoneForSecondsFromGMT:timeZoneOffset];
    NSCalendar          *calendar       = [NSCalendar currentCalendar];
    [calendar setTimeZone:timeZone];
    NSCalendarUnit      unit            = NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay ;
    NSDateComponents    *components     = [calendar components:unit fromDate:clockDate];
    NSUInteger          dateFormat      = self.dateFormatBtn.indexOfSelectedItem;
    
    self.date.title = [self stringFromYear:components.year
                                     month:components.month
                                       day:components.day
                                    format:dateFormat];
}

//这里保存一个NSDate *类型成员属性clockDate,开启定时器实时更新该变量，并将其反映到UI上.
- (void)updateClockTimeUI
{
    NSDate              *clockDate      = self.clockDate? self.clockDate : [NSDate date];
    NSUInteger          timeZoneIdx     = self.timeZoneBtn.indexOfSelectedItem;
    NSInteger           timeZoneOffset  = (-1) * [[self availableTimeZone][timeZoneIdx] integerValue];
    NSTimeZone          *timeZone       = [NSTimeZone timeZoneForSecondsFromGMT:timeZoneOffset];
    NSCalendar          *calendar       = [NSCalendar currentCalendar];
    [calendar setTimeZone:timeZone];
    NSCalendarUnit      unit            = NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond;
    NSDateComponents    *components     = [calendar components:unit fromDate:clockDate];
    NSUInteger          timeFormat      = self.timeFormatBtn.indexOfSelectedItem;
    NSUInteger          h = 0;
    NSUInteger          ampm = 0;
    
    switch (timeFormat) {
        case 0://12小时制
            h = [self hour12FromHour24:components.hour ampm:&ampm];
            [self.ampmBtn selectItemWithTag:ampm];
            [self.ampmBtn setHidden:NO];
            break;
        case 1://24小时制
            h = components.hour;
            [self.ampmBtn setHidden:YES];
            break;
        default:
            break;
    }
    
    [self.hourBtn selectItemAtIndex:h];
    [self.minutesBtn selectItemAtIndex:components.minute];
    [self.secondBtn selectItemAtIndex:components.second];
}

- (void)updateDevSystemTimeUI
{
    FOS_DEVSYSTEMTIME   deviceSystemTime    = self.deviceSystemTime;
    
    //时区(从服务器获取的时区时差偏移，符号与Cocoa使用习惯相反，但凡需要使用时区进行计算时，统一添加“－”)
    int                 timeZoneOffset      = deviceSystemTime.timeZone;
    NSUInteger          timeZoneIdx         = [[self availableTimeZone] indexOfObject:[NSNumber numberWithInt:timeZoneOffset]];
    
    if (timeZoneIdx < [self availableTimeZone].count) {
        [self.timeZoneBtn selectItemAtIndex:timeZoneIdx];
    }
    
    //NPT服务器
    NSString            *ntpServer          = [NSString stringWithCString:deviceSystemTime.ntpServer encoding:NSASCIIStringEncoding];
    NSUInteger          ntpServerIdx        = [[self availableTimeServers] indexOfObject:ntpServer];
    if (ntpServerIdx < [self availableTimeServers].count) {
        [self.ntpServerBtn selectItemAtIndex:ntpServerIdx];
    }
    
    //时间源
    self.ntpEnable = deviceSystemTime.timeSource;
    
    [self.dateFormatBtn selectItemWithTag:deviceSystemTime.dateFormat];
    [self.timeFormatBtn selectItemWithTag:deviceSystemTime.timeFormat];
    
    //时钟时间
    [self setShouldUpdateClockTime:YES];
    [self setClockDate:[self clockDateFromDevSysTime:deviceSystemTime]];
    [self alterTimeFmt];
    [self updateClockDateUI];
    [self updateClockTimeUI];
    
    //夏令时
    self.dstEnable = (deviceSystemTime.isDst == 1);
    [self.dstBtn selectItemWithTag:deviceSystemTime.dst];
}


#pragma mark setter & getter
- (void)setDeviceSystemTime:(FOS_DEVSYSTEMTIME)deviceSystemTime
{
    _deviceSystemTime = deviceSystemTime;
    
    if ([self gmt]) {
        [self convertGTMToLocal:&_deviceSystemTime];
    }
    [self updateDevSystemTimeUI];//更新记录
}

- (TFDatePickerPopoverController *)datePickerPopoverController
{
    if (!_datePickerPopoverController) {
        _datePickerPopoverController = [[TFDatePickerPopoverController alloc] init];
    }
    
    return _datePickerPopoverController;
}

- (NSTimer *)timeUpdate
{
    if (!_timeUpdate) {
        _timeUpdate = [NSTimer scheduledTimerWithTimeInterval :1
                                                       target :self
                                                     selector :@selector(timeUpdate:)
                                                     userInfo :nil
                                                      repeats :YES];
    }
    
    return _timeUpdate;
}

- (void)setControl :(NSPopUpButton *)btn withTitles :(NSArray *)titles
{
    [btn removeAllItems];
    for (int i = 0; i < titles.count; i++) {
        NSString *title = titles[i];
        [btn addItemWithTitle:title];
    }
}

- (void)setControl :(NSPopUpButton *)btn withRange :(NSRange)range
{
    [btn removeAllItems];
    for (int i = 0; i < range.length; i++) {
        NSString *title = [NSString stringWithFormat:@"%2lu",range.location + i];
        [btn addItemWithTitle:title];
    }
}

- (void)setTimeZoneBtn:(NSPopUpButton *)timeZoneBtn
{
    _timeZoneBtn = timeZoneBtn;
    [self setControl :_timeZoneBtn withTitles :[self availableTimeZoneNames]];
}

- (void)setNtpServerBtn:(NSPopUpButton *)ntpServerBtn
{
    _ntpServerBtn = ntpServerBtn;
    [self setControl:_ntpServerBtn withTitles:[self availableTimeServers]];
}

- (void)setHourBtn:(NSPopUpButton *)hourBtn
{
    _hourBtn = hourBtn;
    [self setControl:_hourBtn withRange:[self hour24Range]];
}

- (void)setMinutesBtn:(NSPopUpButton *)minutesBtn
{
    _minutesBtn = minutesBtn;
    [self setControl:_minutesBtn withRange:[self minutesRange]];
}

- (void)setSecondBtn:(NSPopUpButton *)secondBtn
{
    _secondBtn = secondBtn;
    [self setControl:_secondBtn withRange:[self secondsRange]];
}

#pragma mark - data for controls
- (NSArray *)availableTimeZoneNames
{
    return @[NSLocalizedString(@"(GMT -12:00) International Date Line West", nil),
             NSLocalizedString(@"(GMT -11:00) Midway Islands, Samoa Islands", nil),
             NSLocalizedString(@"(GMT -10:00) Hawaii", nil),
             NSLocalizedString(@"(GMT -09:00) Alaska Standard", nil),
             NSLocalizedString(@"(GMT -08:00) Pacific Standard(US and Canada)", nil),
             NSLocalizedString(@"(GMT -07:00) Mountain Standard(US and Canada)", nil),
             NSLocalizedString(@"(GMT -06:00) Central Standard(US and Canada), Mexico City", nil),
             NSLocalizedString(@"(GMT -05:00) Eastern Standard(US and Canada), Lima, Bogota", nil),
             NSLocalizedString(@"(GMT -04:00) Atlantic Standard (Canada), Santiago, La Paz", nil),
             NSLocalizedString(@"(GMT -03:30) Newfoundland", nil),
             NSLocalizedString(@"(GMT -03:00) Brasilia, Buenos Aires, Georgetown", nil),
             NSLocalizedString(@"(GMT -02:00) South Georgia I.", nil),
             NSLocalizedString(@"(GMT -01:00) Reykjavik", nil),
             NSLocalizedString(@"(GMT) Greenwich mean time; London, Lisbon, Casablanca", nil),
             NSLocalizedString(@"(GMT +01:00) Brussels, Paris, Berlin, Rome, Madrid, Stockholm, Beograd", nil),
             NSLocalizedString(@"(GMT +02:00) Athens, Jerusalem, Cairo, Helsinki", nil),
             NSLocalizedString(@"(GMT +03:00) Nairobi, Riyadh, Moscow", nil),
             NSLocalizedString(@"(GMT +03:30) Tehran", nil),
             NSLocalizedString(@"(GMT +04:00) Baku, Tbilisi, Abu Dhabi, Muscat", nil),
             NSLocalizedString(@"(GMT +04:30) Kabul", nil),
             NSLocalizedString(@"(GMT +05:00) Islamabad, Karachi, Tashkent", nil),
             NSLocalizedString(@"(GMT +05:30) Bombay, Calcutta, Madras, New Delhi", nil),
             NSLocalizedString(@"(GMT +06:00) Astana, Almaty, Dhaka, Colombo", nil),
             NSLocalizedString(@"(GMT +07:00) Bangkok, Hanoi, Jakarta", nil),
             NSLocalizedString(@"(GMT +08:00) Beijing, Singapore, Taipei", nil),
             NSLocalizedString(@"(GMT +09:00) Seoul, Yakutsk, Tokyo", nil),
             NSLocalizedString(@"(GMT +09:30) Darwin", nil),
             NSLocalizedString(@"(GMT +10:00) Guam, Melbourne, Sydney, Port Moresby, Vladivostok", nil),
             NSLocalizedString(@"(GMT +11:00) Magadan, Solomon Islands, New Caledonia", nil),
             NSLocalizedString(@"(GMT +12:00) Auckland, Wellington, Fiji Islands", nil)];
}

- (NSArray *)availableTimeZone
{
    int zone[30] = {
        43200,
        39600,
        36000,
        32400,
        28800,
        25200,
        21600,
        18000,
        14400,
        12600,
        10800,
        7200,
        3600,
        0,
        -3600,
        -7200,
        -10800,
        -12600,
        -14400,
        -16200,
        -18000,
        -19800,
        -21600,
        -25200,
        -28800,
        -32400,
        -34200,
        -36000,
        -39600,
        -43200
    };
    
    NSMutableArray *availableTimeZones = [[NSMutableArray alloc] init];
    for (int i = 0; i < 30; i++) {
        [availableTimeZones addObject:[NSNumber numberWithInt:zone[i]]];
    }
    
    return availableTimeZones;
}

- (NSArray *)availableTimeServers
{
    const char *serverNames[] = {
        "time.nist.gov",
        "time.kriss.re.kr",
        "time.windows.com",
        "time.nuri.net",
        NULL
    };
    
    NSMutableArray *names = [[NSMutableArray alloc] init];
    for (int i = 0; ; i++) {
        const char *serverName = serverNames[i];
        if (!serverName) break;
        [names addObject:[NSString stringWithCString:serverName encoding:NSASCIIStringEncoding]];
    }
    return names;
}


- (NSRange)hour24Range
{
    return NSMakeRange(0, 24);
}

- (NSRange)hour12Range
{
    return NSMakeRange(0, 12);
}

- (NSRange)minutesRange
{
    return NSMakeRange(0, 60);
}

- (NSRange)secondsRange
{
    return NSMakeRange(0, 60);
}

@end
