//
//  LedConfigViewController.m
//  VMS
//
//  Created by mac_dev on 16/8/25.
//  Copyright © 2016年 mac_dev. All rights reserved.
//

#import "LedConfigViewController.h"

@interface LedConfigViewController ()

@property (nonatomic,weak) IBOutlet NSView *manualZone;
@property (nonatomic,weak) IBOutlet NSPopUpButton *ledModeBtn;
@end

@implementation LedConfigViewController

//FOSCAM_NET_CONFIG_DEVICE_STATE
#pragma mark - public
- (void)fetch
{
    [self setActivity:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FOSCAM_NET_CONFIG config;
        FOSIRCUTSTATE ircutState;
        
        config.info = &ircutState;

        BOOL success = [[DispatchCenter sharedDispatchCenter] getConfig:&config
                                                                forType:FOSCAM_NET_CONFIG_VIDEO_IRCUT_STATE
                                                             fromDevice:self.device];
       
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success)
                [self setIrcutState:ircutState];
            else
                [self alert:NSLocalizedString(@"failed to get the settings", nil)
                       info:NSLocalizedString(@"time out", nil)];
            [self setActivity:NO];
        });
    });
}


- (NSString *)description
{
    return NSLocalizedString(@"Led Mode", nil);
}

- (SVC_OPTION)option
{
    return 0;
}

#pragma mark - action
- (IBAction)ledModeSelected:(id)sender
{
    NSInteger mode = [(NSPopUpButton *)sender indexOfSelectedItem];
    FOSCAM_NET_CONFIG config;
    
    config.info = &mode;
    [[DispatchCenter sharedDispatchCenter] setConfig:&config forType:FOSCAM_NET_CONFIG_VIDEO_IRLAMP_TYPE toDevice:self.device];
}


- (IBAction)ledStateSelected:(id)sender
{
    int state = [self selectionOfRadioGroupView:self.manualZone];
    FOSCAM_NET_CONFIG_TYPE cfgTypes[] = {
        FOSCAM_NET_CONFIG_VIDEO_IRLAMP_OPEN,
        FOSCAM_NET_CONFIG_VIDEO_IRLAMP_CLOSE,
    };
    FOSCAM_NET_CONFIG config;
    
    config.info = &state;
    [[DispatchCenter sharedDispatchCenter] setConfig:&config forType:cfgTypes[state] toDevice:self.device];
}

#pragma mark - life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDispatchCenterNotification:)
                                                 name:DEVICE_IRCUT_STATE_DID_CHANGE_NOTIFICATION
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - notification
- (void)handleDispatchCenterNotification :(NSNotification *)aNotific
{
    NSString *name = aNotific.name;
    NSDictionary *userInfo = aNotific.userInfo;
    
    long dId = [[userInfo valueForKey:KEY_EVENT_DEVICE_ID] longValue];
    
    if (dId == self.device.uniqueId) {
        if ([name isEqualToString:DEVICE_IRCUT_STATE_DID_CHANGE_NOTIFICATION]) {
            FOSIRCUTSTATE ircutState;
            NSData *data = [userInfo valueForKey:KEY_IRCUT_STATE];
            
            [data getBytes:&ircutState length:sizeof(FOSIRCUTSTATE)];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setIrcutState:ircutState];
            });
        }
    }
}

#pragma mark - update mode ui
- (void)updateIRCutStateUI
{
    int mode = self.ircutState.mode;
    int state = self.ircutState.state;
    
    if (mode >=0 && mode < self.ledModeBtn.itemArray.count) {
        [self.ledModeBtn selectItemAtIndex:mode];
        self.manualZone.hidden = (mode != 1);
    }
    [self selectRadioGroupView:self.manualZone atIndex:state];
}

- (int)selectionOfRadioGroupView :(NSView *)view
{
    int     selection = 0;
    NSArray *radios = view.subviews;
    
    for (NSButton *radio in radios) {
        if (radio.state == NSOnState) {
            selection = (int)radio.tag;
            break;
        }
    }
    
    return selection;
}

- (void)selectRadioGroupView :(NSView *)view atIndex :(int)idx
{
    NSArray *radios = view.subviews;
    
    for (NSButton *radio in radios)
        [radio setState:(radio.tag == idx)? NSOnState : NSOffState];
}

#pragma mark - setter & getter
- (void)setIrcutState:(FOSIRCUTSTATE)ircutState
{
    _ircutState = ircutState;
    [self updateIRCutStateUI];
}

@end
