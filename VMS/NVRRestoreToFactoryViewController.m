//
//  NVRRestoreToFactoryViewController.m
//  
//
//  Created by mac_dev on 16/5/31.
//
//

#import "NVRRestoreToFactoryViewController.h"

@interface NVRRestoreToFactoryViewController ()

@end

@implementation NVRRestoreToFactoryViewController
#pragma mark - public api
- (void)performReset
{
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
       
        FOSCAM_NVR_CONFIG nvrCfg;
        char xml[OUT_BUFFER_LENGTH] = {0};
        
        nvrCfg.output = xml;
        nvrCfg.outputLen = OUT_BUFFER_LENGTH;
        
        BOOL success = NO;
        if ([[DispatchCenter sharedDispatchCenter] setConfig:&nvrCfg
                                                     forType:FOSCAM_NVR_CONFIG_SYSTEM_RESET
                                                    toDevice:self.device]) {
            //解析结果
            NSError *err = nil;
            NSString *rawString = [NSString stringWithCString:xml encoding:NSASCIIStringEncoding];
            NSLog(@"%@",rawString);
            NSDictionary *values = [XMLHelper parserCGIXml:rawString error:&err];
            
            if (!err) {
                NSNumber *result = [values valueForKey:KEY_XML_RESULT];
                if (result && (result.intValue == 0)) {
                    [[DispatchCenter sharedDispatchCenter] setConfig:&nvrCfg
                                                             forType:FOSCAM_NVR_CONFIG_SYSTEM_RESTART
                                                            toDevice:self.device];
                    success = YES;
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success)
                [self onRestore];
            else
                [self alert:NSLocalizedString(@"failed to factory reset", nil) info:@""];
            
            [self setActivity:NO];
        });
    });
}

@end
