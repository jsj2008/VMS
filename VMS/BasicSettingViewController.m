//
//  BasicSettingViewController.m
//  VMS
//
//  Created by mac_dev on 15/8/28.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "BasicSettingViewController.h"

#define ID_TIME_ZONE                            @"Time Zones"
#define ID_TIME_SERVERS                         @"Time Servers"
#define ID_HOURS                                @"Hours"
#define ID_MINS                                 @"Mins"
#define ID_SECS                                 @"Secs"
#define ID_DATE_FORMATS                         @"Date Formats"
#define ID_TIME_FORMATS                         @"Time Formats"
#define ID_AMPM                                 @"AMPM"

@interface BasicSettingViewController ()

//设备名称
@property (nonatomic,weak) IBOutlet NSTextField *deviceName;

//设备系统时间
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


//指示灯
@property (weak) IBOutlet NSComboBox *infraLedEnable;

//时间更新计时器
@property (strong,nonatomic) NSTimer *timeUpdate;

//字符串格式化器
@property (nonatomic,weak) IBOutlet XStringFomatter *deviceNameFormatter;
@end

@implementation BasicSettingViewController

@synthesize devName = _devName;
@synthesize ledEnable = _ledEnable;

#pragma mark - action
//当用户切换了时区，日期格式，时间格式，执行下面的动作
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
}

#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    //[self refetch :0];
}

- (void)viewWillDisappear
{
    [self.timeUpdate invalidate];
    [self setTimeUpdate :nil];
}
#pragma mark - public api
- (void)push:(NSInteger)tag
{
    [self setActivity:YES];
    
    __block FOSCAM_NET_CONFIG config;
    DispatchCenter *center = [DispatchCenter sharedDispatchCenter];
    CDevice *device = self.device;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        switch (tag) {
            case 0: {
                const char *devName = [self.devName UTF8String];
                //设备名
                config.info = (void *)devName;
                [center setConfig:&config forType:FOSCAM_NET_CONFIG_DEVICE_NAME toDevice:device];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setActivity:NO];
                });
            }
                break;
            case 1: {
                FOS_DEVSYSTEMTIME sysTime = [self devSysTimeFromUI];
                config.info = &sysTime;
                [center setConfig:&config forType:FOSCAM_NET_CONFIT_DEVICE_SYSTEM_TIME toDevice:device];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setActivity:NO];
                });
            }
                break;
            case 2: {
                int ledEnable = self.ledEnable;
                config.info = &ledEnable;
                [center setConfig:&config forType:FOSCAM_NET_CONFIG_DEVICE_LED_ENABLE_STATE toDevice:device];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setActivity:NO];
                });
            }
                break;
            default: {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setActivity:NO];
                });
            }
                break;
        }
    });
}

- (void)refetch :(NSInteger)tag
{
    [self setActivity:YES];
    
    __block FOSCAM_NET_CONFIG config;
    DispatchCenter *center = [DispatchCenter sharedDispatchCenter];
    CDevice *device = self.device;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        switch (tag) {
            case 0: {
                char device_name[128];
                config.info = device_name;
                
                BOOL success = [center getConfig:&config forType:FOSCAM_NET_CONFIG_DEVICE_NAME fromDevice:device];
                NSString *deviceName = [NSString stringWithUTF8String:device_name];
                
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    if (success) [self setDevName :deviceName];
                    else [self alert:@"超时"];
                    [self setActivity:NO];
                });
            }
                break;
            case 1: {
                FOS_DEVSYSTEMTIME devSystemTime;
                config.info = &devSystemTime;
                BOOL success = [center getConfig:&config forType:FOSCAM_NET_CONFIT_DEVICE_SYSTEM_TIME fromDevice:device];
                
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    if (success) {
                        [self setDeviceSystemTime:devSystemTime];
                        [self.timeUpdate fire];
                    } else [self alert:@"超时"];
                    
                    [self setActivity:NO];
                });
            }
                break;
            case 2: {
                int infraLedEnable;
                config.info = &infraLedEnable;
                BOOL success = [center getConfig:&config forType:FOSCAM_NET_CONFIG_DEVICE_LED_ENABLE_STATE fromDevice:device];
                
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    if (success) {
                        [self setLedEnable :infraLedEnable];
                    } else [self alert:@"超时"];
                    [self setActivity:NO];
                });
            }
                break;
            default: {
                dispatch_async(dispatch_get_main_queue(), ^{
                   [self setActivity:NO]; 
                });
            }
                break;
        }
    });
}

#pragma mark - private method
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


- (NSDateComponents *)componentsForYear :(int)y
                                 mounth :(int)M
                                    day :(int)d
                                   hour :(int)h
                                minutes :(int)m
                                seconds :(int)s
                           fromTimeZone :(NSTimeZone *)zone1
                             toTimeZone :(NSTimeZone *)zone2
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    [calendar setTimeZone:zone1];
    
    NSDate *date = [calendar dateWithEra:1
                                 year:y
                                month:M
                                  day:d
                                 hour:h
                               minute:m
                               second:s
                           nanosecond:0];
    return [calendar componentsInTimeZone:zone2 fromDate:date];
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
    NSString    *dst        = [NSString stringWithFormat:@"%d",(int)self.dstBtn.indexOfSelectedItem * 30];
    int         h           = (int)self.hourBtn.indexOfSelectedItem;
    int         m           = (int)self.minutesBtn.indexOfSelectedItem;
    int         s           = (int)self.secondBtn.indexOfSelectedItem;
    [self getYear:&y mounth:&M day:&d fromDateString:dateString withFormate:dateFmt];
    
    NSDateComponents *components = [self componentsForYear:y
                                                    mounth:M
                                                       day:d
                                                      hour:h
                                                   minutes:m
                                                   seconds:s
                                              fromTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:offset]
                                                toTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
    devSysTime.timeZone     = [timeZones[timeZoneIdx] intValue];
    devSysTime.timeSource   = self.ntpEnable;
    devSysTime.dateFormat   = (int)self.dateFormatBtn.indexOfSelectedItem;
    devSysTime.timeFormat   = (int)self.timeFormatBtn.indexOfSelectedItem;
    devSysTime.year         = (int)components.year;
    devSysTime.mon          = (int)components.month;
    devSysTime.day          = (int)components.day;
    devSysTime.hour         = (int)components.hour;
    devSysTime.minute       = (int)components.minute;
    devSysTime.sec          = (int)components.second;
    devSysTime.isDst        = (int)self.dstEnable;
    devSysTime.dst          = (int)self.dstBtn.indexOfSelectedItem * 30;
    
    strcpy(devSysTime.ntpServer, dst.UTF8String);
    
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
        case 0:
            h = [self hour12FromHour24:components.hour ampm:&ampm];
            break;
        case 1://24小时制
            h = components.hour;
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
    NSString            *ntpServer          = [NSString stringWithUTF8String:deviceSystemTime.ntpServer];
    NSUInteger          ntpServerIdx        = [[self availableTimeServers] indexOfObject:ntpServer];
    if (ntpServerIdx < [self availableTimeServers].count) {
        [self.ntpServerBtn selectItemAtIndex:ntpServerIdx];
    }
    
    //时间源
    self.ntpEnable = deviceSystemTime.timeSource;
    
    //日期格式
    NSUInteger          dateFmtIdx          = deviceSystemTime.dateFormat;
    if (dateFmtIdx < [self availableDateFormats].count) {
        [self.dateFormatBtn selectItemAtIndex:dateFmtIdx];
    }
    
    //时间格式
    NSUInteger          timeFmtIdx          = deviceSystemTime.timeFormat;
    if (timeFmtIdx < [self availableTimeFormats].count) {
        [self.timeFormatBtn selectItemAtIndex:timeFmtIdx];
    }
    
    //时钟时间
    [self setShouldUpdateClockTime:YES];
    [self setClockDate:[self clockDateFromDevSysTime:deviceSystemTime]];
    [self alterTimeFmt];
    [self updateClockDateUI];
    [self updateClockTimeUI];
    
    //夏令时
    self.dstEnable = (deviceSystemTime.isDst == 1);
    NSUInteger dstIdx = deviceSystemTime.dst / 30;
    if (dstIdx < self.dstBtn.itemArray.count) {
        [self.dstBtn selectItemAtIndex:dstIdx];
    }
}

#pragma mark - setter && getter
- (void)setDevName:(NSString *)devName
{
    _devName = devName;
    [self.deviceName setStringValue:[self safetyText:devName]];
}

- (void)setDeviceSystemTime:(FOS_DEVSYSTEMTIME)deviceSystemTime
{
    _deviceSystemTime = deviceSystemTime;
    [self updateDevSystemTimeUI];//更新记录
}

- (NSString *)devName
{
    _devName = [self.deviceName stringValue];
    return _devName;
}

- (void)setLedEnable:(int)ledEnable
{
    _ledEnable = ledEnable;
    [self.infraLedEnable selectItemAtIndex:ledEnable];
}

- (int)ledEnable
{
    _ledEnable = (int)[self.infraLedEnable indexOfSelectedItem];
    return _ledEnable;
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

- (void)setDeviceNameFormatter:(XStringFomatter *)deviceNameFormatter
{
    _deviceNameFormatter = deviceNameFormatter;
    [_deviceNameFormatter setMaxLength :20];
    [_deviceNameFormatter setRegex:@"^[a-zA-Z0-9_-]{0,20}$"];
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

- (void)setDateFormatBtn:(NSPopUpButton *)dateFormatBtn
{
    _dateFormatBtn = dateFormatBtn;
    [self setControl :_dateFormatBtn withTitles:[self availableDateFormats]];
}

- (void)setTimeFormatBtn:(NSPopUpButton *)timeFormatBtn
{
    _timeFormatBtn = timeFormatBtn;
    [self setControl:_timeFormatBtn withTitles:[self availableTimeFormats]];
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

- (void)setDstBtn:(NSPopUpButton *)dstBtn
{
    _dstBtn = dstBtn;
    
    NSRange range = [self dstRange];
    [_dstBtn removeAllItems];
    for (int i = 0; i < range.length; i++) {
        NSString *title = [NSString stringWithFormat:@"%2lu",(range.location + i)*30];
        [_dstBtn addItemWithTitle:title];
    }
}

#pragma mark - data for controls
- (NSArray *)availableTimeZoneNames
{
    const char *zoneNames[] = {
        "(GMT -12:00)国际日期变更线以西",
        "(GMT -11:00) 中途岛，萨摩亚群岛",
        "(GMT -10:00) 夏威夷",
        "(GMT -09:00) 阿拉斯加标准",
        "(GMT -08:00) 太平洋标准（美国和加拿大）",
        "(GMT -07:00) 山地标准（美国和加拿大）",
        "(GMT -06:00) 中部时间（美国和加拿大），墨西哥城",
        "(GMT -05:00) 东部时间（美国和加拿大），波哥大，利马",
        "(GMT -04:00) 大西洋标准（加拿大），拉巴斯，圣地亚哥",
        "(GMT -03:30) 纽芬兰",
        "(GMT -03:00) 巴西利亚，布宜诺斯艾利斯，乔治敦",
        "(GMT -02:00) 南乔治亚一",
        "(GMT -01:00) 雷克雅未克",
        "(GMT) 格林威治标准时间，伦敦，里斯本，卡萨布兰卡",
        "(GMT +01:00) 布鲁塞尔，巴黎，柏林，罗马，马德里，斯德哥尔摩，贝尔格莱德",
        "(GMT +02:00) 雅典，耶路撒冷，开罗，赫尔辛基",
        "(GMT +03:00) 利雅得，莫斯科，内罗毕",
        "(GMT +03:30) 德黑兰",
        "(GMT +04:00) 巴库，第比利斯，阿布扎比，马斯喀特",
        "(GMT +04:30) 喀布尔",
        "(GMT +05:00) 伊斯兰堡，卡拉奇，塔什干",
        "(GMT +05:30) 孟买，加尔各答，马德拉斯，新德里",
        "(GMT +06:00) 阿斯塔纳，阿拉木图，达卡，科伦坡",
        "(GMT +07:00) 曼谷，河内，雅加达",
        "(GMT +08:00) 北京，新加坡，台北",
        "(GMT +09:00) 首尔，雅库茨克，东京",
        "(GMT +09:30) 达尔文",
        "(GMT +10:00) 关岛，墨尔本，悉尼，符拉迪沃斯托克，莫尔兹比港",
        "(GMT +11:00) 马加丹，所罗门群岛，新喀里多尼亚",
        "(GMT +12:00) 奥克兰，惠灵顿，斐济群岛",
        NULL
    };
    
    NSMutableArray *names = [[NSMutableArray alloc] init];
    for (int i = 0;; i++) {
        const char *zoneName = zoneNames[i];
        if (!zoneName) break;
        [names addObject:[NSString stringWithUTF8String:zoneName]];
    }
    
    return names;
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
        [names addObject:[NSString stringWithUTF8String:serverName]];
    }
    return names;
}

- (NSArray *)availableDateFormats
{
    char *dateFormats[] = {
        "年-月－日",
        "日/月/年",
        "月/日/年",
        NULL
    };
    
    NSMutableArray *names = [[NSMutableArray alloc] init];
    for (int i = 0; ; i++) {
        const char *dateFormat = dateFormats[i];
        if (!dateFormat) break;
        [names addObject:[NSString stringWithUTF8String:dateFormat]];
    }
    return names;
}

- (NSArray *)availableTimeFormats
{
    const char *timeFormats[] = {
        "12小时制",
        "24小时制",
        NULL
    };
    
    NSMutableArray *names = [[NSMutableArray alloc] init];
    for (int i = 0; ; i++) {
        const char *timeFormat = timeFormats[i];
        if (!timeFormat) break;
        [names addObject:[NSString stringWithUTF8String:timeFormat]];
    }
    return names;
}

- (NSRange)dstRange
{
    return NSMakeRange(0, 5);
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
