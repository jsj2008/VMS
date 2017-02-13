//
//  OSDMaskViewController.m
//  
//
//  Created by mac_dev on 16/6/2.
//
//

#import "OSDMaskViewController.h"

@interface OSDMaskViewController ()

@end

@implementation OSDMaskViewController

#pragma mark - public api
- (void)fetch
{
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int osdMaskEnable = 0;
        FOS_OSDMASKAREA osdMaskArea;
        FOSCAM_NET_CONFIG config;
        
        void *infos[] = {&osdMaskEnable,&osdMaskArea,NULL};
        int types[] = {FOSCAM_NET_CONFIG_VIDEO_OSD_MASK_ENABLE,FOSCAM_NET_CONFIG_OSD_MASK_AREA};
        
        BOOL success = YES;
        for (int i = 0; ; i++) {
            
            if (!success || infos[i] == NULL) {
                break;
            }
            
            config.info = infos[i];
            success = [[DispatchCenter sharedDispatchCenter] getConfig:&config
                                                               forType:types[i]
                                                            fromDevice:self.device];
        }
    
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [self setOsdMaskEnable:osdMaskEnable];
                [self setOsdMaskArea:osdMaskArea];
            } else
                [self alert:NSLocalizedString(@"failed to get the settings", nil) info:@""];
            
            [self setActivity:NO];
        });
    });
}

- (void)push
{
    [self setActivity:YES];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int osdMaskEnable = [self osdMaskEnableFromUI];
        FOS_OSDMASKAREA area = self.osdMaskArea;
        FOSCAM_NET_CONFIG config;
        
        void *infos[] = {&osdMaskEnable,&area,NULL};
        int types[] = {FOSCAM_NET_CONFIG_VIDEO_OSD_MASK_ENABLE,FOSCAM_NET_CONFIG_OSD_MASK_AREA};
        
        BOOL success = YES;
        for (int i = 0;; i++) {
            if (!success || infos[i] == NULL) {
                break;
            }
            
            config.info = infos[i];
            success = [[DispatchCenter sharedDispatchCenter] setConfig:&config
                                                               forType:types[i]
                                                              toDevice:self.device];
        }
    
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!success)
                [self alert:NSLocalizedString(@"failed to set the settings", nil) info:@""];
            
            [self setActivity:NO];
        });
    });
}

- (NSString *)description
{
    return NSLocalizedString(@"Privacy Zone", nil);
}

- (BOOL)enableOSD
{
    return NO;
}

- (BOOL)enablePrivacyCover
{
    return YES;
}
@end
