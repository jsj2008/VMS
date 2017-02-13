//
//  OSDViewController.m
//  
//
//  Created by mac_dev on 16/5/23.
//
//

#import "OSDViewController.h"

@interface OSDViewController ()

@property (nonatomic,weak) IBOutlet NSView *zone1;
@property (nonatomic,weak) IBOutlet NSView *zone2;
@property (nonatomic,weak) IBOutlet NSTextField *chnNameLabel;
@property (nonatomic,weak) IBOutlet NSTextField *chnNameTF;
@property (nonatomic,weak) IBOutlet NSPopUpButton *timeStampEnableBtn;
@property (nonatomic,weak) IBOutlet NSPopUpButton *deviceNameEnableBtn;
@property (nonatomic,strong) PrivacyCoverEditWindowController *pcewc;

@end

@implementation OSDViewController

#pragma mark - public api
- (void)fetch
{
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FOS_OSDSETTING osdSetting;
        FOSCAM_NET_CONFIG config;
        config.info = &osdSetting;
        BOOL success = [[DispatchCenter sharedDispatchCenter] getConfig:&config
                                                                forType:FOSCAM_NET_CONFIG_VIDEO_OSD
                                                             fromDevice:self.device];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                FOS_OSDConfigMsg osdConfigMsg;
                osdConfigMsg.isEnableDevName = osdSetting.isEnableDevName;
                osdConfigMsg.isEnableTimeStamp = osdSetting.isEnableTimeStamp;
                [self setOsdConfigMsg:osdConfigMsg];
            }
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
        FOS_OSDConfigMsg osdConfigMsg = [self osdConfigMsgFromUI];
        FOS_OSDSETTING osdSetting;
        memset(&osdSetting, 0, sizeof(FOS_OSDSETTING));
        osdSetting.isEnableDevName = osdConfigMsg.isEnableDevName;
        osdSetting.isEnableTimeStamp = osdConfigMsg.isEnableTimeStamp;
        
        FOSCAM_NET_CONFIG config;
        
        config.info = &osdSetting;
        BOOL success = [[DispatchCenter sharedDispatchCenter] setConfig:&config
                                                                forType:FOSCAM_NET_CONFIG_VIDEO_OSD
                                                               toDevice:self.device];
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
    return  NSLocalizedString(@"OSD", nil);
}

- (SVC_OPTION)option
{
    return SVC_REFRESH | SVC_SAVE;
}

- (BOOL)enableOSD
{
    return YES;
}

- (BOOL)enablePrivacyCover
{
    return NO;
}

- (int)osdMaskEnableFromUI
{
    return (int)self.osdMaskEnableBtn.indexOfSelectedItem;
}
#pragma mark - private api
#pragma mark - life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    BOOL hideChnName = (self.device.type == IPC);
    
    [self.chnNameLabel setHidden:hideChnName];
    [self.chnNameTF setHidden:hideChnName];
    [self.osdMaskEnableBtn setEnabled:NO];
    [self.privacyCoverEditBtn setHidden:YES];
    
    [self setupZones];
}

- (void)setupZones
{
    if (![self enablePrivacyCover]) {
        [self.zone2 setHidden:YES];
    } else if (![self enableOSD]) {
        NSPoint origin = self.zone2.frame.origin;
        origin.y += self.zone1.frame.size.height;
        [self.zone1 setHidden:YES];
        [self.zone2 setFrameOrigin:origin];
    }
}

#pragma mark - action
- (IBAction)editPrivacyCoverArea:(id)sender
{
    if (!self.pcewc) {
        Channel *chn = self.device.children[0];
        self.pcewc = [[PrivacyCoverEditWindowController alloc] initWithWindowNibName:@"PrivacyCoverEditWindowController"
                                                                           channelId:chn.uniqueId
                                                                               areas:self.osdMaskArea];
        [self.view.window beginSheet:self.pcewc.window
                   completionHandler:^(NSModalResponse returnCode) {
             self.osdMaskArea = self.pcewc.areas;
             
             [self.pcewc close];
             [self setPcewc:nil];
         }];
    }
}

- (IBAction)selectPrivacyCoverOption:(id)sender
{
    [self updatePrivacyCoverUI];
}
#pragma mark - collect from UI
- (FOS_OSDConfigMsg)osdConfigMsgFromUI
{
    FOS_OSDConfigMsg osdConfigMsg = self.osdConfigMsg;
    
    [self.chnNameTF.stringValue getCString:osdConfigMsg.devName
                                 maxLength:64
                                  encoding:NSASCIIStringEncoding];
    osdConfigMsg.isEnableTimeStamp = (int)self.timeStampEnableBtn.indexOfSelectedItem;
    osdConfigMsg.isEnableDevName = (int)self.deviceNameEnableBtn.indexOfSelectedItem;
    return osdConfigMsg;
}
#pragma mark - update UI
- (void)updateOsdConfigMsgUI
{
    FOS_OSDConfigMsg osdConfigMsg = self.osdConfigMsg;
    [self.timeStampEnableBtn selectItemAtIndex:osdConfigMsg.isEnableTimeStamp];
    [self.deviceNameEnableBtn selectItemAtIndex:osdConfigMsg.isEnableDevName];
    [self.chnNameTF setStringValue:[NSString stringWithCString:osdConfigMsg.devName encoding:NSASCIIStringEncoding]];
}

- (void)updatePrivacyCoverUI
{
    self.privacyCoverEditBtn.hidden = (self.osdMaskEnableBtn.indexOfSelectedItem == 0);
}

#pragma mark - setter && getter
- (void)setOsdConfigMsg:(FOS_OSDConfigMsg)osdConfigMsg
{
    _osdConfigMsg = osdConfigMsg;
    [self updateOsdConfigMsgUI];
}


- (void)setOsdMaskEnable:(int)osdMaskEnable
{
    _osdMaskEnable = osdMaskEnable;
    [self.osdMaskEnableBtn setEnabled:YES];
    [self.osdMaskEnableBtn selectItemAtIndex:osdMaskEnable];
    [self updatePrivacyCoverUI];
}
@end
