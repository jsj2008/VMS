//
//  PTZSpeedViewController.m
//  
//
//  Created by mac_dev on 16/5/23.
//
//

#import "PTZSpeedViewController.h"

@interface PTZSpeedViewController ()


@property(nonatomic,weak) IBOutlet NSPopUpButton *speedBtn;

@end

@implementation PTZSpeedViewController
#pragma mark - public api
- (void)fetch
{
    [self setActivity:YES];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        FOSCAM_NET_CONFIG config;
        int speed = 0;
        config.info = &speed;
        BOOL success = [[DispatchCenter sharedDispatchCenter] getConfig:&config
                                                                forType:FOSCAM_NET_CONFIG_PTZ_SPEED
                                                             fromDevice:self.device];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success)
                [self setSpeed:speed];
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
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        //获取PTZ速度
        FOSCAM_NET_CONFIG config;
        int speed = [self ptzSpeedFromUI];
        if (speed >= 0) {
            //FOSPTZ_SPEED speed = speed;
            config.info = &speed;
            BOOL success = [[DispatchCenter sharedDispatchCenter] setConfig:&config
                                                                    forType:FOSCAM_NET_CONFIG_PTZ_SPEED
                                                                   toDevice:self.device];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!success)
                    [self alert:NSLocalizedString(@"failed to set the settings", nil)
                           info:NSLocalizedString(@"time out", nil)];
                [self setActivity:NO];
            });
        }
    });
}

- (NSString *)description
{
    return NSLocalizedString(@"Pan & Tilt Speed", nil);
}

- (SVC_OPTION)option
{
    return SVC_REFRESH | SVC_SAVE;
}

- (int)ptzSpeedFromUI
{
    return (int)[self.speedBtn indexOfSelectedItem];
}
#pragma mark - update UI
- (void)updateSpeedUI
{
    int idx = self.speed;
    if (idx >= 0 && idx < [self availableSpeed].count)
        [self.speedBtn selectItemAtIndex:idx];
}

#pragma mark - data
- (NSArray *)availableSpeed
{
    return @[NSLocalizedString(@"Very fast", nil),
             NSLocalizedString(@"Fast", nil),
             NSLocalizedString(@"Normal", nil),
             NSLocalizedString(@"Slow", nil),
             NSLocalizedString(@"Very Slow", nil),];
}

#pragma mark - setter & getter
- (void)setSpeed:(int)speed
{
    _speed = speed;
    [self updateSpeedUI];
}

- (void)setSpeedBtn:(NSPopUpButton *)speedBtn
{
    _speedBtn = speedBtn;
    [self setControl:_speedBtn withTitles:[self availableSpeed]];
}
@end
