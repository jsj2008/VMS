//
//  LogQuerySheetController.m
//  VMS
//
//  Created by mac_dev on 15/10/23.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "LogQuerySheetController.h"
#define COL_NUM         @"col_number"
#define COL_DATE_TIME   @"col_date_time"
#define COL_OPERATOR    @"col_operator"
#define COL_TYPE        @"col_type"
#define COL_CONTENT     @"col_content"



@interface LogQuerySheetController ()
@property (nonatomic,strong) NSArray *logs;
@property (nonatomic,weak) IBOutlet NSTableView *tableView;
@property (nonatomic,weak) IBOutlet TFDatePicker *begin;
@property (nonatomic,weak) IBOutlet TFDatePicker *end;
@end

@implementation LogQuerySheetController

- (void)windowDidLoad {
    [super windowDidLoad];
    [self.window setBackgroundColor:[NSColor colorWithCalibratedRed:232/255.0 green:235/255.0 blue:236/255.0 alpha:1.0]];
}


#pragma mark - action
- (IBAction)query :(id)sender
{
    [self setLogs:nil];
    [self.tableView reloadData];
}

#pragma mark - nstableview datasource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.logs.count;
}



- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSString *identifier = [tableColumn identifier];
    id obj = nil;
    Log *log = self.logs[row];
    
    if ([identifier isEqualToString:COL_NUM])
        obj = [NSString stringWithFormat:@"%ld",row];
    else if ([identifier isEqualToString:COL_DATE_TIME])
        obj = log.date;
    else if ([identifier isEqualToString:COL_OPERATOR])
        obj = log.opt;
    else if ([identifier isEqualToString:COL_TYPE])
        obj = log.type;
    else
        obj = log.event;
    
    
    return obj;
}

#pragma mark - nstableview delegate
- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return NO;
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectTableColumn:(NSTableColumn *)tableColumn
{
    return NO;
}
#pragma mark - nswindow delegate
- (void)windowWillClose:(NSNotification *)notification
{
    [[NSApplication sharedApplication] stopModal];
}


#pragma mark - setter && getter
- (NSArray *)logs
{
    if (!_logs) {
        VMSDatabase *db = [VMSDatabase sharedVMSDatabase];
        NSDate *begin = [self.begin dateValue];
        NSDate *end = [self.end dateValue];
        NSString *fmt = @"yyyy-MM-dd HH:mm:ss";
        _logs = [db fetchLogsFromDate:[[begin dateByMovingToBeginningOfDay] stringWithFormatter:fmt]
                               toDate:[[end dateByMovingToEndOfDay] stringWithFormatter:fmt]];
    }
    
    return _logs;
}

- (void)setBegin:(TFDatePicker *)begin
{
    _begin = begin;
    _begin.dateValue = [NSDate date];
}

- (void)setEnd:(TFDatePicker *)end
{
    _end = end;
    _end.dateValue = [NSDate date];
}

@end
