//
//  ColorAdjustmentViewController.m
//  VMS
//
//  Created by mac_dev on 16/8/26.
//  Copyright © 2016年 mac_dev. All rights reserved.
//

#import "ColorAdjustmentViewController.h"

@interface ColorAdjustmentViewController ()

@property(nonatomic,weak) IBOutlet NSSlider *hueSlider;
@property(nonatomic,weak) IBOutlet NSSlider *brightnessSlider;
@property(nonatomic,weak) IBOutlet NSSlider *contrastSlider;
@property(nonatomic,weak) IBOutlet NSSlider *saturationSlider;
@property(nonatomic,weak) IBOutlet NSSlider *sharpnessSlider;
@property(nonatomic,weak) IBOutlet NSTextField *hueTF;
@property(nonatomic,weak) IBOutlet NSTextField *brightnessTF;
@property(nonatomic,weak) IBOutlet NSTextField *contrastTF;
@property(nonatomic,weak) IBOutlet NSTextField *saturationTF;
@property(nonatomic,weak) IBOutlet NSTextField *sharpnessTF;
@property(nonatomic,weak) IBOutlet NSButton *mirrorBtn;
@property(nonatomic,weak) IBOutlet NSButton *flipBtn;
@property(nonatomic,weak) IBOutlet NSPopUpButton *powerFrequencyBtn;

@end

@implementation ColorAdjustmentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDispatchCenterNotification:)
                                                 name:DEVICE_IMAGE_PARAM_DID_CHANGE_NOTIFICATION
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDispatchCenterNotification:)
                                                 name:DEVICE_MIRROR_FLIP_DID_CHANGE_NOTIFICATION
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDispatchCenterNotification:)
                                                 name:DEVICE_POWER_FREQUENCY_DID_CHANGE_NOTIFICATION
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - notification
- (void)handleDispatchCenterNotification:(NSNotification *)aNotific
{
    NSString *name = aNotific.name;
    NSDictionary *dict = aNotific.userInfo;
    long dId = [[dict valueForKey:KEY_EVENT_DEVICE_ID] longValue];
    
    if (dId == self.device.uniqueId) {
        if ([name isEqualToString:DEVICE_IMAGE_PARAM_DID_CHANGE_NOTIFICATION]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSData *data = [dict valueForKey:KEY_IMAGE_PARAM];
                FOSIMAGE imgParam;
                
                [data getBytes:&imgParam length:sizeof(FOSIMAGE)];
                [self setImgParam:imgParam];
            });
        }
        else if ([name isEqualToString:DEVICE_MIRROR_FLIP_DID_CHANGE_NOTIFICATION]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSData *data = [dict valueForKey:KEY_MIRROR_FLIP];
                FOSMIRRORFLIP mirrorFlip;
                
                [data getBytes:&mirrorFlip length:sizeof(FOSMIRRORFLIP)];
                [self setMirrorAndFlipCfg:mirrorFlip];
            });
        }
        else if (DEVICE_POWER_FREQUENCY_DID_CHANGE_NOTIFICATION) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSData *data = [dict valueForKey:KEY_PWRFREQ];
                FOSPWRFREQ pwrfreq;
                
                [data getBytes:&pwrfreq length:sizeof(FOSPWRFREQ)];
                [self setPowerFrequency:pwrfreq];
            });
        }
    }
}

#pragma mark - public api
- (void)fetch
{
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FOSIMAGE imgParam;
        FOSPWRFREQ pwrfreq;
        FOSMIRRORFLIP mirrorAndFlipCfg;
        
        FOSCAM_NET_CONFIG_TYPE cfgTypes[7] =
        {
            FOSCAM_NET_CONFIG_VIDEO_IMAGE_PARAM,
            FOSCAM_NET_CONFIG_VIDEO_PWR_FREG,
            FOSCAM_NET_CONFIG_VIDEO_MIRROR_FLIP,
        };
        
        void *configs[] =
        {
            &imgParam,
            &pwrfreq,
            &mirrorAndFlipCfg
        };
        
        FOSCAM_NET_CONFIG config;
        BOOL success = NO;
        
        for (int i = 0; i < 3; i++) {
            config.info = configs[i];
            success = [[DispatchCenter sharedDispatchCenter] getConfig:&config
                                                               forType:cfgTypes[i]
                                                            fromDevice:self.device];
            
            if (!success) {
                break;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [self setImgParam:imgParam];
                [self setPowerFrequency:pwrfreq];
                [self setMirrorAndFlipCfg:mirrorAndFlipCfg];
            }
            else
                [self alert:NSLocalizedString(@"failed to get the settings", nil)
                       info:NSLocalizedString(@"time out", nil)];
            [self setActivity:NO];
        });
    });
}

- (NSString *)description
{
    return NSLocalizedString(@"Color Adjustment", nil);
}

- (SVC_OPTION)option
{
    return 0;
}

#pragma mark - action
- (IBAction)colorAdjust:(id)sender
{
    
    NSInteger tag = [sender tag];
    NSArray *labels = @[self.hueTF,self.brightnessTF,self.contrastTF,self.saturationTF,self.sharpnessTF];
    
    FOSCAM_NET_CONFIG_TYPE cfgTypes[] = {
        FOSCAM_NET_CONFIG_VIDEO_IMAGE_PARAM_HUE,
        FOSCAM_NET_CONFIG_VIDEO_IMAGE_PARAM_BRIGHTNESS,
        FOSCAM_NET_CONFIG_VIDEO_IMAGE_PARAM_CONTRAST,
        FOSCAM_NET_CONFIG_VIDEO_IMAGE_PARAM_SATURATION,
        FOSCAM_NET_CONFIG_VIDEO_IMAGE_PARAM_SHARPNESS,
        FOSCAM_NET_CONFIG_VIDEO_IMAGE_PARAM_DEFALUT,
    };
    FOSCAM_NET_CONFIG config;
    
    switch (tag) {
        case 0:
        case 1:
        case 2:
        case 3:
        case 4: {
            
            NSEvent *event = [[NSApplication sharedApplication] currentEvent];
            BOOL startingDrag = event.type == NSLeftMouseDown;
            BOOL endingDrag = event.type == NSLeftMouseUp;
            BOOL dragging = event.type == NSLeftMouseDragged;
            
            NSAssert(startingDrag || endingDrag || dragging, @"unexpected event type caused slider change: %@", event);
            
            
            NSSlider *slider = sender;
            int val = slider.intValue;
            
            NSTextField *label = labels[tag];
            label.stringValue = [NSString stringWithFormat:@"%d",val];
            
            if (endingDrag) {
                // do whatever needs to be done when the slider stops changing
                config.info = &val;
                [[DispatchCenter sharedDispatchCenter] setConfig:&config forType:cfgTypes[tag] toDevice:self.device];
            }
        }
            
            break;
        case 5:{
            int mode = 1;
            config.info = &mode;
            [[DispatchCenter sharedDispatchCenter] setConfig:&config forType:cfgTypes[tag] toDevice:self.device];
        }
        default:
            break;
    }
}

- (IBAction)powerFrequencySelected :(id)sender
{
    NSPopUpButton *btn = sender;
    NSInteger tag = [btn selectedTag];
    FOSCAM_NET_CONFIG config;
    
    config.info = &tag;
    
    [[DispatchCenter sharedDispatchCenter] setConfig:&config forType:FOSCAM_NET_CONFIG_VIDEO_PWR_FREG toDevice:self.device];
}

- (IBAction)mirrorFlip:(id)sender
{
    NSInteger tag = [sender tag];
    NSInteger state = [(NSButton *)sender state];
    FOSCAM_NET_CONFIG_TYPE cfgTypes[] = {
        FOSCAM_NET_CONFIG_VIDEO_MIRROR,
        FOSCAM_NET_CONFIG_VIDEO_FLIP,
    };
    FOSCAM_NET_CONFIG config;
    config.info = &state;
    
    
    [[DispatchCenter sharedDispatchCenter] setConfig:&config forType:cfgTypes[tag] toDevice:self.device];
}


#pragma mark - mouse event
//截获鼠标弹起时间，查看
- (void)mouseUp:(NSEvent *)event
{
    [super mouseUp:event];
    
    
}

#pragma mark - update ui
- (void)updateImageParamUI
{
    NSArray *sliders = @[self.hueSlider,self.brightnessSlider,self.contrastSlider,self.saturationSlider,self.sharpnessSlider];
    NSArray *labels = @[self.hueTF,self.brightnessTF,self.contrastTF,self.saturationTF,self.sharpnessTF];
    int values[5] = {self.imgParam.hue,self.imgParam.brightness,self.imgParam.contrast,self.imgParam.saturation,self.imgParam.sharpness};
    
    for (int i = 0; i < 5; i++)
        [self updateSlider:sliders[i] label:labels[i] withValue:values[i]];
}

- (void)updatePowerFrequencyUI
{
    [self.powerFrequencyBtn selectItemWithTag:self.powerFrequency.freq];
}

- (void)updateMirrorAndFlipUI
{
    self.mirrorBtn.state = (self.mirrorAndFlipCfg.isMirror == 0)? NSOffState:NSOnState;
    self.flipBtn.state = (self.mirrorAndFlipCfg.isFlip == 0)? NSOffState:NSOnState;
}

- (void)updateSlider :(NSSlider *)slider label:(NSTextField *)label withValue :(int)val
{
    slider.integerValue = val;
    label.stringValue = [NSString stringWithFormat:@"%d",val];
}

#pragma mark - setter & getter
- (void)setImgParam:(FOSIMAGE)imgParam
{
    _imgParam = imgParam;
    [self updateImageParamUI];
}

- (void)setPowerFrequency:(FOSPWRFREQ)powerFrequency
{
    _powerFrequency = powerFrequency;
    [self updatePowerFrequencyUI];
}

- (void)setMirrorAndFlipCfg:(FOSMIRRORFLIP)mirrorAndFlipCfg
{
    _mirrorAndFlipCfg = mirrorAndFlipCfg;
    [self updateMirrorAndFlipUI];
}

@end
