//
//  NVRDeviceRebootViewController.m
//  
//
//  Created by mac_dev on 16/5/31.
//
//

#import "NVRDeviceRebootViewController.h"

@interface NVRDeviceRebootViewController ()

@end

@implementation NVRDeviceRebootViewController

- (void)performReboot
{
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        
        FOSCAM_NVR_CONFIG nvrCfg;
        char xml[OUT_BUFFER_LENGTH] = {0};
        
        nvrCfg.output = xml;
        nvrCfg.outputLen = OUT_BUFFER_LENGTH;
        
        BOOL success = NO;
        if ([[DispatchCenter sharedDispatchCenter] setConfig:&nvrCfg
                                                     forType:FOSCAM_NVR_CONFIG_SYSTEM_RESTART
                                                    toDevice:self.device]) {
            //解析结果
            NSError *err = nil;
            NSString *rawString = [NSString stringWithCString:xml encoding:NSASCIIStringEncoding];
            NSLog(@"%@",rawString);
            NSDictionary *values = [XMLHelper parserCGIXml:rawString error:&err];
            
            if (!err) {
                NSNumber *result = [values valueForKey:KEY_XML_RESULT];
                success = result && (result.intValue == 0);
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success)
                [self onReboot];
            else
                [self alert:NSLocalizedString(@"failed to reboot", nil) info:@""];
            
            [self setActivity:NO];
        });
    });
}
@end
