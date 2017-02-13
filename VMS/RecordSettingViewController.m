//
//  RecordSettingViewController.m
//  VMS
//
//  Created by mac_dev on 2016/10/24.
//  Copyright © 2016年 mac_dev. All rights reserved.
//

#import "RecordSettingViewController.h"

@interface RecordSettingViewController ()

@property (assign) BOOL enableRecording;
@property (assign) BOOL cycleRecord;//循环录像
@property (weak) IBOutlet NSTextField *recordingPathName;
@property (weak) IBOutlet NSTextField *freeSpace;
@property (strong,nonatomic) NSArray *channels;

@end

@implementation RecordSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (NSString *)panelTitle
{
    return NSLocalizedString(@"Record Settings", nil);
}

#pragma mark - action
- (IBAction)cancel:(id)sender
{
    [self goBack];
}

- (IBAction)done:(id)sender
{
    self.recordSetting.enable = self.enableRecording;
    self.recordSetting.recordingPathName = self.recordingPathName.stringValue;
    self.recordSetting.enableLoopRecord = self.cycleRecord;
    
    //归档
    [self.recordSetting archive];
    
    //发送广播通知
    [[NSNotificationCenter defaultCenter] postNotificationName:RECORDING_SETTING_DID_CHANGE_NOTIFIC
                                                        object:nil];
    [self goBack];
}

#pragma mark - load
- (void)load
{
    self.recordSetting = [[VMSRecordSetting alloc] initWithPath:[VMSPathManager vmsConfPath:YES]];
    [self updateUIWithRecordSetting:self.recordSetting];
}

- (void)updateUIWithRecordSetting :(VMSRecordSetting *)setting
{
    if (setting) {
        self.enableRecording = setting.enable;
        self.recordingPathName.stringValue = setting.recordingPathName? setting.recordingPathName : @"";
        self.cycleRecord = setting.enableLoopRecord;
        //get free dick space
        NSError *err;
        NSDictionary *fileAttributes =
        [[NSFileManager defaultManager] attributesOfFileSystemForPath:setting.recordingPathName
                                                                error:&err];
        
        if (!err) {
            unsigned long long freeSpace = [[fileAttributes valueForKey:NSFileSystemFreeSize] longLongValue];
            [self.freeSpace setStringValue:[NSString stringWithFormat:@"%@:%dGB",NSLocalizedString(@"Available space", nil),(int)(freeSpace / 1073741824)]];
        }
    }
}

@end
