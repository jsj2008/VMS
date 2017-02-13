//
//  PrivacyCoverViewController.m
//  
//
//  Created by mac_dev on 16/5/23.
//
//

#import "PrivacyCoverViewController.h"
#import "PrivacyCoverEditWindowController.h"

@interface PrivacyCoverViewController ()

//隐私遮盖
@property (nonatomic,weak) IBOutlet NSPopUpButton *osdMaskEnableBtn;
@property (nonatomic,weak) IBOutlet NSButton *privacyCoverEditBtn;
@property (nonatomic,strong) PrivacyCoverEditWindowController *pcewc;

@end

@implementation PrivacyCoverViewController

#pragma mark - public api
- (void)fetch
{
    [self setActivity:YES];
    
    __block FOSCAM_NET_CONFIG config;
    DispatchCenter *center = [DispatchCenter sharedDispatchCenter];
    CDevice *device = self.device;
    __block BOOL success = YES;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int osdMaskEnable = 0;
        FOS_OSDMASKAREA osdMaskArea;
        do {
            config.info = &osdMaskEnable;
            success = [center getConfig:&config forType:FOSCAM_NET_CONFIG_VIDEO_OSD_MASK_ENABLE fromDevice:device];
            if (!success)
                break;
            
            config.info = &osdMaskArea;
            success = [center getConfig:&config forType:FOSCAM_NET_CONFIG_OSD_MASK_AREA fromDevice:device];
        }while (0);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [self setOsdMaskEnable:osdMaskEnable];
                [self setOsdMaskArea:osdMaskArea];
            } else
                [self alert:@"超时"];
            [self setActivity:NO];
        });
        //osdMaskEnable
    });
}

- (void)push
{
    [self setActivity:YES];
    
    __block FOSCAM_NET_CONFIG config;
    DispatchCenter *center = [DispatchCenter sharedDispatchCenter];
    //Channel *channel = self.channel;
    CDevice *device = self.device;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int             osdMaskEnable = (int)self.osdMaskEnableBtn.indexOfSelectedItem;
        FOS_OSDMASKAREA area = self.osdMaskArea;
        BOOL success = NO;
        
        do {
            config.info = &osdMaskEnable;
            success = [center setConfig:&config forType:FOSCAM_NET_CONFIG_VIDEO_OSD_MASK_ENABLE toDevice:device];
            if (!success) break;
            
            config.info = &area;
            success = [center setConfig:&config forType:FOSCAM_NET_CONFIG_OSD_MASK_AREA toDevice:device];
        }while (0);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!success) [self alert:@"保存失败!"];
            [self setActivity:NO];
        });
    });
}

- (NSString *)description
{
    return @"隐私遮盖";
}

- (SVC_OPTION)option
{
    return SVC_REFRESH | SVC_SAVE;
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
                   completionHandler:^(NSModalResponse returnCode)
         {
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
#pragma mark - update UI
- (void)updatePrivacyCoverUI
{
    self.privacyCoverEditBtn.hidden = (self.osdMaskEnableBtn.indexOfSelectedItem == 0);
}

#pragma mark - setter && getter
- (void)setOsdMaskEnable:(int)osdMaskEnable
{
    _osdMaskEnable = osdMaskEnable;
    [self.osdMaskEnableBtn selectItemAtIndex:osdMaskEnable];
    [self updatePrivacyCoverUI];
}

@end
