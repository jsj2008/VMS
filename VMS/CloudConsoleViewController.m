//
//  CloudConsoleViewController.m
//  VMS
//
//  Created by mac_dev on 15/6/1.
//  Copyright (c) 2015年 mac_dev. All rights reserved.
//

#import "CloudConsoleViewController.h"
#import "JFBackground.h"
#import "Image+Clip.h"
#import "JFButton.h"

#define CTRL_PAN_PTZ                        @"CTRL_PAN_PTZ.bmp"
#define CTRL_PAN_PT_UP                      @"CTRL_PAN_PT_UP"
#define CTRL_PAN_PT_RIGHTUP                 @"CTRL_PAN_PT_RIGHTUP"
#define CTRL_PAN_PT_RIGHT                   @"CTRL_PAN_PT_RIGHT"
#define CTRL_PAN_PT_RIGHTDOWN               @"CTRL_PAN_PT_RIGHTDOWN"
#define CTRL_PAN_PT_DOWN                    @"CTRL_PAN_PT_DOWN"
#define CTRL_PAN_PT_LEFTDOWN                @"CTRL_PAN_PT_LEFTDOWN"
#define CTRL_PAN_PT_LEFT                    @"CTRL_PAN_PT_LEFT"
#define CTRL_PAN_PT_LEFTUP                  @"CTRL_PAN_PT_LEFTUP"
#define CTRL_PAN_PT_AUTO                    @"CTRL_PAN_PT_AUTO"
#define CTRL_PAN_PTZ_ADD                    @"CTRL_PAN_PTZ_ADD"
#define CTRL_PAN_PTZ_SUBTRACT               @"CTRL_PAN_PTZ_SUBTRACT"
#define CTRL_PAN_SET                        @"CTRL_PAN_SET"
#define CTRL_PAN_DEL                        @"CTRL_PAN_DEL"
#define CTRL_PAN_RUN                        @"CTRL_PAN_RUN"

@interface CloudConsoleViewController ()
@property (weak) IBOutlet NSImageView *imageView;
@property (weak) IBOutlet JFButton *upButton;
@property (weak) IBOutlet JFButton *rightUpButton;
@property (weak) IBOutlet JFButton *rightButton;
@property (weak) IBOutlet JFButton *rightDownButton;
@property (weak) IBOutlet JFButton *downButton;
@property (weak) IBOutlet JFButton *leftDownButton;
@property (weak) IBOutlet JFButton *leftButton;
@property (weak) IBOutlet JFButton *leftUpButton;
@property (weak) IBOutlet JFButton *autoButton;
@property (weak) IBOutlet JFButton *distanceIncreaseButton;
@property (weak) IBOutlet JFButton *distanceDecreaseButton;
@property (weak) IBOutlet JFButton *lengthIncreaseButton;
@property (weak) IBOutlet JFButton *lengthDecreaseButton;
@property (weak) IBOutlet JFButton *apertureIncreaseButton;
@property (weak) IBOutlet JFButton *apertureDecreaseButton;
@property (weak) IBOutlet JFButton *stationSettingButton;
@property (weak) IBOutlet JFButton *stationDeleteButton;
@property (weak) IBOutlet JFButton *stationRunButton;
@property (weak) IBOutlet JFButton *inspectionSettingButton;
@property (weak) IBOutlet JFButton *inspectionDeleteButton;
@property (weak) IBOutlet JFButton *inspectionRunButton;
@end

@implementation CloudConsoleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (void)awakeFromNib
{
    if ([self.view isKindOfClass:[JFBackground class]]) {
        JFBackground *background = (JFBackground *)self.view;
        [background setBackgroundColor:[NSColor colorWithRed:192/255.0 green:192/255.0 blue:192/255.0 alpha:1.0]];
    }
    
    [self.imageView setImage:[NSImage imageNamed:CTRL_PAN_PTZ]];
    [self.upButton setImageForAllState:[NSImage imageNamed:CTRL_PAN_PT_UP]];
    [self.rightUpButton setImageForAllState:[NSImage imageNamed:CTRL_PAN_PT_RIGHTUP]];
    [self.rightButton setImageForAllState:[NSImage imageNamed:CTRL_PAN_PT_RIGHT]];
    [self.rightDownButton setImageForAllState:[NSImage imageNamed:CTRL_PAN_PT_RIGHTDOWN]];
    [self.downButton setImageForAllState:[NSImage imageNamed:CTRL_PAN_PT_DOWN]];
    [self.leftDownButton setImageForAllState:[NSImage imageNamed:CTRL_PAN_PT_LEFTDOWN]];
    [self.leftButton setImageForAllState:[NSImage imageNamed:CTRL_PAN_PT_LEFT]];
    [self.leftUpButton setImageForAllState:[NSImage imageNamed:CTRL_PAN_PT_LEFTUP]];
    [self.autoButton setImageForAllState:[NSImage imageNamed:CTRL_PAN_PT_AUTO]];
    [self.distanceIncreaseButton setImageForAllState:[NSImage imageNamed:CTRL_PAN_PTZ_ADD]];
    [self.distanceDecreaseButton setImageForAllState:[NSImage imageNamed:CTRL_PAN_PTZ_SUBTRACT]];
    [self.lengthIncreaseButton setImageForAllState:[NSImage imageNamed:CTRL_PAN_PTZ_ADD]];
    [self.lengthDecreaseButton setImageForAllState:[NSImage imageNamed:CTRL_PAN_PTZ_SUBTRACT]];
    [self.apertureIncreaseButton setImageForAllState:[NSImage imageNamed:CTRL_PAN_PTZ_ADD]];
    [self.apertureDecreaseButton setImageForAllState:[NSImage imageNamed:CTRL_PAN_PTZ_SUBTRACT]];
    
    [self.stationSettingButton setImageForAllState:[NSImage imageNamed:CTRL_PAN_SET]];
    [self.stationDeleteButton setImageForAllState:[NSImage imageNamed:CTRL_PAN_DEL]];
    [self.stationRunButton setImageForAllState:[NSImage imageNamed:CTRL_PAN_RUN]];
    [self.inspectionSettingButton setImageForAllState:[NSImage imageNamed:CTRL_PAN_SET]];
    [self.inspectionDeleteButton setImageForAllState:[NSImage imageNamed:CTRL_PAN_DEL]];
    [self.inspectionRunButton setImageForAllState:[NSImage imageNamed:CTRL_PAN_RUN]];
}



- (IBAction)cameraDirectionControl :(NSButton *)sender
{

}


@end